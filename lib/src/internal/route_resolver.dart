import 'package:flutter/material.dart';
import '../route_registry.dart';
import '../build/route_cache_stub.dart' as cache;

/// Dynamic route resolver that resolves routes without app imports
/// Uses generated route cache file to access widgets
class RouteResolver {
  /// Resolve a route widget from a route definition
  /// Returns a WidgetBuilder for the route
  WidgetBuilder? resolveRoute(String widgetPath) {
    try {
      // Use the route cache (stub or generated)
      return cache.RouteCache.get(widgetPath);
    } catch (e) {
      print('Warning: Failed to resolve route widget "$widgetPath": $e');
      return null;
    }
  }

  /// Build all routes from RouteRegistry
  /// Returns a map of route paths to WidgetBuilders
  /// Laravel-style: Uses runtime-registered routes first, then falls back to YAML routes
  Map<String, WidgetBuilder> buildRoutesFromRegistry(
    RouteRegistry routeRegistry,
  ) {
    final routes = <String, WidgetBuilder>{};

    // First, use runtime-registered routes (Laravel-style - preferred)
    routes.addAll(routeRegistry.getAllBuilders());

    // Then, try to resolve routes from module.yaml (fallback)
    final allRoutes = routeRegistry.getAllRoutes();
    for (final route in allRoutes) {
      // Only add if not already registered by a provider
      if (!routes.containsKey(route.path)) {
        final builder = resolveRoute(route.widget);
        if (builder != null) {
          routes[route.path] = builder;
        } else {
          print(
            'Warning: Could not resolve route widget "${route.widget}" for path "${route.path}". '
            'Register it in your ModuleProvider.registerRoutes() method instead.',
          );
        }
      }
    }

    return routes;
  }
}
