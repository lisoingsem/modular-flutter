# Modular Flutter

A powerful Flutter package for managing modular architecture. Organize your Flutter application into reusable, manageable modules with advanced filtering and execution capabilities.

**Inspired by [Laravel Modules](https://github.com/nwidart/laravel-modules)** - Bringing Laravel's modular architecture patterns to Flutter.

## Features

- **Auto-Discovery**: Automatically discovers modules from `packages/` or `modules/` directory
- **Auto-Sync**: Automatically updates `pubspec.yaml` with discovered modules (no manual editing!)
- **Module Management**: Enable/disable modules dynamically with JSON configuration
- **Service Providers**: Register services and dependencies per module
- **Route Registration**: Register routes from modules automatically
- **Code Generation**: Auto-generates `modules.dart` with provider registration
- **Git Submodules**: Support for managing modules as git submodules

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
- ✅ Generates `lib/app/modules.dart` with provider registration

### 4. Use in Your App

```dart
import 'package:flutter/material.dart';
import 'package:modular_flutter/modular_flutter.dart';
import 'app/modules.dart'; // Auto-generated!

void main() {
  final registry = ModuleRegistry(
    repository: ModuleRepository(localModulesPath: 'packages'),
  );

  registerAllModules(registry); // Auto-registers all providers
  registry.register();
  registry.boot();

  runApp(MyApp());
}
```

## Why pubspec.yaml?

**Flutter requires all dependencies to be declared in `pubspec.yaml`** - this is a Flutter/Dart package system requirement. There's no way around it.

However, **you never need to edit it manually!** The `build` command automatically:
- Scans `packages/` directory
- Reads each module's `pubspec.yaml`
- Auto-adds them to your main `pubspec.yaml`

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

## Module Structure

```
packages/
  auth/
    lib/
      providers/
        auth_service_provider.dart
      routes/
        auth_route.dart
    module.yaml
    pubspec.yaml
```

## CLI Commands

```bash
# Create module
dart run modular_flutter create <name> [--submodule]

# Auto-sync pubspec.yaml & generate modules.dart
dart run modular_flutter build

# Enable/disable modules
dart run modular_flutter enable <name>
dart run modular_flutter disable <name>

# List modules
dart run modular_flutter list
```

## Documentation

- [Git Submodules Guide](GIT_SUBMODULES.md)
- [Full Documentation](DOCS.md)
