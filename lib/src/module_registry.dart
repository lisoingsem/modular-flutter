import 'module.dart';
import 'module_repository.dart';
import 'module_provider.dart';
import 'route_registry.dart';
import 'localization_registry.dart';
import 'localization_loader.dart';
import 'exceptions/module_exceptions.dart';

/// Callback type for provider instantiation
typedef ProviderFactory = ModuleProvider? Function(Module module);

/// Registry for managing module registration and booting
class ModuleRegistry {
  final ModuleRepository repository;
  final RouteRegistry routeRegistry;
  final LocalizationRegistry localizationRegistry;
  final Map<String, ProviderFactory> _providerFactories = {};
  final List<ModuleProvider> _providers = [];
  bool _registered = false;
  bool _booted = false;

  ModuleRegistry({
    ModuleRepository? repository,
    RouteRegistry? routeRegistry,
    LocalizationRegistry? localizationRegistry,
  })  : repository = repository ?? ModuleRepository(),
        routeRegistry = routeRegistry ?? RouteRegistry(),
        localizationRegistry = localizationRegistry ??
            LocalizationRegistry(repository: repository ?? ModuleRepository());

  /// Register a provider factory for a class name
  /// This allows modules to register their providers without using reflection
  void registerProviderFactory(String className, ProviderFactory factory) {
    _providerFactories[className] = factory;
  }

  /// Register all enabled modules
  void register() {
    if (_registered) {
      return;
    }

    final modules = repository.getOrdered();

    // Check dependencies
    _validateDependencies(modules);

    // Register each module
    for (final module in modules) {
      registerModule(module);
    }

    _registered = true;
  }

  /// Register a single module
  void registerModule(Module module) {
    // Register service providers
    for (final providerClass in module.providers) {
      try {
        final factory = _providerFactories[providerClass];
        if (factory != null) {
          final provider = factory(module);
          if (provider != null) {
            // Set localization registry for provider
            provider.setLocalizationRegistry(localizationRegistry);
            provider.register();
            _providers.add(provider);
          }
        } else {
          print(
            'Warning: No factory registered for provider $providerClass. '
            'Register it using registerProviderFactory()',
          );
        }
      } catch (e) {
        print('Warning: Failed to register provider $providerClass: $e');
      }
    }

    // Register routes
    routeRegistry.registerModuleRoutes(module);

    // Register localizations (only for enabled modules)
    if (module.enabled) {
      final moduleLocalizations =
          LocalizationLoader.getModuleLocalizations(module);
      if (moduleLocalizations.isNotEmpty) {
        localizationRegistry.register();
      }
    }
  }

  /// Boot all registered modules
  void boot() {
    if (!_registered) {
      register();
    }

    if (_booted) {
      return;
    }

    // Boot all providers
    for (final provider in _providers) {
      try {
        provider.boot();
      } catch (e) {
        print('Warning: Failed to boot provider: $e');
      }
    }

    _booted = true;
  }

  /// Validate module dependencies
  void _validateDependencies(List<Module> modules) {
    final moduleNames = modules.map((m) => m.name.toLowerCase()).toSet();

    for (final module in modules) {
      for (final requiredModule in module.requires) {
        final requiredName = requiredModule.toLowerCase();
        if (!moduleNames.contains(requiredName)) {
          throw InvalidModuleException(
            'Module "${module.name}" requires "${requiredModule}" but it is not enabled',
          );
        }
      }
    }
  }

  /// Get all registered providers
  List<ModuleProvider> getProviders() {
    return List.unmodifiable(_providers);
  }

  /// Check if modules are registered
  bool get isRegistered => _registered;

  /// Check if modules are booted
  bool get isBooted => _booted;
}
