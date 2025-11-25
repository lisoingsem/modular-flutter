import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import '../../module_repository.dart';
import '../command.dart';

/// Command to generate modules.dart file with auto-registration code
class BuildCommand implements Command {
  @override
  Future<int> run(List<String> arguments) async {
    try {
      final projectRoot = Directory.current.path;

      // Check if we're in a Flutter project
      final pubspecPath = path.join(projectRoot, 'pubspec.yaml');

      // Detect modules path
      String? modulesPath;
      if (Directory(path.join(projectRoot, 'packages')).existsSync()) {
        modulesPath = 'packages';
      } else if (Directory(path.join(projectRoot, 'modules')).existsSync()) {
        modulesPath = 'modules';
      }

      // Use modules.yaml config file (in project root)
      // User only edits modules.yaml, never touches pubspec.yaml!
      final modulesConfigPath = path.join(projectRoot, 'modules.yaml');

      if (File(modulesConfigPath).existsSync()) {
        // Read modules.yaml and sync everything automatically
        // 1. Sync modules to pubspec.yaml (dependencies)
        await _syncModulesFromConfig(
            modulesConfigPath, pubspecPath, projectRoot);
        print('✓ Synced modules from modules.yaml to pubspec.yaml');

        // 2. Generate module imports (auto-registration) - only enabled modules
        if (modulesPath != null) {
          await _generateModulesImport(
              projectRoot, modulesPath, modulesConfigPath);
        }
      } else if (modulesPath != null) {
        // Auto-discover modules and create config file
        await _autoDiscoverAndCreateConfig(
            projectRoot, modulesPath, modulesConfigPath);
        // Sync modules to pubspec.yaml
        await _syncModulesFromConfig(
            modulesConfigPath, pubspecPath, projectRoot);
        // Generate module imports (only enabled modules)
        await _generateModulesImport(
            projectRoot, modulesPath, modulesConfigPath);
        print('✓ Auto-discovered modules and created modules.yaml');
      } else if (!File(pubspecPath).existsSync()) {
        print('Error: Not in a Flutter project (pubspec.yaml not found)');
        return 1;
      }

      print('✓ Build complete');
      print('');
      print('Module management enabled!');
      print('');
      print('How it works:');
      print(
          '  1. Edit modules.yaml to enable/disable modules (auth: true/false)');
      print('  2. Build command auto-syncs to pubspec.yaml');
      print('  3. Module imports are auto-generated (only enabled modules)');
      print('  4. Routes are auto-registered at runtime');
      print('');
      print('Workflow:');
      print('  1. Edit modules.yaml (enable/disable: auth: true)');
      print('  2. Run: dart run modular_flutter build');
      print('  3. Run: flutter pub get');
      print('  4. Run: flutter run');

      return 0;
    } catch (e) {
      print('Error generating modules.dart: $e');
      return 1;
    }
  }

