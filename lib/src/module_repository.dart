import 'dart:io';
import 'package:path/path.dart' as path;
import 'module.dart';
import 'activator.dart';
import 'module_filter.dart';
import 'package_discovery.dart';
import 'exceptions/module_exceptions.dart';

/// Repository for managing and discovering modules
class ModuleRepository {
  final String modulesPath;
  final Activator activator;
  final bool autoDiscoverPackages;
  final String? localModulesPath;
  Map<String, Module>? _modules;

  ModuleRepository({
    String? modulesPath,
    Activator? activator,
    this.autoDiscoverPackages = true,
    this.localModulesPath,
  })  : modulesPath =
            modulesPath ?? path.join(Directory.current.path, 'modules'),
        activator = activator ?? FileActivator() {
    // Load module statuses from activator
    _syncActivatorStatuses();
  }

  /// Sync module enabled status with activator
  void _syncActivatorStatuses() {
    final enabledModules = activator.getEnabledModules();
    final disabledModules = activator.getDisabledModules();

    if (_modules != null) {
      for (final module in _modules!.values) {
        final moduleName = module.name.toLowerCase();
        if (enabledModules.contains(moduleName)) {
          module.enabled = true;
        } else if (disabledModules.contains(moduleName)) {
          module.enabled = false;
        }
      }
    }
  }

  /// Scan and discover all modules
  /// Auto-discovers from local modules/ directory and installed packages
  Future<List<Module>> scan() async {
    _modules = {};

    // Discover modules from all sources
    final discoveredModules = autoDiscoverPackages
        ? await PackageDiscovery.discoverFromPackages(
            projectRoot: Directory.current.path,
            activator: activator,
            localModulesPath: localModulesPath)
        : _scanLocalModules();

    // Process discovered modules
    for (final module in discoveredModules) {
      try {
        // Sync with activator
        final moduleName = module.name.toLowerCase();
        if (activator.getEnabledModules().contains(moduleName)) {
          module.enabled = true;
        } else if (activator.getDisabledModules().contains(moduleName)) {
          module.enabled = false;
        }

        // Handle duplicates (local modules take precedence)
        if (!_modules!.containsKey(moduleName)) {
          _modules![moduleName] = module;
        }
      } catch (e) {
        print('Warning: Failed to process module ${module.name}: $e');
      }
    }

    return _modules!.values.toList();
  }

  /// Scan only local modules directory (legacy method)
  List<Module> _scanLocalModules() {
    final modulesDir = Directory(modulesPath);

    if (!modulesDir.existsSync()) {
      return [];
    }

    // Scan for module.yaml files
    final moduleYamlFiles = modulesDir
        .listSync(recursive: false, followLinks: false)
        .whereType<Directory>()
        .map((dir) => path.join(dir.path, 'module.yaml'))
        .where((yamlPath) => File(yamlPath).existsSync())
        .toList();

    final modules = <Module>[];
    for (final yamlPath in moduleYamlFiles) {
      try {
        final moduleDir = path.dirname(yamlPath);
        modules.add(Module.fromPath(moduleDir));
      } catch (e) {
        print(
            'Warning: Failed to load module at ${path.dirname(yamlPath)}: $e');
      }
    }

    return modules;
  }

  /// Get all modules
  List<Module> all() {
    if (_modules == null) {
      scan();
    }
    return _modules!.values.toList();
  }

  /// Get all enabled modules
  List<Module> allEnabled() {
    return all().where((module) => module.enabled).toList();
  }

  /// Get all disabled modules
  List<Module> allDisabled() {
    return all().where((module) => !module.enabled).toList();
  }

  /// Get modules by status
  List<Module> getByStatus(bool enabled) {
    return all().where((module) => module.enabled == enabled).toList();
  }

  /// Get ordered modules (by priority)
  List<Module> getOrdered({String direction = 'asc'}) {
    final modules = allEnabled();
    modules.sort((a, b) {
      if (direction == 'desc') {
        return b.priority.compareTo(a.priority);
      }
      return a.priority.compareTo(b.priority);
    });
    return modules;
  }

  /// Check if a module exists
  bool has(String name) {
    return _modules?.containsKey(name.toLowerCase()) ?? false;
  }

  /// Get a module by name
  Module? find(String name) {
    if (_modules == null) {
      scan();
    }
    return _modules![name.toLowerCase()];
  }

  /// Get a module by name or throw exception
  Module get(String name) {
    final module = find(name);
    if (module == null) {
      throw ModuleNotFoundException(name);
    }
    return module;
  }

  /// Enable a module
  void enable(String name) {
    final module = get(name);
    activator.enable(module);
    module.enabled = true;
  }

  /// Disable a module
  void disable(String name) {
    final module = get(name);
    activator.disable(module);
    module.enabled = false;
  }

  /// Get module count
  int count() {
    return all().length;
  }

  /// Clear cached modules (force rescan)
  void clearCache() {
    _modules = null;
  }

  /// Get modules with filter applied
  List<Module> filtered(ModuleFilter filter) {
    return filter.apply(all());
  }
}
