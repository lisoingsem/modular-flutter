import 'module.dart';
import 'module_registry.dart';
import 'build/provider_parser.dart';

/// Global registry for auto-registration
/// Modules register themselves here when imported
class ModuleAutoRegister {
  static final Map<String, void Function(ModuleRegistry, Module)>
      _registrations = {};

  /// Register a module's registration function
  /// Called automatically when module.dart is imported
  static void register(
    String moduleAlias,
    void Function(ModuleRegistry, Module) registrationFunction,
  ) {
    _registrations[moduleAlias] = registrationFunction;
  }

  /// Auto-register all discovered modules
  /// Like Laravel Modules - automatically discovers from module.yaml
  static void autoRegisterAll(ModuleRegistry registry) {
    final modules = registry.repository.all();
    for (final module in modules) {
      if (!module.enabled) continue;

      // Try to use registered function first (if module was imported)
      final registration = _registrations[module.alias];
      if (registration != null) {
        registration(registry, module);
        continue;
      }

      // Otherwise, auto-register from module.yaml (like Laravel)
      // Parse provider class names and register them automatically
      for (final providerClass in module.providers) {
        try {
          final parsed = ProviderParser.parse(providerClass);
          // We can't instantiate without the actual class, but we can register the factory
          // The module needs to provide the factory function
          // This is a limitation of Dart - we need the actual class imported
        } catch (e) {
          // Skip invalid providers
        }
      }
    }
  }

  /// Get all registered module aliases
  static Set<String> get registeredAliases => _registrations.keys.toSet();
}
