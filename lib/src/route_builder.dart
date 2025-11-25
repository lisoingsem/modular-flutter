import 'route_registry.dart';
import 'package:flutter/material.dart';
import 'internal/route_resolver.dart';

/// Build routes map from RouteRegistry (like Laravel route registration)
/// Uses internal route resolver to dynamically resolve routes
Map<String, WidgetBuilder> buildRoutesFromRegistry(RouteRegistry registry) {
  final resolver = RouteResolver();
  return resolver.buildRoutesFromRegistry(registry);
}
