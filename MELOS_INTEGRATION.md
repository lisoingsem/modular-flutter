# How Melos Works with modular_flutter

## The Complete Flow

### 1. Melos Discovers Packages Automatically

When you run `melos bootstrap`, Melos:

```yaml
# melos.yaml
packages:
  - "packages/**"  # Melos scans this directory
  - "."

command:
  bootstrap:
    usePubspecOverrides: true  # Links packages automatically
```

**What Melos does:**
- Scans `packages/` directory
- Finds all packages (auth, catalog, payway, etc.)
- Links them via `pubspec_overrides` (no need to edit pubspec.yaml!)
- Updates `.dart_tool/package_config.json` with all discovered packages

### 2. modular_flutter Reads package_config.json

When `ModularApp` starts, it:

```dart
// modular_flutter/lib/src/package_discovery.dart
static List<Module> _discoverFromPackages(String projectRoot, ...) {
  // Reads .dart_tool/package_config.json
  final packageConfig = jsonDecode(content);
  
  for (final package in packages) {
    final packageName = package['name'];  // e.g., "auth_module"
    final packageRoot = package['rootUri']; // e.g., "../packages/auth"
    
    // Check if package has module.yaml
    if (hasModuleYaml(packagePath)) {
      modules.add(Module.fromPath(packagePath));
    }
  }
}
```

**What modular_flutter does:**
- Reads `.dart_tool/package_config.json` (created by Melos)
- Finds all packages that have `module.yaml`
- Discovers modules automatically - **no imports needed!**

### 3. Modules Auto-Register Themselves

Each module has auto-registration code:

```dart
// packages/auth/lib/auth_module.dart
import 'package:modular_flutter/src/module_auto_register.dart';
import 'providers/auth_service_provider.dart';

void _registerAuthModule() {
  ModuleAutoRegister.registerFactory(
    'auth_module.providers.AuthServiceProvider',
    (module) => AuthServiceProvider(module),
  );
}

// Auto-register when library is loaded
final _ = _registerAuthModule();
```

**What happens:**
- When package is loaded, auto-registration code runs
- Module registers itself in `ModuleAutoRegister`
- No manual imports needed in main.dart!

### 4. ModularApp Discovers Everything

```dart
// Your main.dart - NO MODULE IMPORTS!
void main() {
  runApp(ModularApp(
    // ModularApp automatically:
    // 1. Reads package_config.json (from Melos)
    // 2. Discovers all modules
    // 3. Loads their auto-registration code
    // 4. Registers routes, menus, translations
  ));
}
```

## Complete Workflow

### Setup (One Time)

1. **Install Melos:**
   ```bash
   dart pub global activate melos
   ```

2. **Create melos.yaml:**
   ```yaml
   name: my_monorepo
   packages:
     - "packages/**"
     - "."
   
   command:
     bootstrap:
       usePubspecOverrides: true
   ```

3. **Bootstrap:**
   ```bash
   melos bootstrap
   ```

### Daily Workflow

1. **Add a new module:**
   ```bash
   dart run modular_flutter create NewModule
   ```

2. **Enable it in modules.yaml:**
   ```yaml
   new_module: true
   ```

3. **Bootstrap (if needed):**
   ```bash
   melos bootstrap
   ```

4. **Run app:**
   ```bash
   flutter run
   ```

**That's it!** No imports, no manual configuration - everything is automatic!

## How It Achieves Your Goal

### ✅ No Module Imports in Core App

- Melos discovers packages → updates `package_config.json`
- modular_flutter reads `package_config.json` → discovers modules
- Modules auto-register when packages are loaded
- **Zero imports needed in main.dart!**

### ✅ Melos Handles Package Linking

- `usePubspecOverrides: true` links all packages
- No need to edit `pubspec.yaml` manually
- Melos handles all dependency management

### ✅ modular_flutter Handles Runtime

- Module discovery from `package_config.json`
- Route registration
- Menu registration
- Translation loading
- Service provider registration

## Example: Adding a New Module

```bash
# 1. Create module
dart run modular_flutter create Payment

# 2. Enable in modules.yaml
echo "payment: true" >> modules.yaml

# 3. Bootstrap (Melos discovers it)
melos bootstrap

# 4. Run app (modular_flutter discovers it)
flutter run
```

**No code changes in main.dart needed!** The module is automatically:
- Discovered by Melos
- Linked via pubspec_overrides
- Discovered by modular_flutter
- Auto-registered at runtime

## Key Files

- **melos.yaml**: Tells Melos where to find packages
- **package_config.json**: Created by Melos, lists all packages
- **modules.yaml**: Tells modular_flutter which modules are enabled
- **module.yaml**: In each module, defines module metadata

## Benefits

1. **Zero Configuration**: Just add module, enable it, run app
2. **No Imports**: Core app never imports modules
3. **Auto-Discovery**: Melos + modular_flutter discover everything
4. **Clean Separation**: Core app doesn't know about modules
5. **Scalable**: Add 100 modules, no code changes needed

