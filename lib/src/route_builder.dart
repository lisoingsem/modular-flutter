import 'route_registry.dart';
import 'package:flutter/material.dart';

/// Build routes map from RouteRegistry (like Laravel route registration)
///
/// Note: This returns an empty map because route builders need to be
/// resolved from route.widget strings in the app's route_builder.dart.
/// The RouteRegistry only stores route metadata (path, widget string).
Map<String, WidgetBuilder> buildRoutesFromRegistry(RouteRegistry registry) {
  // Routes are built in the app's route_builder.dart file
  // This function is a placeholder for future enhancements
  return <String, WidgetBuilder>{};
}
