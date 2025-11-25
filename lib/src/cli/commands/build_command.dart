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
      final basePath = path.join(projectRoot, 'pubspec.yaml.base');

      // Detect modules path
      String? modulesPath;
      if (Directory(path.join(projectRoot, 'packages')).existsSync()) {
        modulesPath = 'packages';
      } else if (Directory(path.join(projectRoot, 'modules')).existsSync()) {
        modulesPath = 'modules';
      }

      // If base exists, auto-generate pubspec.yaml (modules never in git)
      if (File(basePath).existsSync()) {
        await _generateFromBase(
            basePath, pubspecPath, projectRoot, modulesPath);
      } else if (File(pubspecPath).existsSync()) {
        // Fallback: update existing pubspec.yaml
        if (modulesPath != null) {
          await _autoSyncPubspec(pubspecPath, projectRoot, modulesPath);
        }
      } else {
        print(
            'Error: Not in a Flutter project (pubspec.yaml or pubspec.yaml.base not found)');
        return 1;
      }

      print('✓ Build complete');
      print('');
      print('Note: Module registration and route building are handled');
      print(
          'automatically by ModularApp at runtime. No code generation needed!');
      print('');
      print('Your main.dart can now be as simple as:');
      print('  void main() {');
      print("    runApp(ModularApp(title: 'My App'));");
      print('  }');
      print('');
      print('Modules auto-register themselves when their packages are loaded.');
      print(
          'Just add modules to pubspec.yaml and they will be discovered automatically!');

      return 0;
    } catch (e) {
      print('Error generating modules.dart: $e');
      return 1;
    }
  }

  /// Generate pubspec.yaml from template (prevents git conflicts)
  Future<void> _autoSyncPubspec(
      String pubspecPath, String projectRoot, String modulesPath) async {
    try {
      // Use ModuleRepository to discover modules (same way as build command)
      final repository = ModuleRepository(localModulesPath: modulesPath);
      final modules = repository.scan();

      if (modules.isEmpty) {
        return;
      }

      // Get package names from discovered modules
      final discoveredModules = <String, String>{}; // packageName -> path
      for (final module in modules) {
        try {
          // Read module's pubspec.yaml to get actual package name
          final modulePubspecPath =
              path.join(projectRoot, modulesPath, module.alias, 'pubspec.yaml');
          if (File(modulePubspecPath).existsSync()) {
            final content = await File(modulePubspecPath).readAsString();
            final yaml = loadYaml(content) as Map;
            final packageName = yaml['name']?.toString();
            if (packageName != null) {
              final relativePath = path.join(modulesPath, module.alias);
              discoveredModules[packageName] = relativePath;
            }
          }
        } catch (e) {
          // Skip invalid modules
        }
      }

      if (discoveredModules.isEmpty) {
        return;
      }

      // Update existing pubspec.yaml
      final pubspecContent = await File(pubspecPath).readAsString();
      final pubspec = loadYaml(pubspecContent) as Map;
      final dependencies = pubspec['dependencies'] as Map? ?? {};

      // Check if we need to update
      bool needsUpdate = false;
      for (final entry in discoveredModules.entries) {
        final packageName = entry.key;
        final modulePath = entry.value;
        final currentDep = dependencies[packageName];

        if (currentDep == null ||
            (currentDep is Map && currentDep['path'] != modulePath)) {
          needsUpdate = true;
          break;
        }
      }

      if (!needsUpdate) {
        return; // Already synced
      }

      // Update pubspec.yaml by replacing modules section
      final moduleNames = discoveredModules.keys.toList()..sort();
      final lines = pubspecContent.split('\n');
      final result = <String>[];
      bool inDependencies = false;
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

          // Detect start of modules section
          if (trimmed.contains('Feature modules') ||
              trimmed.contains('auto-generated')) {
            // Replace with new modules section
            result.add(
                '${' ' * (depsIndent + 2)}# Feature modules (auto-generated by modular_flutter)');
            for (final moduleName in moduleNames) {
              result.add('${' ' * (depsIndent + 2)}$moduleName:');
              result.add(
                  '${' ' * (depsIndent + 4)}path: ${discoveredModules[moduleName]}');
            }
            // Skip old module lines
            i++;
            while (i < lines.length) {
              final nextLine = lines[i];
              final nextIndent =
                  nextLine.isEmpty ? 999 : nextLine.indexOf(RegExp(r'[^\s]'));
              // Stop at next dependency or end of dependencies
              if (nextIndent <= depsIndent + 2 &&
                  !nextLine.trim().isEmpty &&
                  !nextLine.trim().startsWith('#')) {
                i--; // Back up
                break;
              }
              // Skip if it's a module entry
              if (moduleNames
                  .any((name) => nextLine.trim().startsWith('$name:'))) {
                i++;
                continue;
              }
              if (nextIndent > depsIndent + 2) {
                i++; // Skip indented lines (path: etc)
                continue;
              }
              break;
            }
            continue;
          }

          // Skip old module entries
          if (moduleNames.any((name) => trimmed.startsWith('$name:'))) {
            // Skip this module and its path line
            i++;
            while (i < lines.length) {
              final nextLine = lines[i];
              final nextIndent =
                  nextLine.isEmpty ? 999 : nextLine.indexOf(RegExp(r'[^\s]'));
              if (nextIndent <= depsIndent + 2) {
                i--; // Back up
                break;
              }
              i++;
            }
            continue;
          }

          // End of dependencies section
          if (currentIndent <= depsIndent &&
              trimmed.isNotEmpty &&
              !trimmed.startsWith('#')) {
            // Add modules section before this line
            result.add(
                '${' ' * (depsIndent + 2)}# Feature modules (auto-generated by modular_flutter)');
            for (final moduleName in moduleNames) {
              result.add('${' ' * (depsIndent + 2)}$moduleName:');
              result.add(
                  '${' ' * (depsIndent + 4)}path: ${discoveredModules[moduleName]}');
            }
            inDependencies = false;
          }
        }

        result.add(line);
      }

      // Write updated pubspec.yaml
      final updatedContent = result.join('\n');
      if (updatedContent != pubspecContent) {
        await File(pubspecPath).writeAsString(updatedContent);
        print(
            '✓ Auto-synced pubspec.yaml with ${discoveredModules.length} discovered modules');
      }
    } catch (e) {
      // Silently fail - don't break the build process
      print('Warning: Could not auto-sync pubspec.yaml: $e');
    }
  }

  /// Generate pubspec.yaml from base (modules never in git)
  Future<void> _generateFromBase(String basePath, String pubspecPath,
      String projectRoot, String? modulesPath) async {
    try {
      // Read base file
      final baseContent = await File(basePath).readAsString();

      if (modulesPath == null) {
        // No modules, just copy base
        await File(pubspecPath).writeAsString(baseContent);
        return;
      }

      // Discover modules
      final repository = ModuleRepository(localModulesPath: modulesPath);
      final modules = repository.scan();

      if (modules.isEmpty) {
        // No modules, just copy base
        await File(pubspecPath).writeAsString(baseContent);
        return;
      }

      // Get package names
      final discoveredModules = <String, String>{};
      for (final module in modules) {
        try {
          final modulePubspecPath =
              path.join(projectRoot, modulesPath, module.alias, 'pubspec.yaml');
          if (File(modulePubspecPath).existsSync()) {
            final content = await File(modulePubspecPath).readAsString();
            final yaml = loadYaml(content) as Map;
            final packageName = yaml['name']?.toString();
            if (packageName != null) {
              final relativePath = path.join(modulesPath, module.alias);
              discoveredModules[packageName] = relativePath;
            }
          }
        } catch (e) {
          // Skip invalid modules
        }
      }

      // Insert modules after modular_flutter
      final baseLines = baseContent.split('\n');
      final result = <String>[];
      bool inserted = false;

      for (final line in baseLines) {
        result.add(line);

        // Insert modules after modular_flutter
        if (!inserted && line.trim().startsWith('modular_flutter:')) {
          result.add('');
          result.add('  # Feature modules (auto-generated by modular_flutter)');
          final moduleNames = discoveredModules.keys.toList()..sort();
          for (final moduleName in moduleNames) {
            result.add('  $moduleName:');
            result.add('    path: ${discoveredModules[moduleName]}');
          }
          inserted = true;
        }
      }

      // Write generated pubspec.yaml
      await File(pubspecPath).writeAsString(result.join('\n'));
    } catch (e) {
      print('Warning: Could not generate pubspec.yaml: $e');
    }
  }

  // REMOVED: All code generation functions
  // Routes are registered at runtime via ModuleProvider.registerRoutes()
  // Modules auto-register themselves when their packages are loaded
  // No code generation needed - pure Laravel-style runtime discovery!
}
