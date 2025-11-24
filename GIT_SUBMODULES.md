# Git Submodules Setup for Flutter Modules

Similar to Laravel Modules, you can manage Flutter modules as git submodules with the `flutter-` prefix.

## Setup

### 1. Create Module Repositories

First, create separate git repositories for each module:

```bash
# Example: Create flutter-auth repository
cd ..
git clone <your-flutter-repo> flutter-auth
cd flutter-auth
# Remove all files, copy module files
# Initialize as new repo
git init
git add .
git commit -m "Initial commit"
git remote add origin git@github.com:lisoingsem/flutter-auth.git
git push -u origin main
```

### 2. Add as Submodules

In your main Flutter project:

```bash
cd /path/to/flutter

# Add modules as submodules
git submodule add -b main ../flutter-auth.git packages/auth
git submodule add -b main ../flutter-profile.git packages/profile
git submodule add -b main ../flutter-payment.git packages/payment

# This creates .gitmodules automatically
```

### 3. .gitmodules Format

Your `.gitmodules` will look like:

```ini
[submodule "packages/auth"]
    path = packages/auth
    url = ../flutter-auth.git
    branch = main

[submodule "packages/profile"]
    path = packages/profile
    url = ../flutter-profile.git
    branch = main

[submodule "packages/payment"]
    path = packages/payment
    url = ../flutter-payment.git
    branch = main
```

## CLI Support

The `modular_flutter create` command can optionally initialize git submodules:

```bash
# Create module and initialize as git submodule
dart run modular_flutter create Auth --submodule

# This will:
# 1. Create the module structure
# 2. Initialize git in the module
# 3. Add it as a submodule to your main project
```

## Common Commands

```bash
# Initialize all submodules (when cloning main repo)
git submodule update --init --recursive

# Update all submodules to latest
git submodule update --remote

# Update specific submodule
cd packages/auth
git pull origin main
cd ../..

# Commit submodule updates
git add packages/auth
git commit -m "Update auth module"
```

## Workflow

1. **Create new module:**
   ```bash
   dart run modular_flutter create NewModule --submodule
   ```

2. **Work on module:**
   ```bash
   cd packages/new_module
   # Make changes
   git add .
   git commit -m "Update module"
   git push
   ```

3. **Update in main project:**
   ```bash
   cd /path/to/flutter
   git submodule update --remote packages/new_module
   git add packages/new_module
   git commit -m "Update new_module submodule"
   ```

