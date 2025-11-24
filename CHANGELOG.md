# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2024-12-XX

### Added
- **ModularApp widget** - Simplified app wrapper that auto-discovers and registers everything
- **Auto-discovery** - Automatically discovers modules from `packages/` or `modules/` directories
- **Zero configuration** - No manual setup needed, just like Laravel Modules
- **Route builder** - `buildRoutesFromRegistry()` helper function
- **Auto path discovery** - Automatically detects modules path without configuration

### Improved
- **Simplified main.dart** - Minimal setup required, everything auto-discovered
- **Better documentation** - Clear examples showing Laravel Modules-like usage
- **Code generation** - Improved `modules.dart` generation with better error handling

### Changed
- **ModularApp API** - Now handles all registration and booting automatically
- **Module discovery** - More robust path detection (packages/ or modules/)

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
