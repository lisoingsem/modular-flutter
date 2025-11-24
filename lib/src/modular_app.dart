import 'package:flutter/material.dart';
import 'module_registry.dart';
import 'module_repository.dart';
import 'route_builder.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Simplified app wrapper - auto-discovers and registers everything
/// Like Laravel Modules - zero configuration needed
class ModularApp extends StatelessWidget {
  final String? title;
  final ThemeData? theme;
  final String? initialRoute;
  final String? localModulesPath;
  final Widget? home;
  final Map<String, WidgetBuilder>? additionalRoutes;
  final List<NavigatorObserver>? navigatorObservers;

  const ModularApp({
    super.key,
    this.title,
    this.theme,
    this.initialRoute = '/',
    this.localModulesPath,
    this.home,
    this.additionalRoutes,
    this.navigatorObservers,
  });

  // Static registry instance (shared with main.dart)
  static ModuleRegistry? _registry;

  /// Set the registry (called from main.dart after registerAllModules)
  static void setRegistry(ModuleRegistry registry) {
    _registry = registry;
  }

  /// Get the registry (like Laravel's Module facade)
  static ModuleRegistry get registry {
    if (_registry == null) {
      throw StateError(
          'ModularApp.setRegistry() must be called before building');
    }
    return _registry!;
  }

  @override
  Widget build(BuildContext context) {
    // Auto-discover modules path if not set
    final modulesPath = localModulesPath ?? _autoDiscoverModulesPath();

    // Use registry set in main.dart, or create new one
    _registry ??= ModuleRegistry(
      repository: ModuleRepository(localModulesPath: modulesPath),
    );

    // Register and boot all modules (like Laravel Modules)
    // Providers are already registered via modules.dart in main.dart
    _registry!.register();
    _registry!.boot();

    // Build routes from modules
    final moduleRoutes = buildRoutesFromRegistry(registry.routeRegistry);
    final allRoutes = {
      ...moduleRoutes,
      if (additionalRoutes != null) ...additionalRoutes!,
    };

    return MaterialApp(
      title: title ?? 'Flutter App',
      theme: theme ??
          ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
      routes: allRoutes,
      initialRoute: initialRoute,
      home: home,
      navigatorObservers: navigatorObservers ?? [],
    );
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
}
