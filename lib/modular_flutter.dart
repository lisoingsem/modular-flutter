/// Modular Flutter - A modular architecture system for Flutter applications
///
/// This is the public API for modular_flutter. Modules should only import
/// this file and use the exported classes.
library modular_flutter;

// Core classes that modules and apps use
export 'src/module.dart';
export 'src/module_provider.dart';
export 'src/module_registry.dart';
export 'src/module_repository.dart';
export 'src/route_registry.dart';
export 'src/route_builder.dart';
export 'src/localization_registry.dart';
export 'src/config_loader.dart'; // Exports ModuleConfig which modules use
export 'src/activator.dart';
export 'src/module_filter.dart';
export 'src/exceptions/module_exceptions.dart';
export 'src/modular_app.dart'; // Simplified app wrapper
export 'src/modular_app_config.dart'; // Configuration for ModularApp

// Internal implementation - NOT exported (modules should not use these directly)
// - AssetLoader (internal)
// - LocalizationLoader (internal)
// - PackageDiscovery (internal)
