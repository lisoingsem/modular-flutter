import 'module_registry.dart';

/// Global registry for module auto-registration
/// Modules can register themselves here at library load time
class ModuleAutoRegister {
  static final Map<String, ProviderFactory> _factories = {};
  static bool _initialized = false;

  /// Register a provider factory (called by modules at library load time)
  /// Format: 'package_name.providers.ClassName'
  static void registerFactory(String className, ProviderFactory factory) {
    _factories[className] = factory;
  }

  /// Get all registered factories
  static Map<String, ProviderFactory> getFactories() {
    return Map.unmodifiable(_factories);
  }

  /// Initialize factories into a registry
  static void initialize(ModuleRegistry registry) {
    if (_initialized) return;
    
    for (final entry in _factories.entries) {
      registry.registerProviderFactory(entry.key, entry.value);
    }
    
    _initialized = true;
  }

  /// Reset (for testing)
  static void reset() {
    _factories.clear();
    _initialized = false;
  }
}

