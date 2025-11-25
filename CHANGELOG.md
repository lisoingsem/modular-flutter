# Changelog

All notable changes to this project will be documented in this file.

## [0.3.0] - 2025-01-XX

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
