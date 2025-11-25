import 'package:flutter/material.dart';
import 'module.dart';

/// Route definition from a module
class ModuleRoute {
  final String path;
  final String widget;
  final String? name;
  final Map<String, dynamic>? parameters;
  final WidgetBuilder? builder; // Runtime builder

  ModuleRoute({
    required this.path,
    required this.widget,
    this.name,
    this.parameters,
    this.builder,
  });

  factory ModuleRoute.fromMap(Map<String, dynamic> map) {
    return ModuleRoute(
      path: map['path'] as String,
      widget: map['widget'] as String,
      name: map['name'] as String?,
      parameters: map['parameters'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'widget': widget,
      if (name != null) 'name': name,
      if (parameters != null) 'parameters': parameters,
    };
  }
}

/// Registry for managing routes from modules
/// Routes registered at runtime through providers
class RouteRegistry {
  final Map<String, ModuleRoute> _routes = {};
  final Map<String, WidgetBuilder> _builders = {}; // Direct route builders

  /// Register a route with a WidgetBuilder
  /// Last registered route wins - later registrations override earlier ones
  /// This is the preferred method - modules call this in their providers
  void register(String path, WidgetBuilder builder, {String? name}) {
    // Last registration wins - override any existing route with same path
    _builders[path] = builder;
    if (name != null) {
      _builders[name] = builder; // Named routes also override
    }
  }
  
  /// Register multiple routes at once
  /// Last registered routes override earlier ones with same paths
  void registerRoutes(Map<String, WidgetBuilder> routes) {
    // Add all routes - later entries in the map override earlier ones
    _builders.addAll(routes);
  }

  /// Register routes from a module (from module.yaml)
  /// This is a fallback for modules that define routes in YAML
  void registerModuleRoutes(Module module) {
    for (final routeMap in module.routes) {
      final route = ModuleRoute.fromMap(routeMap);
      final routeName = route.name ?? route.path;
      _routes[routeName] = route;
    }
  }

  /// Get all registered routes
  List<ModuleRoute> getAllRoutes() {
    return _routes.values.toList();
  }

  /// Get all route builders (runtime routes)
  Map<String, WidgetBuilder> getAllBuilders() {
    return Map.unmodifiable(_builders);
  }

  /// Get a route builder by path
  WidgetBuilder? getBuilder(String path) {
    return _builders[path];
  }

  /// Get a route by name or path
  ModuleRoute? getRoute(String nameOrPath) {
    return _routes[nameOrPath] ??
        _routes.values.firstWhere(
          (route) => route.path == nameOrPath,
          orElse: () => throw StateError('Route not found'),
        );
  }

  /// Check if a route exists
  bool hasRoute(String nameOrPath) {
    return _builders.containsKey(nameOrPath) ||
        _routes.containsKey(nameOrPath) ||
        _routes.values.any((route) => route.path == nameOrPath);
  }

  /// Clear all routes
  void clear() {
    _routes.clear();
    _builders.clear();
  }
}
