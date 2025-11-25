import 'package:flutter/material.dart';
import 'module_registry.dart';
import 'module_repository.dart';
import 'internal/route_resolver.dart';
import 'internal/provider_loader.dart';
import 'modular_app_config.dart';
import 'menu_registry.dart';
import 'localization_registry.dart';
import 'module_auto_register.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Self-contained app wrapper - handles all discovery, registration, and routing internally
/// Like Laravel Modules - zero configuration needed, but fully customizable
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

  /// Get the registry (like Laravel's Module facade)
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

    // Create registry
    _registry = ModuleRegistry(
      repository: ModuleRepository(localModulesPath: modulesPath),
    );

    // Set static registry for access
    ModularApp._registry = _registry;

    // Initialize auto-registered providers (Laravel-style - no code generation!)
    // Modules register themselves via ModuleAutoRegister when their package is loaded
    // This works like Laravel's auto-discovery - pure runtime discovery
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
      _routes = _buildRoutes(_registry!, config);
    }

    setState(() {
      _initialized = true;
    });
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
    final resolver = RouteResolver();
    var routes = resolver.buildRoutesFromRegistry(registry.routeRegistry);

    // Merge additional routes (last order wins - additionalRoutes override module routes)
    if (widget.additionalRoutes != null) {
      routes = {
        ...routes, // Module routes first
        ...widget.additionalRoutes!, // Additional routes override module routes
      };
    }

    // Call route built hook (last order - can override everything)
    // The hook receives all routes and returns the final routes map
    if (config.onRouteBuilt != null) {
      routes = config.onRouteBuilt!(routes);
    }

    return routes;
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
      );
    }

    final routes = _routes ?? {};

    // MaterialApp doesn't allow both 'home' and 'routes' when routes contains '/'
    // If routes contains '/', we must use routes and cannot use home
    final hasHomeRoute = routes.containsKey('/');
    final hasRoutes = routes.isNotEmpty;

    // Build MaterialApp - last registered route wins (Laravel-style)
    // If routes contains '/', we cannot use home - use routes only
    if (hasHomeRoute) {
      return MaterialApp(
        title: widget.title ?? 'Flutter App',
        theme: widget.theme ??
            ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
        routes: routes,
        initialRoute: widget.initialRoute,
        navigatorObservers: widget.navigatorObservers ?? [],
      );
    }

    // If we have routes but no '/', we can use both
    if (hasRoutes) {
      return MaterialApp(
        title: widget.title ?? 'Flutter App',
        theme: widget.theme ??
            ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
        routes: routes,
        initialRoute: widget.initialRoute,
        home: widget.home,
        navigatorObservers: widget.navigatorObservers ?? [],
      );
    }

    // No routes - use home if provided
    return MaterialApp(
      title: widget.title ?? 'Flutter App',
      theme: widget.theme ??
          ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
      initialRoute: widget.initialRoute,
      home: widget.home,
      navigatorObservers: widget.navigatorObservers ?? [],
    );
  }
}
