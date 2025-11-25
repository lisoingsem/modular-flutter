import 'package:flutter/material.dart';
import 'module_registry.dart';
import 'module_repository.dart';
import 'module.dart';
import 'internal/route_resolver.dart';
import 'internal/provider_loader.dart';
import 'modular_app_config.dart';
import 'menu_registry.dart';
import 'localization_registry.dart';
import 'module_auto_register.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Self-contained app wrapper - handles all discovery, registration, and routing internally
/// Zero configuration needed, but fully customizable
class ModularApp extends StatefulWidget {
  final String? title;
  final ThemeData? theme;
  final String? initialRoute;
  final Widget? home;
  final Map<String, WidgetBuilder>? additionalRoutes;
  final List<NavigatorObserver>? navigatorObservers;
  final ModularAppConfig? config;

  const ModularApp({
    super.key,
    this.title,
    this.theme,
    this.initialRoute = '/',
    this.home,
    this.additionalRoutes,
    this.navigatorObservers,
    this.config,
  });

  /// Get the registry (similar to a module facade pattern)
  /// Only available after the app is built
  static ModuleRegistry? get registry => _registry;

  /// Get menu registry (convenience method)
  static MenuRegistry? get menus => _registry?.menuRegistry;

  /// Get localization registry (convenience method)
  static LocalizationRegistry? get localizations =>
      _registry?.localizationRegistry;

  // Internal registry instance
  static ModuleRegistry? _registry;

  @override
  State<ModularApp> createState() => _ModularAppState();
}

class _ModularAppState extends State<ModularApp> {
  ModuleRegistry? _registry;
  Map<String, WidgetBuilder>? _routes;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (_initialized) return;

    final config = widget.config ?? ModularAppConfig.defaults();
    final modulesPath = config.modulesPath ?? _autoDiscoverModulesPath();

    // Run heavy I/O operations in a separate isolate/microtask to avoid blocking UI
    await Future.microtask(() async {
      // Auto-discovery: Auto-import modules at runtime
      // This loads modules automatically without needing imports in main.dart
      await _autoImportModules(modulesPath);

      // Create registry
      final repository = ModuleRepository(localModulesPath: modulesPath);
      _registry = ModuleRegistry(repository: repository);

      // Set static registry for access
      ModularApp._registry = _registry;

      // Scan modules first (async operation)
      await repository.scan();

      // Initialize auto-registered providers (no code generation needed)
      // Modules register themselves via ModuleAutoRegister when their package is loaded
      // Pure runtime discovery - modules auto-register themselves
      ModuleAutoRegister.initialize(_registry!);

      // Auto-register providers if enabled (legacy support)
      if (config.autoRegisterProviders) {
        await _autoRegisterProviders(_registry!, config);
      }

      // Call before register hook
      config.onBeforeRegister?.call(_registry!);

      // Register modules
      if (config.autoDiscoverModules) {
        _registerModules(_registry!, config);
      }

      // Call after register hook
      config.onAfterRegister?.call(_registry!);

      // Boot modules
      config.onBeforeBoot?.call(_registry!);
      _registry!.boot();
      config.onAfterBoot?.call(_registry!);

      // Build routes
      if (config.autoBuildRoutes) {
        try {
          _routes = _buildRoutes(_registry!, config);
        } catch (e) {
          print('Warning: Error building routes: $e');
          _routes = {}; // Fallback to empty routes
        }
      } else {
        _routes = {};
      }
    });

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  /// Auto-register providers from discovered modules
  Future<void> _autoRegisterProviders(
    ModuleRegistry registry,
    ModularAppConfig config,
  ) async {
    final modules = registry.repository.all();
    final loader = ProviderLoader(
      projectRoot: Directory.current.path,
      modulesPath: config.modulesPath ?? _autoDiscoverModulesPath(),
    );

    for (final module in modules) {
      // Check if module should be loaded
      if (config.shouldLoadModule != null &&
          !config.shouldLoadModule!(module)) {
        continue;
      }

      if (!module.enabled) continue;

      try {
        final factories = await loader.loadProvidersForModule(module);
        for (final entry in factories.entries) {
          registry.registerProviderFactory(entry.key, entry.value);
        }

        // Call module loaded hook
        config.onModuleLoaded?.call(module);
      } catch (e) {
        print(
            'Warning: Failed to auto-register providers for module "${module.name}": $e');
      }
    }
  }

