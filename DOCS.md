# Flutter Modular Documentation

Complete guide for using Flutter Modular.

> **Note:** This package is inspired by [Laravel Modules](https://github.com/nwidart/laravel-modules). Many concepts and patterns are adapted from Laravel's modular architecture system.

## Table of Contents

1. [Quick Start](#quick-start)
2. [CLI Commands](#cli-commands)
3. [Configuration](#configuration)
4. [Localization](#localization)
5. [Publishing Modules](#publishing-modules)

## Quick Start

### Installation

```yaml
dependencies:
  flutter_modular: ^0.1.0
```

### Basic Usage

```dart
import 'package:flutter_modular/flutter_modular.dart';

void main() {
  final registry = ModuleRegistry();
  
  // Register provider factories
  registry.registerProviderFactory(
    'modules.auth.providers.AuthServiceProvider',
    (module) => AuthServiceProvider(module),
  );
  
  registry.register();
  registry.boot();
  
  runApp(MyApp());
}
```

### Create Module

```bash
dart run flutter_modular create Auth
```

## CLI Commands

### Module Management

```bash
# Create module
dart run flutter_modular create Auth

# Enable/disable
dart run flutter_modular enable Auth
dart run flutter_modular disable Payment

# List modules
dart run flutter_modular list
dart run flutter_modular list --enabled
dart run flutter_modular list --format=json
```

### Code Generation

```bash
# Generate components
dart run flutter_modular make:widget Login --module=Auth
dart run flutter_modular make:service AuthService --module=Auth
dart run flutter_modular make:route Login --module=Auth
dart run flutter_modular make:provider AuthProvider --module=Auth
dart run flutter_modular make:config api --module=Auth
```

### Advanced

```bash
# Execute commands across modules
dart run flutter_modular exec -- "flutter test"
dart run flutter_modular exec --scope=auth* --concurrency=5 -- "flutter test"

# Publish module assets/config
dart run flutter_modular publish Auth --tag=config

# Install from pub.dev/git/path
dart run flutter_modular install auth_module
dart run flutter_modular install auth_module --git=https://github.com/user/repo.git
```

## Configuration

### Using Config

```dart
final module = repository.get('Auth');

// Get config value (like Laravel's config('auth.key'))
final apiUrl = module.config.get<String>('config.api_url');
final timeout = module.config.get<int>('config.timeout', 30);
```

### Config Files

Modules can have config files in `lib/config/`:

```yaml
# modules/Auth/lib/config/config.yaml
api_url: https://api.example.com
timeout: 30
features:
  login: true
  register: true
```

### Customization

Publish config to customize:

```bash
dart run flutter_modular publish Auth --tag=config
# Edit config/modules/auth/config.yaml
```

## Localization

### Supported Formats

- **ARB** (`.arb`) - Flutter's default format ✅ Recommended
- **JSON** (`.json`) - Simple format
- **YAML** (`.yaml`/`.yml`) - Clean syntax

### File Structure

```
modules/Auth/lang/
├── en.arb          # English (ARB format - recommended)
├── es.json         # Spanish (JSON format)
└── fr.yaml         # French (YAML format)
```

**File naming:** Use just the locale name (e.g., `en.arb`, `es.json`, `fr.yaml`)

**Directory:** Use `lang/` folder (also supports `l10n/` for compatibility)

### ARB File Example

```json
{
  "@@locale": "en",
  "login": "Login",
  "welcome": "Welcome, {name}!",
  "@welcome": {
    "placeholders": {
      "name": {"type": "String"}
    }
  }
}
```

### Usage

```dart
final localizationRegistry = LocalizationRegistry(repository: repository);
final loginText = localizationRegistry.translate('auth', 'login');
```

### Service Provider Registration

```dart
class AuthServiceProvider extends ModuleProvider {
  @override
  void boot() {
    // Load from directory
    loadLocalizationsFrom('lib/lang');
    
    // Or register programmatically
    registerLocalizations({
      'en': {'login': 'Login', 'logout': 'Logout'},
    });
  }
}
```

## Publishing Modules

### Create Publishable Module

```bash
dart run flutter_modular create Auth
# Module includes pubspec.yaml automatically
```

### Publish to pub.dev

```bash
cd modules/Auth
flutter pub publish
```

### Auto-Discovery

Modules from pub.dev are automatically discovered:

```bash
# Install module
dart run flutter_modular install auth_module

# Or add to pubspec.yaml
dependencies:
  auth_module: ^1.0.0

# Auto-discovered when you run:
final repository = ModuleRepository();
final modules = repository.all(); // auth_module included!
```

### Customize Published Modules

```bash
# Publish config for customization
dart run flutter_modular publish auth_module --tag=config

# Edit config/modules/auth_module/config.yaml
# Your app uses the customized config!
```

## Module Structure

```
modules/Auth/
├── module.yaml              # Module metadata
├── pubspec.yaml             # Package definition
├── lib/
│   ├── auth_module.dart     # Main export
│   ├── widgets/             # UI components
│   ├── services/            # Business logic
│   ├── routes/              # Route definitions
│   ├── providers/           # State management
│   ├── models/              # Data models
│   └── config/              # Configuration
├── assets/                  # Module assets
├── lang/                    # Localizations
└── test/                    # Module tests
```

## Module Status

Module status stored in `modules_statuses.json`:

```json
{
  "auth": true,
  "payment": false
}
```

Edit manually or use CLI commands - both work!

