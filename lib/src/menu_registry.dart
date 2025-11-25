import 'module.dart';
import 'module_repository.dart';

/// Registry for managing module menus
/// Auto-registers menus from module.yaml files
class MenuRegistry {
  final ModuleRepository repository;
  final Map<String, List<Map<String, dynamic>>> _menus = {};
  bool _registered = false;

  MenuRegistry({
    ModuleRepository? repository,
  }) : repository = repository ?? ModuleRepository();

  /// Register menus from all enabled modules
  void register() {
    if (_registered) {
      return;
    }

    final enabledModules = repository.allEnabled();

    for (final module in enabledModules) {
      registerModuleMenus(module);
    }

    _registered = true;
  }

  /// Register menus for a specific module
  /// Public method for ModuleRegistry to call
  void registerModuleMenus(Module module) {
    for (final entry in module.menus.entries) {
      final menuGroup = entry.key;
      final menuItems = entry.value;

      if (!_menus.containsKey(menuGroup)) {
        _menus[menuGroup] = [];
      }

      // Add module namespace to menu items
      for (final item in menuItems) {
        final menuItem = Map<String, dynamic>.from(item);
        menuItem['module'] = module.alias;
        _menus[menuGroup]!.add(menuItem);
      }
    }
  }

  /// Get menus for a specific group
  List<Map<String, dynamic>> getMenus(String group) {
    return List.unmodifiable(_menus[group] ?? []);
  }

  /// Get all menus
  Map<String, List<Map<String, dynamic>>> getAllMenus() {
    return Map.unmodifiable(_menus);
  }

  /// Check if menus are registered
  bool get isRegistered => _registered;
}