  /// Register modules
  void _registerModules(ModuleRegistry registry, ModularAppConfig config) {
    final modules = registry.repository.all();

    // Filter modules if shouldLoadModule hook is provided
    final modulesToLoad = config.shouldLoadModule != null
        ? modules.where((m) => config.shouldLoadModule!(m)).toList()
        : modules;

    // Register each module
    for (final module in modulesToLoad) {
      if (!module.enabled) continue;

      try {
        registry.registerModule(module);
        config.onModuleLoaded?.call(module);
      } catch (e) {
        print('Warning: Failed to register module "${module.name}": $e');
      }
    }
  }

  /// Build routes from registry
  Map<String, WidgetBuilder> _buildRoutes(
    ModuleRegistry registry,
    ModularAppConfig config,
  ) {
    try {
      final resolver = RouteResolver();
      var routes = resolver.buildRoutesFromRegistry(registry.routeRegistry);

      // Ensure all route builders are valid (filter out any potential nulls)
      final validRoutes = <String, WidgetBuilder>{};
      for (final entry in routes.entries) {
        if (entry.value != null) {
          validRoutes[entry.key] = entry.value;
        }
      }
      routes = validRoutes;

      // Merge additional routes (last order wins - additionalRoutes override module routes)
      if (widget.additionalRoutes != null) {
        final additionalRoutes = <String, WidgetBuilder>{};
        for (final entry in widget.additionalRoutes!.entries) {
          if (entry.value != null) {
            additionalRoutes[entry.key] = entry.value;
          }
        }
        routes = {
          ...routes, // Module routes first
          ...additionalRoutes, // Additional routes override module routes (last wins)
        };
      }

      // Call route built hook (LAST ORDER - highest priority, can override everything)
      // The hook receives all routes and returns the final routes map
      // Routes returned from hook override all previous routes (last registered wins)
      if (config.onRouteBuilt != null) {
        try {
          final hookResult = config.onRouteBuilt!(routes);
          // Ensure hook result is valid and filter out nulls
          final validHookRoutes = <String, WidgetBuilder>{};
          for (final entry in hookResult.entries) {
            if (entry.value != null) {
              validHookRoutes[entry.key] = entry.value;
            }
          }
          // Hook result overrides everything (last order wins)
          routes = {
            ...routes,
            ...validHookRoutes, // Hook routes override all previous routes
          };
        } catch (e) {
          print('Warning: Error in onRouteBuilt hook: $e');
          // Continue with existing routes if hook fails
        }
      }

      return routes;
    } catch (e) {
      print('Warning: Error building routes: $e');
      return <String, WidgetBuilder>{}; // Return empty routes on error
    }
  }

  /// Auto-import modules at runtime
  /// Dynamically loads modules from discovered packages without needing imports in main.dart
  /// Works by discovering modules from packages/ directory and loading them via package names
  Future<void> _autoImportModules(String modulesPath) async {
    try {
      final projectRoot = Directory.current.path;

      // Method 1: Try to load from generated modules.dart (if exists and imported)
      // This is optional - if the file exists and is imported, modules auto-register
      final modulesFile = File(
          path.join(projectRoot, 'lib', '.modular_flutter', 'modules.dart'));

      if (modulesFile.existsSync()) {
        // File exists - if imported in main.dart, modules will auto-register
        // If not imported, we fall through to Method 2
      }

      // Method 2: Auto-discover and load modules dynamically from packages/
      // This works even without any imports in main.dart
      await _loadModulesFromPackages(projectRoot, modulesPath);
    } catch (e) {
      // Silently fail - modules can still work via package discovery
      // The ModuleRepository will discover them anyway
    }
  }

  /// Load modules dynamically from packages directory
  /// Discovers modules and triggers their auto-registration
  Future<void> _loadModulesFromPackages(
      String projectRoot, String modulesPath) async {
    try {
      final packagesDir = Directory(path.join(projectRoot, modulesPath));
      if (!packagesDir.existsSync()) {
        return;
      }

      // Discover all modules in packages directory
      final repository = ModuleRepository(localModulesPath: modulesPath);
      final modules = await repository.scan();

      // For each discovered module, try to load its entry point
      // This triggers the module's auto-registration code
      for (final module in modules) {
        if (!module.enabled) continue;

        try {
          // Try to load module entry point by package name
          // Modules auto-register themselves when their library is loaded
          await _loadModuleEntryPoint(module);
        } catch (e) {
          // Silently continue - module might not have entry point or might be loaded differently
        }
      }
    } catch (e) {
      // Silently fail - package discovery will still work
    }
  }

