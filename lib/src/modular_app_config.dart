import 'module.dart';
import 'module_registry.dart';
import 'package:flutter/material.dart';

/// Configuration for ModularApp
/// Allows customization of module loading, registration, and routing
class ModularAppConfig {
  /// Custom modules path (default: auto-discover 'packages' or 'modules')
  final String? modulesPath;

  /// Hook called before module registration
  /// Allows customizing the registry before modules are registered
  final void Function(ModuleRegistry registry)? onBeforeRegister;

  /// Hook called after module registration
  /// Allows customizing the registry after modules are registered
  final void Function(ModuleRegistry registry)? onAfterRegister;

  /// Hook called after routes are built
  /// Allows customizing routes before they're used
  final Map<String, WidgetBuilder> Function(
    Map<String, WidgetBuilder> routes,
  )? onRouteBuilt;

  /// Hook called when a module is loaded
  /// Allows customizing per module
  final void Function(Module module)? onModuleLoaded;

  /// Hook to determine if a module should be loaded
  /// Return false to skip loading a module
  final bool Function(Module module)? shouldLoadModule;

  /// Hook called before module boot
  final void Function(ModuleRegistry registry)? onBeforeBoot;

  /// Hook called after module boot
  final void Function(ModuleRegistry registry)? onAfterBoot;

  /// Whether to enable auto-discovery of modules
  final bool autoDiscoverModules;

  /// Whether to enable auto-registration of providers
  final bool autoRegisterProviders;

  /// Whether to enable auto-building of routes
  final bool autoBuildRoutes;

  const ModularAppConfig({
    this.modulesPath,
    this.onBeforeRegister,
    this.onAfterRegister,
    this.onRouteBuilt,
    this.onModuleLoaded,
    this.shouldLoadModule,
    this.onBeforeBoot,
    this.onAfterBoot,
    this.autoDiscoverModules = true,
    this.autoRegisterProviders = true,
    this.autoBuildRoutes = true,
  });

  /// Create a config with default values
  factory ModularAppConfig.defaults() {
    return const ModularAppConfig();
  }

  /// Create a config that only loads enabled modules
  factory ModularAppConfig.enabledOnly() {
    return ModularAppConfig(
      shouldLoadModule: (module) => module.enabled,
    );
  }

  /// Create a config with custom module filter
  factory ModularAppConfig.custom({
    required bool Function(Module module) filter,
  }) {
    return ModularAppConfig(
      shouldLoadModule: filter,
    );
  }
}
