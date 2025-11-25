import 'module.dart';
import 'module_repository.dart';
import 'module_provider.dart';
import 'route_registry.dart';
import 'localization_registry.dart';
import 'localization_loader.dart';
import 'menu_registry.dart';
import 'exceptions/module_exceptions.dart';

/// Callback type for provider instantiation
/// Providers can be ModuleProvider or any class with register()/boot() methods
typedef ProviderFactory = dynamic Function(Module module);

/// Registry for managing module registration and booting
class ModuleRegistry {
  final ModuleRepository repository;
  final RouteRegistry routeRegistry;
  final LocalizationRegistry localizationRegistry;
  final MenuRegistry menuRegistry;
  final Map<String, ProviderFactory> _providerFactories = {};
  final List<dynamic> _providers = []; // Can be ModuleProvider or any class
  final bool autoDiscoverProviders;
  bool _registered = false;
  bool _booted = false;

  ModuleRegistry({
    ModuleRepository? repository,
    RouteRegistry? routeRegistry,
    LocalizationRegistry? localizationRegistry,
    MenuRegistry? menuRegistry,
    String? localModulesPath,
    this.autoDiscoverProviders = false,
  })  : repository =
            repository ?? ModuleRepository(localModulesPath: localModulesPath),
        routeRegistry = routeRegistry ?? RouteRegistry(),
        localizationRegistry = localizationRegistry ??
            LocalizationRegistry(
              repository: repository ??
                  ModuleRepository(localModulesPath: localModulesPath),
            ),
        menuRegistry = menuRegistry ??
            MenuRegistry(
              repository: repository ??
                  ModuleRepository(localModulesPath: localModulesPath),
            );

  /// Register a provider factory for a class name
  /// This allows modules to register their providers without using reflection
  void registerProviderFactory(String className, ProviderFactory factory) {
    _providerFactories[className] = factory;
  }

  /// Register multiple provider factories at once
  /// Useful when you have many modules - register all providers in one call
  void registerProviderFactories(Map<String, ProviderFactory> factories) {
    _providerFactories.addAll(factories);
  }

  /// Auto-register providers from enabled modules
  /// This discovers modules and registers their providers automatically
  /// Only enabled modules are registered
  void autoRegisterFromModules() {
    final modules = repository.getOrdered();
    for (final module in modules) {
      if (!module.enabled) {
        continue; // Skip disabled modules
      }
      // Providers will be registered when register() is called
      // This method is here for future auto-discovery enhancements
    }
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
  /// Similar to Laravel modules: auto-discovers providers from module.yaml
  void registerModule(Module module) {
    // Register service providers (like Laravel modules auto-discovery)
    // Providers are listed in module.yaml and must be registered via registerProviderFactory()
    for (final providerClass in module.providers) {
      try {
        final factory = _providerFactories[providerClass];
        if (factory != null) {
          final provider = factory(module);
          if (provider != null) {
            // Set localization registry if provider supports it (ModuleProvider)
            if (provider is ModuleProvider) {
              provider.setLocalizationRegistry(localizationRegistry);
            }
            // Call register() if it exists (works for both ModuleProvider and plain classes)
            try {
              // Use dynamic call to support both ModuleProvider and plain classes
              if (provider is ModuleProvider) {
                provider.register();
              } else {
                // Try to call register() on plain class using noSuchMethod
                (provider as dynamic).register();
              }
            } catch (e) {
              // Provider might not have register() - that's OK, skip it
            }
            _providers.add(provider);
          }
        } else {
          // In Laravel modules, missing providers are logged but don't stop execution
          print(
            'Warning: Provider "$providerClass" not registered. '
            'Register it using registerProviderFactory() or registerProviderFactories(). '
            'Format: package_name.providers.ModuleNameServiceProvider',
          );
        }
      } catch (e) {
        print('Warning: Failed to register provider "$providerClass": $e');
      }
    }

    // Register routes
    routeRegistry.registerModuleRoutes(module);

    // Register menus (from module.yaml)
    if (module.menus.isNotEmpty) {
      menuRegistry.registerModuleMenus(module);
    }

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
        // Call boot() if it exists (works for both ModuleProvider and plain classes)
        if (provider is ModuleProvider) {
          provider.boot();
        } else {
          // Try to call boot() on plain class using dynamic
          (provider as dynamic).boot();
        }
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
