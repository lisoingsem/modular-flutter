# Changelog

All notable changes to this project will be documented in this file.

## [0.4.1] - 2025-01-19

### Fixed
- Removed all code generation - pure runtime discovery
- Fixed duplicate ProviderFactory export issue
- Removed unused imports and generated file references
- Clean build command - only syncs pubspec.yaml

## [0.4.0] - 2025-01-19

### Added
- **Laravel-Style Runtime Route Discovery** - Routes registered at runtime through `ModuleProvider.registerRoutes()` method
- **No Code Generation Required** - Pure runtime discovery, no build commands needed
- **RouteRegistry.register()** - Direct route registration with WidgetBuilder (like Laravel's Route::get())

### Changed
- **Breaking**: Routes now registered in `ModuleProvider.registerRoutes()` instead of module.yaml (module.yaml still works as fallback)
- **RouteResolver** - Now prioritizes runtime-registered routes over YAML-defined routes
- Removed all code generation logic for routes

### Improved
- **True Laravel-Style Discovery** - Modules discovered and routes registered at runtime, just like Laravel modules
- **Simpler Architecture** - No generated files, no build commands, pure runtime discovery
- Better error messages when routes can't be resolved

## [0.3.2] - 2025-01-XX

### Fixed
- Fixed missing `provider_parser.dart` file in published package
- Updated `.pubignore` to not exclude `lib/src/build/` directory

## [0.3.1] - 2025-01-XX

### Fixed
- Package publishing issue resolved

## [0.3.0] - 2025-01-XX

### Added
- **Thin App Architecture** - Zero module imports in app, all complexity in package
- **Self-Contained ModularApp** - Handles all discovery, registration, and route building internally
- **ModularAppConfig** - Comprehensive configuration with customization hooks
- **Internal Provider Loader** - Dynamic provider loading without app imports
- **Internal Route Resolver** - Dynamic route resolution without app imports
- **Menu System** - Auto-register menus from `module.yaml` (inspired by Laravel Menus)
- **MenuRegistry** - Centralized menu management with support for menu groups
- **Translation Support** - Auto-load translations from module `lang/` or `l10n/` directories
- **LocalizationRegistry** - Centralized translation management with module namespaces
- **Optional Module Dependency** - Modules can work without `modular_flutter` as a direct dependency
- **ModuleProviderInterface** - Lightweight interface for standalone modules
- **Customization Hooks** - `onBeforeRegister`, `onAfterRegister`, `onRouteBuilt`, `onModuleLoaded`, `shouldLoadModule`, `onBeforeBoot`, `onAfterBoot`
- **Conditional Module Loading** - Support for loading modules based on custom logic
- **Static Registry Access** - `ModularApp.registry`, `ModularApp.menus`, `ModularApp.localizations` for global access

### Improved
- **Minimal main.dart** - Now just `runApp(ModularApp(title: 'App'))`
- **No Generated App Files** - Removed `app/modules.dart` and `app/route_builder.dart` generation
- **Better Architecture** - All complexity moved to package, app stays thin and clean
- **Easy Customization** - Full control via ModularAppConfig hooks
- **Module Configuration** - All module aspects (providers, routes, menus, localizations) defined in `module.yaml`

### Changed
- **Breaking**: Removed `registerAllModules()` function (now handled internally)
- **Breaking**: Removed `buildRoutesFromRegistry()` from app (now handled internally)
- **Breaking**: ModularApp no longer requires manual registry setup
- **Build Command** - No longer generates app files, only updates `pubspec.yaml`
- **Module.fromPath()** - Now parses menus and localizations from `module.yaml`

### Removed
- `app/modules.dart` generation (handled internally)
- `app/route_builder.dart` requirement (handled internally)
- `module_registration_discovery.dart` - Not used, replaced by internal provider loader
- `module_provider_interface.dart` - Not used (duplicate functionality)
- `module_config_loader.dart` - Not used (functionality in Module.fromPath)
- `build/generator.dart` - No longer generating app files
- `module_auto_register.dart` - Not needed with new architecture

## [0.2.0] - 2024-12-XX

### Added
- **Thin App Architecture** - Zero module imports in app, all complexity in package
- **ModularAppConfig** - Comprehensive configuration with customization hooks
- **Internal Provider Loader** - Dynamic provider loading without app imports
- **Internal Route Resolver** - Dynamic route resolution without app imports
- **Customization Hooks** - `onBeforeRegister`, `onAfterRegister`, `onRouteBuilt`, `onModuleLoaded`, `shouldLoadModule`, `onBeforeBoot`, `onAfterBoot`
- **Conditional Module Loading** - Support for loading modules based on custom logic
- **Self-Contained ModularApp** - Handles all discovery, registration, and route building internally

### Improved
- **Minimal main.dart** - Now just `runApp(ModularApp(title: 'App'))`
- **No Generated App Files** - Removed `app/modules.dart` and `app/route_builder.dart` generation
- **Better Architecture** - All complexity moved to package, app stays thin and clean
- **Easy Customization** - Full control via ModularAppConfig hooks

### Changed
- **Breaking**: Removed `registerAllModules()` function (now handled internally)
- **Breaking**: Removed `buildRoutesFromRegistry()` from app (now handled internally)
- **Breaking**: ModularApp no longer requires manual registry setup
- **Build Command** - No longer generates app files, only updates `pubspec.yaml`

### Removed
- `app/modules.dart` generation (handled internally)
- `app/route_builder.dart` requirement (handled internally)

## [0.1.2] - 2024-12-XX

### Added
- Auto-sync `pubspec.yaml` with discovered modules
- Support for `pubspec.yaml.base` to keep modules out of git
- Git hooks for automatic syncing after pull/merge
- `.gitattributes` with merge strategies

### Fixed
- Module discovery in `packages/` and `modules/` directories
- Provider registration from `module.yaml` files

## [0.1.1] - 2024-12-XX

### Added
- Initial release
- Module discovery and registration
- Provider auto-registration
- Route registration
- Localization support
- CLI commands for module management
