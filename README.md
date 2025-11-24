# Flutter Modules

A powerful Flutter package for managing modular architecture. Organize your Flutter application into reusable, manageable modules with advanced filtering and execution capabilities.

**Inspired by [Laravel Modules](https://github.com/nwidart/laravel-modules)** - Bringing Laravel's modular architecture patterns to Flutter.

## Features

- **Module Discovery**: Automatically discover and load modules from the `modules/` directory
- **Module Management**: Enable/disable modules dynamically with JSON configuration
- **Service Providers**: Register services and dependencies per module
- **Route Registration**: Register routes from modules automatically
- **Asset Loading**: Load assets from modules
- **Localization Support**: Load localizations from modules
- **Priority-based Loading**: Control module loading order
- **Dependency Management**: Define module dependencies
- **Advanced Filtering**: Filter modules by name pattern, status, dependencies
- **Exec Command**: Execute commands across multiple modules with concurrency
- **Multiple Output Formats**: Table, JSON, and simple list formats
- **Configuration System**: Laravel-style config files for modules
- **Auto-Discovery**: Automatically discover modules from pub.dev packages
- **Localization Support**: Module-based i18n with ARB files (only enabled modules)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_modules: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Initialize Module Registry

```dart
import 'package:flutter_modules/flutter_modules.dart';

void main() {
  final registry = ModuleRegistry();
  
  // Register provider factories
  registry.registerProviderFactory(
    'modules.auth.providers.AuthServiceProvider',
    (module) => AuthServiceProvider(module),
  );
  
  // Register and boot modules
  registry.register();
  registry.boot();
  
  runApp(MyApp());
}
```

### 2. Create a Module

```bash
dart run flutter_modules create Auth
```

### 3. Generate Components

```bash
# Generate a widget
dart run flutter_modules make:widget Login --module=Auth

# Generate a service
dart run flutter_modules make:service AuthService --module=Auth

# Generate a route
dart run flutter_modules make:route Login --module=Auth
```

### 4. Manage Modules

```bash
# Enable a module
dart run flutter_modules enable Auth

# Disable a module
dart run flutter_modules disable Payment

# List all modules
dart run flutter_modules list
```

## Advanced Features

### Filter Modules

```bash
# List only enabled modules
dart run flutter_modules list --enabled

# Filter by name pattern
dart run flutter_modules list --scope=auth*

# JSON output for scripting
dart run flutter_modules list --format=json
```

### Execute Commands Across Modules

```bash
# Run tests in all modules
dart run flutter_modules exec -- "flutter test"

# With filtering
dart run flutter_modules exec --scope=auth* -- "flutter test"

# With concurrency
dart run flutter_modules exec --concurrency=5 -- "flutter test"

# Fail fast on errors
dart run flutter_modules exec --fail-fast -- "flutter test"
```

### Module Status Configuration

Module status is stored in `modules_statuses.json`:

```json
{
  "auth": true,
  "payment": false,
  "shipping": true
}
```

You can edit this file manually or use CLI commands - both work!

## Module Structure

Each module follows this structure:

```
modules/Auth/
├── module.yaml              # Module metadata
├── lib/
│   ├── auth_module.dart     # Module exports
│   ├── widgets/             # UI components
│   ├── services/            # Business logic
│   ├── routes/              # Route definitions
│   ├── providers/           # State management
│   ├── models/              # Data models
│   └── config/              # Configuration
├── assets/                  # Module assets
├── lang/                    # Localizations (en.arb, es.json, etc.)
└── test/                    # Module tests
```

## CLI Commands

- `create <name>` - Create a new module
- `make:widget <name> --module=<module>` - Generate a widget
- `make:service <name> --module=<module>` - Generate a service
- `make:route <name> --module=<module>` - Generate a route
- `make:provider <name> --module=<module>` - Generate a state provider
- `make:config <name> --module=<module>` - Generate a config file
- `enable <name>` - Enable a module
- `disable <name>` - Disable a module
- `list [--format=table|json|simple]` - List modules
- `exec -- <command>` - Execute command across modules
- `publish <name> [--tag=assets|config]` - Publish module assets/config
- `install <package> [--version|--path|--git]` - Install module from pub.dev/git/path

## Configuration System

Similar to Laravel's config system:

```dart
final module = repository.get('Auth');

// Get config value (like config('auth.key') in Laravel)
final apiUrl = module.config.get<String>('config.api_url');
final timeout = module.config.get<int>('config.timeout', 30);
```

See [CONFIG_GUIDE.md](CONFIG_GUIDE.md) for detailed configuration guide.

## Publishing & Customization

Modules can be published to pub.dev and easily customized:

```bash
# Publish module config for customization
dart run flutter_modules publish Auth --tag=config

# Install module from pub.dev
dart run flutter_modules install auth_module
```

See [PUBLISHING_MODULES.md](PUBLISHING_MODULES.md) for detailed guide.

## Documentation

- [DOCS.md](DOCS.md) - Complete documentation (CLI, config, localization, publishing)

## Credits

This package is inspired by and adapted from [nwidart/laravel-modules](https://github.com/nwidart/laravel-modules), bringing Laravel's powerful modular architecture patterns to Flutter.

## License

MIT
