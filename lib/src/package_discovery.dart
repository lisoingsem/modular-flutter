import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:yaml/yaml.dart';
import 'module.dart';
import 'activator.dart';

/// Discovers modules from installed packages (pub.dev, git, path)
/// Auto-discovery for package dependencies
class PackageDiscovery {
  /// Discover modules from all installed packages
  /// Uses package_config.json ONLY (like Melos) - no directory scanning
  static Future<List<Module>> discoverFromPackages({
    String? projectRoot,
    Activator? activator,
    String? localModulesPath,
  }) async {
    print(
        'PackageDiscovery: Using package_config.json for discovery (Melos-style)');

    // ONLY use package_config.json - no directory scanning
    // This works on all platforms and doesn't need project root
    final packageModules = await _discoverFromPackages(null, activator);
    return packageModules;
  }


  /// Discover modules from installed packages using package_config.json
  /// This is the ONLY discovery method (like Melos)
  static Future<List<Module>> _discoverFromPackages(
      String? projectRoot, Activator? activator) async {
    final modules = <Module>[];

    // Find package_config.json - try multiple locations
    String? packageConfigPath;

    // Try 1: Relative to current directory (works in most cases)
    var configFile = File('.dart_tool/package_config.json');
    if (configFile.existsSync()) {
      packageConfigPath = configFile.path;
      print(
          'PackageDiscovery: Found package_config.json at: $packageConfigPath');
    } else {
      // Try 2: Use projectRoot if provided
      if (projectRoot != null && projectRoot.isNotEmpty && projectRoot != '/') {
        configFile =
            File(path.join(projectRoot, '.dart_tool', 'package_config.json'));
        if (configFile.existsSync()) {
          packageConfigPath = configFile.path;
          print(
              'PackageDiscovery: Found package_config.json at: $packageConfigPath');
        }
      }

      // Try 3: Look in parent directories (up to 5 levels)
      if (packageConfigPath == null) {
        var currentDir = Directory.current;
        for (int i = 0; i < 5; i++) {
          configFile = File(
              path.join(currentDir.path, '.dart_tool', 'package_config.json'));
          if (configFile.existsSync()) {
            packageConfigPath = configFile.path;
            print(
                'PackageDiscovery: Found package_config.json at: $packageConfigPath');
            break;
          }
          currentDir = currentDir.parent;
          if (!currentDir.existsSync() ||
              currentDir.path == currentDir.parent.path) {
            break;
          }
        }
      }
    }

    if (packageConfigPath == null) {
      print(
          'PackageDiscovery: package_config.json not found - no modules will be discovered');
      return modules;
    }

    final packageConfigFile = File(packageConfigPath);

    if (packageConfigFile.existsSync()) {
      try {
        // Use async read to avoid blocking main thread
        final content = await packageConfigFile.readAsString();
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
            // Only add if enabled (if activator is provided)
            if (activator == null || activator.hasStatus(module, true)) {
              modules.add(module);
            }
          }
        }
      } catch (e) {
        print('Warning: Failed to read package_config.json: $e');
      }
    }

    return modules;
  }

  /// Resolve package URI to absolute path
  static String? _resolvePackagePath(String uri, String? projectRoot) {
    if (uri.startsWith('file://')) {
      // Remove file:// prefix and decode
      var pathStr = uri.substring(7);
      if (Platform.isWindows) {
        // Windows paths might have extra slashes
        pathStr = pathStr.replaceAll('/', '\\');
      }
      return path.normalize(pathStr);
    } else if (uri.startsWith('../') || uri.startsWith('./')) {
      // Relative path - use package_config.json's directory as base
      // Since we found package_config.json, use its parent as base
      if (projectRoot != null && projectRoot.isNotEmpty) {
        return path.normalize(path.join(projectRoot, uri));
      }
      // Try to resolve relative to current directory
      return path.normalize(path.join(Directory.current.path, uri));
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
