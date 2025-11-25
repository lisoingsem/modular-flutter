# Modular Flutter

A powerful Flutter package for managing modular architecture. Organize your Flutter application into reusable, manageable modules with advanced filtering and execution capabilities.

**Inspired by [Laravel Modules](https://github.com/nwidart/laravel-modules)** - Bringing Laravel's modular architecture patterns to Flutter.

## Features

- **Zero Configuration**: Just `runApp(ModularApp())` - everything is automatic!
- **Auto-Discovery**: Automatically discovers modules from `packages/` or `modules/` directory
- **Auto-Sync**: Automatically updates `pubspec.yaml` with discovered modules (no manual editing!)
- **Menu System**: Auto-register menus from `module.yaml` (inspired by Laravel Menus)
- **Translation Support**: Auto-load translations from module `lang/` or `l10n/` directories
- **Service Providers**: Register services and dependencies per module
- **Route Registration**: Register routes from modules automatically
- **Optional Dependency**: Modules can work without `modular_flutter` as a direct dependency
- **Module Management**: Enable/disable modules dynamically with JSON configuration
- **Melos Integration**: Works seamlessly with Melos for package discovery and linking

## Quick Start

### 1. Install

```bash
flutter pub add modular_flutter
```

### 2. Create Modules

```bash
dart run modular_flutter create Auth
dart run modular_flutter create Catalog
```

### 3. Auto-Sync & Build

```bash
dart run modular_flutter build
```

This command:
- ✅ Auto-discovers all modules in `packages/`
- ✅ Auto-updates `pubspec.yaml` with module dependencies

### 4. Use in Your App

**That's it!** Just use `ModularApp` - everything is automatic:

```dart
import 'package:flutter/material.dart';
import 'package:modular_flutter/modular_flutter.dart';

void main() {
  // ModularApp handles everything automatically:
  // - Auto-discovers modules
  // - Auto-registers providers
  // - Auto-builds routes
  // - Auto-loads menus and translations
  runApp(
    ModularApp(
      title: 'My App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    ),
  );
}
```

**No manual setup needed!** All modules are discovered, registered, and booted automatically.

## Melos Integration (Recommended for Monorepos)

If you're using **Melos** for package management (like composer merge-plugin in Laravel), `modular_flutter` automatically detects it and works together:

- **Melos**: Handles package discovery and linking (via `usePubspecOverrides: true`)
- **modular_flutter**: Handles runtime module registration, routes, menus

### Setup with Melos

1. Install Melos:
```bash
dart pub global activate melos
```

2. Create `melos.yaml`:
```yaml
name: my_monorepo
packages:
  - "packages/**"
  - "."

command:
  bootstrap:
    runPubGetInParallel: true
    usePubspecOverrides: true
```

3. Run:
```bash
melos bootstrap
dart run modular_flutter build
```

When Melos is detected, `modular_flutter build` will:
- ✅ Skip `pubspec.yaml` syncing (Melos handles it)
- ✅ Still generate `modules.dart` for auto-registration
- ✅ Still respect `modules.yaml` enable/disable flags

## Why pubspec.yaml?

**Flutter requires all dependencies to be declared in `pubspec.yaml`** - this is a Flutter/Dart package system requirement. There's no way around it.

However, **you never need to edit it manually!** The `build` command automatically:
- Scans `packages/` directory
- Reads each module's `pubspec.yaml`
- Auto-adds them to your main `pubspec.yaml`

**Or use Melos** - it handles package linking automatically!

Just run `dart run modular_flutter build` whenever you add a new module.

## Make It Automatic

### Option 1: Pre-build Hook (Recommended)

Create a script that runs before `flutter pub get`:

```bash
#!/bin/bash
# scripts/pre_build.sh
dart run modular_flutter build
flutter pub get
```

Then use:
```bash
./scripts/pre_build.sh
flutter run
```

### Option 2: Git Hook

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
dart run modular_flutter build
git add pubspec.yaml lib/app/modules.dart
```

### Option 3: IDE Task

Configure your IDE to run `dart run modular_flutter build` before running the app.

## Architecture

### Core App vs Modules

**core_app** (the only real app) contains:
- Navigation
- Theme
- Dependency injection
- Main screens
- App config

**packages/module_xxx** contain:
- Features
- Business logic
- Widgets
- Domain/entities
- Services
- API logic

### Benefits

1. **One app → simple deployment**
   - No need for multiple apps unless you actually need different apps
   - Single deployment target

2. **Modules reusable**
   - Like Laravel modules → portable, easy to update
   - Can be shared across projects
   - Can be versioned independently

3. **Codebase clean & scalable**
   - Modules can be:
     - Shared
     - Versioned
     - Moved to private GitHub
     - Imported in multiple apps in future (if needed)

4. **Melos auto-discovers all modules**
   - Only core_app runs
   - All modules automatically discovered and linked

## Module Structure

```
packages/
  auth/
    lib/
      providers/
        auth_service_provider.dart
      screens/
        login_screen.dart
    lang/
      en.json
    es.yaml
    module.yaml
    pubspec.yaml
```

### module.yaml

```yaml
name: Auth
alias: auth
version: 0.1.0
enabled: true
providers:
  - auth_module.providers.AuthServiceProvider
routes:
  - path: /auth/login
    widget: auth_module.screens.LoginScreen
menus:
  primary:
    - title: Authentication
      url: /auth
      icon: lock
      order: 1
localizations:
  - lang/en.json
  - lang/es.yaml
```

## Advanced Usage

### Custom Configuration

```dart
runApp(
  ModularApp(
    title: 'My App',
    config: ModularAppConfig(
      modulesPath: 'packages', // Custom modules path
      shouldLoadModule: (module) => module.enabled, // Custom filter
      onBeforeRegister: (registry) {
        // Custom logic before registration
      },
      onRouteBuilt: (routes) {
        // Customize routes before use
        return routes;
      },
    ),
  ),
);
```

### Accessing Menus

```dart
// In any widget
final primaryMenus = ModularApp.menus?.getMenus('primary') ?? [];
```

### Accessing Translations

```dart
// In any widget
final welcomeText = ModularApp.localizations?.translate('auth', 'welcome');
```

### Standalone Modules (No Dependency)

Modules can work without `modular_flutter` as a direct dependency:

```dart
// In your module's service provider
class AuthServiceProvider implements ModuleProviderInterface {
  final Module module;
  
  AuthServiceProvider(this.module);
  
  @override
  void register() {
    // Register services
  }
  
  @override
  void boot() {
    // Boot services
  }
}
```

Just define everything in `module.yaml` - `modular_flutter` will discover and load it automatically!

## CLI Commands

```bash
# Create module
dart run modular_flutter create <name> [--submodule]

# Auto-sync pubspec.yaml with discovered modules
dart run modular_flutter build

# Enable/disable modules
dart run modular_flutter enable <name>
dart run modular_flutter disable <name>

# List modules
dart run modular_flutter list
```

## Documentation

- [Full Documentation](DOCS.md)
