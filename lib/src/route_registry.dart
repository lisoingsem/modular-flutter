import 'module.dart';

/// Route definition from a module
class ModuleRoute {
  final String path;
  final String widget;
  final String? name;
  final Map<String, dynamic>? parameters;

  ModuleRoute({
    required this.path,
    required this.widget,
    this.name,
    this.parameters,
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
class RouteRegistry {
  final Map<String, ModuleRoute> _routes = {};

  /// Register routes from a module
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
    try {
      getRoute(nameOrPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all routes
  void clear() {
    _routes.clear();
  }
}
