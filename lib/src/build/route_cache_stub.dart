// Stub file - populated by generated route_cache.g.dart
import 'package:flutter/material.dart';

/// Route cache - populated by generated route_cache.g.dart file
class RouteCache {
  /// Public cache map - populated by generated file
  static final Map<String, WidgetBuilder> cache = {};

  /// Get a route builder for a widget path
  static WidgetBuilder? get(String widgetPath) {
    return cache[widgetPath];
  }

  /// Check if a route exists in cache
  static bool has(String widgetPath) {
    return cache.containsKey(widgetPath);
  }
}

