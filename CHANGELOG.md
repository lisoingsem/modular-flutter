# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.2] - 2024-11-25

### Added
- Auto-discovery and code generation for module providers
- `build` command to generate `modules.dart` with auto-registration
- Automatic provider registration from `module.yaml` files
- Auto-regeneration of `modules.dart` after create/enable/disable commands

### Changed
- Renamed `modules_statuses.json` to `modules.json` (simpler naming)
- Module discovery now follows Laravel Modules pattern (zero-configuration)
- Simplified main app usage - no manual provider registration needed

### Fixed
- Module discovery now properly handles both `packages/` and `modules/` directories

## [0.1.1] - 2024-12-19

### Changed
- Updated copyright to Krup Yang
- Updated author information

## [0.1.0] - 2024-11-25

### Added
- Initial release
- Module discovery and registration
- Module enable/disable functionality
- Service provider pattern
- Route registration
- Asset and localization loading
- CLI tool for module generation
- Module repository and registry
- Priority-based module loading
- Module dependency validation
- Configuration system (Laravel-style)
- Auto-discovery from pub.dev packages
- Localization support (ARB, JSON, YAML)
- Module publishing and customization