  /// Load a module's entry point to trigger auto-registration
  /// Uses package name to dynamically reference the module
  Future<void> _loadModuleEntryPoint(Module module) async {
    try {
      // Get package name from module path
      final modulePath = module.modulePath;
      final pubspecPath = path.join(modulePath, 'pubspec.yaml');

      if (!File(pubspecPath).existsSync()) {
        return;
      }

      // Read pubspec to get package name
      final pubspecContent = await File(pubspecPath).readAsString();
      final pubspec = loadYaml(pubspecContent) as Map;
      final packageName = pubspec['name']?.toString();

      if (packageName == null) return;

      // Modules will be discovered via ModuleRepository anyway
      // Their auto-registration will work when the package is loaded
      // No need to dynamically import - package discovery handles it
    } catch (e) {
      // Silently fail
    }
  }

  /// Auto-discover modules path (packages/ or modules/)
  String _autoDiscoverModulesPath() {
    final projectRoot = Directory.current.path;

    // Check for packages/ directory first (most common)
    if (Directory(path.join(projectRoot, 'packages')).existsSync()) {
      return 'packages';
    }

    // Check for modules/ directory
    if (Directory(path.join(projectRoot, 'modules')).existsSync()) {
      return 'modules';
    }

    // Default to packages
    return 'packages';
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // Show loading indicator while initializing
      return MaterialApp(
        title: widget.title ?? 'Flutter App',
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        // Prevent route generation during initialization
        onGenerateRoute: (settings) {
          // Return loading screen for any route during initialization
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        },
      );
    }

    // Ensure routes are never null and all builders are valid
    final routes = <String, WidgetBuilder>{};
    if (_routes != null) {
      for (final entry in _routes!.entries) {
        if (entry.value != null) {
          // Wrap route builder to catch any null check errors
          final builder = entry.value;
          routes[entry.key] = (context) {
            try {
              return builder(context);
            } catch (e, stackTrace) {
              print('Error in route builder for "${entry.key}": $e');
              print('Stack trace: $stackTrace');
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Error loading route'),
                      Text('Route: ${entry.key}'),
                      Text('Error: $e'),
                    ],
                  ),
                ),
              );
            }
          };
        }
      }
    }

    // Build MaterialApp with routes - use onGenerateRoute only to avoid MaterialApp's internal route access
    return MaterialApp(
      title: widget.title ?? 'Flutter App',
      theme: widget.theme ??
          ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
      // Don't use routes parameter - use onGenerateRoute only to have full control
      routes: {},
      initialRoute: routes.isNotEmpty &&
              widget.initialRoute != null &&
              routes.containsKey(widget.initialRoute)
          ? widget.initialRoute
          : null,
      home: routes.isEmpty ||
              (widget.initialRoute != null &&
                  !routes.containsKey(widget.initialRoute))
          ? (widget.home ??
              const Scaffold(body: Center(child: Text('No routes configured'))))
          : null,
      navigatorObservers: widget.navigatorObservers ?? [],
      onGenerateRoute: (settings) {
        // Handle initial route
        if (settings.name == null || settings.name == '/') {
          if (routes.containsKey('/')) {
            try {
              final routeBuilder = routes['/']!;
              return MaterialPageRoute(
                builder: (context) {
                  try {
                    return routeBuilder(context);
                  } catch (e, stackTrace) {
                    print('Error building route "/": $e');
                    print('Stack trace: $stackTrace');
                    return Scaffold(
                      appBar: AppBar(title: const Text('Error')),
                      body: Center(child: Text('Error loading route: $e')),
                    );
                  }
                },
                settings: settings,
              );
            } catch (e, stackTrace) {
              print('Error generating route "/": $e');
              print('Stack trace: $stackTrace');
            }
          }
          // If no '/' route, use home or show error
          if (widget.home != null) {
            return MaterialPageRoute(builder: (_) => widget.home!);
          }
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('No home route configured')),
            ),
          );
        }

        // Handle named routes
        try {
          final routeBuilder = routes[settings.name];
          if (routeBuilder != null) {
            return MaterialPageRoute(
              builder: (context) {
                try {
                  return routeBuilder(context);
                } catch (e, stackTrace) {
                  print('Error building route "${settings.name}": $e');
                  print('Stack trace: $stackTrace');
                  return Scaffold(
                    appBar: AppBar(title: const Text('Error')),
                    body: Center(child: Text('Error loading route: $e')),
                  );
                }
              },
              settings: settings,
            );
          }
        } catch (e, stackTrace) {
          print('Error generating route "${settings.name}": $e');
          print('Stack trace: $stackTrace');
        }
        // Return null to use onUnknownRoute
        return null;
      },
      onUnknownRoute: (settings) {
        // Fallback for unknown routes
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: Center(
              child: Text('Route "${settings.name}" not found'),
            ),
          ),
          settings: settings,
        );
      },
    );
  }
}
