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
  /// Routes registered ONLY via ModuleProvider.registerRoutes()
  /// NO module.yaml routes - everything through providers
  Map<String, WidgetBuilder> buildRoutesFromRegistry(
    RouteRegistry routeRegistry,
  ) {
    // Routes are registered ONLY via ModuleProvider.registerRoutes()
    // No fallback to module.yaml - routes must be in providers
    // getAllBuilders() already returns non-null WidgetBuilders, so this is safe
    return routeRegistry.getAllBuilders();
  }
}
