# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.1.2] - 2025-11-25

### Added
- Git submodules support via `--submodule` flag in `create` command
- `GIT_SUBMODULES.md` documentation for managing modules as git submodules
- Helper script generation for connecting modules as submodules
- Auto-initialization of git repositories in modules when using `--submodule` flag
- Code generation for `modules.dart` with auto-registration
- `build` command to generate provider registration code
- Auto-regeneration of `modules.dart` after module create/enable/disable

### Changed
- Updated CLI help text to include `--submodule` option
- Improved module creation workflow with git submodule support

## [0.1.1] - 2025-11-24

### Changed
- Renamed `modules_statuses.json` to `modules.json` for cleaner naming
- Updated documentation

## [0.1.0] - 2025-11-24

### Added
- Initial release
- Module discovery and management
- CLI commands for module operations
- Service provider pattern
- Route registration
- Configuration system
- Localization support
