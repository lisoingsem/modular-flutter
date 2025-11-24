import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'module.dart';

/// Discovers modules from installed packages (pub.dev, git, path)
/// Similar to Laravel's merge-plugin auto-discovery
class PackageDiscovery {
  /// Discover modules from all installed packages
  static List<Module> discoverFromPackages({String? projectRoot}) {
    final root = projectRoot ?? Directory.current.path;
    final discoveredModules = <Module>[];

    // 1. Discover from local modules directory
    final localModules = _discoverFromDirectory(
      path.join(root, 'modules'),
    );
    discoveredModules.addAll(localModules);

    // 2. Discover from package dependencies
    final packageModules = _discoverFromPackages(root);
    discoveredModules.addAll(packageModules);

    return discoveredModules;
  }

  /// Discover modules from a directory
  static List<Module> _discoverFromDirectory(String modulesPath) {
    final modulesDir = Directory(modulesPath);
    if (!modulesDir.existsSync()) {
      return [];
    }

    final modules = <Module>[];
    for (final entity in modulesDir.listSync()) {
      if (entity is Directory) {
        final moduleYaml = File(path.join(entity.path, 'module.yaml'));
        if (moduleYaml.existsSync()) {
          try {
            modules.add(Module.fromPath(entity.path));
          } catch (e) {
            print('Warning: Failed to load module at ${entity.path}: $e');
          }
        }
      }
    }
    return modules;
  }

  /// Discover modules from installed packages
  static List<Module> _discoverFromPackages(String projectRoot) {
    final modules = <Module>[];

    // Try to read package_config.json (Dart 2.17+)
    final packageConfigPath = path.join(
      projectRoot,
      '.dart_tool',
      'package_config.json',
    );
    final packageConfigFile = File(packageConfigPath);

    if (packageConfigFile.existsSync()) {
      try {
        final content = packageConfigFile.readAsStringSync();
        final packageConfig = jsonDecode(content) as Map<String, dynamic>;
        final packages = packageConfig['packages'] as List? ?? [];

        for (final package in packages) {
          final packageData = package as Map<String, dynamic>;
          final packageName = packageData['name'] as String?;
          final packageRoot = packageData['rootUri'] as String?;

          if (packageName == null || packageRoot == null) continue;

          // Resolve URI to absolute path
          final packagePath = _resolvePackagePath(packageRoot, projectRoot);
          if (packagePath == null) continue;

          // Check if this package is a module
          final module = _tryLoadModuleFromPackage(packagePath, packageName);
          if (module != null) {
            modules.add(module);
          }
        }
      } catch (e) {
        print('Warning: Failed to read package_config.json: $e');
      }
    }

    return modules;
  }

  /// Resolve package URI to absolute path
  static String? _resolvePackagePath(String uri, String projectRoot) {
    if (uri.startsWith('file://')) {
      // Remove file:// prefix and decode
      var pathStr = uri.substring(7);
      if (Platform.isWindows) {
        // Windows paths might have extra slashes
        pathStr = pathStr.replaceAll('/', '\\');
      }
      return path.normalize(pathStr);
    } else if (uri.startsWith('../') || uri.startsWith('./')) {
      // Relative path
      return path.normalize(path.join(projectRoot, uri));
    }
    return null;
  }

  /// Try to load a module from a package directory
  static Module? _tryLoadModuleFromPackage(
      String packagePath, String packageName) {
    // Check for module.yaml in package root
    final moduleYamlPath = path.join(packagePath, 'module.yaml');
    final moduleYaml = File(moduleYamlPath);

    if (moduleYaml.existsSync()) {
      try {
        return Module.fromPath(packagePath);
      } catch (e) {
        // Not a valid module, skip
        return null;
      }
    }

    // Check for modules/ subdirectory (package might contain multiple modules)
    final modulesDir = Directory(path.join(packagePath, 'modules'));
    if (modulesDir.existsSync()) {
      // This package contains multiple modules
      // For now, we'll skip this case - packages should have module.yaml at root
      // or we could scan modules/ subdirectory
      return null;
    }

    return null;
  }

  /// Check if a package is a module
  static bool isModulePackage(String packagePath) {
    final moduleYaml = File(path.join(packagePath, 'module.yaml'));
    return moduleYaml.existsSync();
  }

  /// Get module metadata from package
  static Map<String, dynamic>? getModuleMetadata(String packagePath) {
    final moduleYaml = File(path.join(packagePath, 'module.yaml'));
    if (!moduleYaml.existsSync()) {
      return null;
    }

    try {
      final content = moduleYaml.readAsStringSync();
      final yaml = loadYaml(content) as Map;
      return Map<String, dynamic>.from(yaml);
    } catch (e) {
      return null;
    }
  }
}