  /// Sync modules from modules.yaml config to pubspec.yaml
  /// User only edits modules.yaml, never pubspec.yaml
  /// Format: { "auth": true, "catalog": true, ... }
  Future<void> _syncModulesFromConfig(
      String configPath, String pubspecPath, String projectRoot) async {
    try {
      final configContent = await File(configPath).readAsString();
      final config = loadYaml(configContent) as Map;

      // Detect modules path
      String? modulesPath;
      if (Directory(path.join(projectRoot, 'packages')).existsSync()) {
        modulesPath = 'packages';
      } else if (Directory(path.join(projectRoot, 'modules')).existsSync()) {
        modulesPath = 'modules';
      }

      if (modulesPath == null) {
        return;
      }

      // Build modules map from simple format: { "auth": true, ... }
      final modulesMap = <String, String>{};
      for (final entry in config.entries) {
        final key = entry.key.toString();
        final value = entry.value;

        // Skip comments and non-module entries
        if (key.startsWith('#') || key == 'modules') continue;

        // If value is true, module is enabled
        if (value == true) {
          final moduleAlias = key;
          final modulePath = path.join(modulesPath, moduleAlias);
          final modulePubspecPath =
              path.join(projectRoot, modulePath, 'pubspec.yaml');

          if (File(modulePubspecPath).existsSync()) {
            final pubspecContent = await File(modulePubspecPath).readAsString();
            final pubspec = loadYaml(pubspecContent) as Map;
            final packageName = pubspec['name']?.toString();

            if (packageName != null) {
              modulesMap[packageName] = modulePath;
            }
          }
        }
      }

      if (modulesMap.isEmpty) {
        return;
      }

      // Read current pubspec.yaml
      final pubspecContent = await File(pubspecPath).readAsString();

      // Update pubspec.yaml
      final lines = pubspecContent.split('\n');
      final result = <String>[];
      bool inDependencies = false;
      bool modulesAdded = false;
      int depsIndent = 0;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trim();

        // Find dependencies section
        if (trimmed == 'dependencies:' || trimmed.startsWith('dependencies:')) {
          inDependencies = true;
          depsIndent = line.indexOf('dependencies');
          result.add(line);
          continue;
        }

        // In dependencies section
        if (inDependencies) {
          final currentIndent =
              line.isEmpty ? 999 : line.indexOf(RegExp(r'[^\s]'));

          // Remove old modules section
          if (trimmed.contains('Feature modules') ||
              trimmed.contains('auto-generated')) {
            // Skip old modules
            i++;
            while (i < lines.length) {
              final nextLine = lines[i];
              final nextIndent =
                  nextLine.isEmpty ? 999 : nextLine.indexOf(RegExp(r'[^\s]'));
              if (nextIndent <= depsIndent + 2 &&
                  !nextLine.trim().isEmpty &&
                  !nextLine.trim().startsWith('#')) {
                i--;
                break;
              }
              if (modulesMap.keys
                  .any((name) => nextLine.trim().startsWith('$name:'))) {
                i++;
                continue;
              }
              if (nextIndent > depsIndent + 2) {
                i++;
                continue;
              }
              break;
            }
            continue;
          }

          // Skip old module entries
          if (modulesMap.keys.any((name) => trimmed.startsWith('$name:'))) {
            i++;
            while (i < lines.length) {
              final nextLine = lines[i];
              final nextIndent =
                  nextLine.isEmpty ? 999 : nextLine.indexOf(RegExp(r'[^\s]'));
              if (nextIndent <= depsIndent + 2) {
                i--;
                break;
              }
              i++;
            }
            continue;
          }

          // End of dependencies - add modules before this line
          if (currentIndent <= depsIndent &&
              trimmed.isNotEmpty &&
              !trimmed.startsWith('#') &&
              !modulesAdded) {
            result.add(
                '${' ' * (depsIndent + 2)}# Feature modules (auto-synced from .modular_flutter/modules.yaml)');
            for (final entry in modulesMap.entries.toList()..sort()) {
              result.add('${' ' * (depsIndent + 2)}${entry.key}:');
              result.add('${' ' * (depsIndent + 4)}path: ${entry.value}');
            }
            modulesAdded = true;
            inDependencies = false;
          }
        }

        result.add(line);
      }

      // If modules not added, add at end of dependencies
      if (!modulesAdded && inDependencies) {
        result.add(
            '${' ' * (depsIndent + 2)}# Feature modules (auto-synced from modules.yaml)');
        for (final entry in modulesMap.entries.toList()..sort()) {
          result.add('${' ' * (depsIndent + 2)}${entry.key}:');
          result.add('${' ' * (depsIndent + 4)}path: ${entry.value}');
        }
      }

      final updatedContent = result.join('\n');
      if (updatedContent != pubspecContent) {
        await File(pubspecPath).writeAsString(updatedContent);
      }
    } catch (e) {
      print('Warning: Could not sync modules from config: $e');
    }
  }

  /// Auto-discover modules and create config file
  Future<void> _autoDiscoverAndCreateConfig(
      String projectRoot, String modulesPath, String configPath) async {
    try {
      final repository = ModuleRepository(localModulesPath: modulesPath);
      final modules = repository.scan();

      if (modules.isEmpty) {
        return;
      }

      // Create .modular_flutter directory
      final configDir = Directory(path.dirname(configPath));
      if (!configDir.existsSync()) {
        configDir.createSync(recursive: true);
      }

      // Build modules config
      final modulesList = <Map<String, dynamic>>[];
      for (final module in modules) {
        final modulePubspecPath =
            path.join(projectRoot, modulesPath, module.alias, 'pubspec.yaml');
        if (File(modulePubspecPath).existsSync()) {
          final content = await File(modulePubspecPath).readAsString();
          final yaml = loadYaml(content) as Map;
          final packageName = yaml['name']?.toString();

          if (packageName != null) {
            modulesList.add({
              'name': packageName,
              'path': path.join(modulesPath, module.alias),
              'enabled': module.enabled,
            });
          }
        }
      }

      // Write config file
      final buffer = StringBuffer();
      buffer.writeln('# Modular Flutter - Module Configuration');
      buffer.writeln('# Configure modules here, not in pubspec.yaml');
      buffer.writeln('# This file is the only place you manage modules');
      buffer.writeln('');
      buffer.writeln('modules:');
      for (final module in modulesList) {
        buffer.writeln('  - name: ${module['name']}');
        buffer.writeln('    path: ${module['path']}');
        buffer.writeln('    enabled: ${module['enabled']}');
        buffer.writeln('');
      }
      buffer.writeln(
          '# Modules are auto-synced to pubspec.yaml by build command');
      buffer.writeln('# You never need to edit pubspec.yaml manually!');

      await File(configPath).writeAsString(buffer.toString());
    } catch (e) {
      print('Warning: Could not create modules config: $e');
    }
  }

  /// Generate modules import file (auto-discovery)
  /// This file imports all enabled modules from modules.yaml so they can auto-register
  /// ModularApp automatically imports this file - no manual imports needed
  Future<void> _generateModulesImport(
      String projectRoot, String modulesPath, String? modulesConfigPath) async {
    try {
      // Read enabled modules from modules.yaml (only enabled modules)
      final enabledModules = <String>{}; // module aliases

      if (modulesConfigPath != null && File(modulesConfigPath).existsSync()) {
        final configContent = await File(modulesConfigPath).readAsString();
        final config = loadYaml(configContent) as Map;

        // Read simple format: { "auth": true, ... }
        for (final entry in config.entries) {
          final key = entry.key.toString();
          final value = entry.value;

          if (key.startsWith('#') || key == 'modules') continue;

          if (value == true) {
            enabledModules.add(key); // Module alias
          }
        }
      } else {
        // Fallback: discover from filesystem
        final repository = ModuleRepository(localModulesPath: modulesPath);
        final modules = repository.scan();
        for (final module in modules) {
          if (module.enabled) {
            enabledModules.add(module.alias);
          }
        }
      }

      if (enabledModules.isEmpty) {
        return;
      }

      // Collect module imports (only enabled modules from modules.yaml)
      final moduleImports = <String, String>{}; // packageName -> moduleFile

      for (final moduleAlias in enabledModules) {
        final modulePath = path.join(projectRoot, modulesPath, moduleAlias);
        final modulePubspecPath = path.join(modulePath, 'pubspec.yaml');
        if (!File(modulePubspecPath).existsSync()) continue;

        final pubspecContent = await File(modulePubspecPath).readAsString();
        final pubspec = loadYaml(pubspecContent) as Map;
        final packageName = pubspec['name']?.toString();
        if (packageName == null) continue;

        // Find module main file (convention-based)
        final libPath = path.join(modulePath, 'lib');
        if (!Directory(libPath).existsSync()) continue;

        // Try common conventions
        final conventions = [
          '${packageName}_module.dart',
          '$packageName.dart',
          'module.dart',
        ];

        String? moduleFile;
        for (final convention in conventions) {
          final file = File(path.join(libPath, convention));
          if (file.existsSync()) {
            moduleFile = convention;
            break;
          }
        }

        if (moduleFile != null) {
          moduleImports[packageName] = moduleFile;
        }
      }

      if (moduleImports.isEmpty) {
        return;
      }

      // Generate modules import file in .modular_flutter/ (hidden from git)
      final libDir = Directory(path.join(projectRoot, 'lib'));
      if (!libDir.existsSync()) {
        libDir.createSync(recursive: true);
      }

      // Generate in a location that ModularApp can auto-import
      // Use a barrel file approach - single file that imports all modules
      final modulesFile =
          File(path.join(libDir.path, '.modular_flutter', 'modules.dart'));
      final modulesDir = modulesFile.parent;
      if (!modulesDir.existsSync()) {
        modulesDir.createSync(recursive: true);
      }

      // Create .gitignore in .modular_flutter/ to ensure it's ignored
      final gitignoreFile = File(path.join(modulesDir.path, '.gitignore'));
      if (!gitignoreFile.existsSync()) {
        await gitignoreFile
            .writeAsString('# Auto-generated files - do not commit\n*.dart\n');
      }

      final buffer = StringBuffer();
      buffer.writeln('// GENERATED FILE - DO NOT EDIT MANUALLY');
      buffer.writeln('// Auto-generated by `dart run modular_flutter build`');
      buffer.writeln('// Auto-imports all enabled modules');
      buffer.writeln('// This file is automatically imported by ModularApp');
      buffer.writeln('');

      // Generate imports for all modules
      for (final entry in moduleImports.entries.toList()..sort()) {
        final packageName = entry.key;
        final moduleFile = entry.value;
        buffer.writeln("import 'package:$packageName/$moduleFile';");
      }

      await modulesFile.writeAsString(buffer.toString());
      print(
          '✓ Generated modules import file with ${moduleImports.length} modules');

      // Auto-update main.dart to import the generated file (fully automatic)

      // This is like Laravel's autoloading - modules are auto-imported, you never touch it!
      await _autoImportModulesInMain(projectRoot, modulesFile);
    } catch (e) {
      print('Warning: Could not generate modules import: $e');
    }
  }

  /// Automatically add modules import to main.dart (no manual work)
  /// This is like Laravel's autoloading - you never see or touch this import
  /// It's automatically added and managed by the build command
  Future<void> _autoImportModulesInMain(
      String projectRoot, File modulesFile) async {
    try {
      final mainDartPath = path.join(projectRoot, 'lib', 'main.dart');
      final mainDartFile = File(mainDartPath);

      if (!mainDartFile.existsSync()) {
        return;
      }

      final content = await mainDartFile.readAsString();
      final relativePath =
          path.relative(modulesFile.path, from: path.join(projectRoot, 'lib'));
      final importPath =
          relativePath.replaceAll('\\', '/').replaceFirst('.dart', '');

      // Check if already imported (look for the auto-generated comment)
      if (content.contains("import '$importPath';") ||
          content.contains('modules.dart') ||
          content.contains('module auto-discovery') ||
          content.contains('Auto-generated by modular_flutter build')) {
        return; // Already imported
      }

      final lines = content.split('\n');
      final result = <String>[];
      bool importAdded = false;

      // Find the modular_flutter import and add modules import after it
      // This is like Laravel's autoloading - completely automatic
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        result.add(line);

        // Add import after modular_flutter import
        // You never see or touch this - it's auto-managed
        if (!importAdded && line.contains("import 'package:modular_flutter")) {
          result.add('');
          result.add("// Auto-generated by modular_flutter build");
          result.add(
              "// You never need to touch this - modules are auto-discovered!");
          result.add("import '$importPath';");
          result.add('');
          importAdded = true;
        }
      }

      if (importAdded) {
        await mainDartFile.writeAsString(result.join('\n'));
        print('✓ Auto-updated main.dart (you never need to touch this)');
      }
    } catch (e) {
      print('Warning: Could not auto-update main.dart: $e');
    }
  }
}
