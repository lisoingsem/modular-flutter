import 'dart:io';
import 'package:path/path.dart' as path;
import 'module.dart';
import 'module_registry.dart';

/// Auto-discovers and calls module registration functions
/// This allows modules to register themselves without manual registration in core app
class ModuleRegistrationDiscovery {
  /// Auto-register all enabled modules
  /// Uses convention: each module exports a registerModule(ModuleRegistry) function
  static void autoRegisterModules(
      ModuleRegistry registry, List<Module> modules) {
    for (final module in modules) {
      if (!module.enabled) {
        continue; // Skip disabled modules
      }

      try {
        _registerModule(registry, module);
      } catch (e) {
        print('Warning: Failed to auto-register module "${module.name}": $e');
      }
    }
  }

  /// Register a single module using its registration function
  static void _registerModule(ModuleRegistry registry, Module module) {
    // Try to find and call the registration function
    // Convention: module exports registerModule(ModuleRegistry) function

    // Check if module has a registration file
    final registrationFile = File(
      path.join(module.modulePath, 'lib', '${module.alias}_registration.dart'),
    );

    if (registrationFile.existsSync()) {
      // The registration function should be exported via module.dart
      // We'll use a convention-based approach
      _callRegistrationFunction(registry, module);
    } else {
      // Try default registration file
      final defaultRegistration = File(
        path.join(module.modulePath, 'lib', 'registration.dart'),
      );
      if (defaultRegistration.existsSync()) {
        _callRegistrationFunction(registry, module);
      }
    }
  }

  /// Call the registration function for a module
  /// Uses convention: function name is register{ModuleName}Module
  static void _callRegistrationFunction(
      ModuleRegistry registry, Module module) {
    // In Dart, we can't dynamically call functions without reflection
    // So we'll use a different approach: modules register themselves via a registry

    // This will be handled by having modules call a global registry
    // Or we can use code generation to create the registration calls

    // For now, we'll rely on modules to export their registration via module.dart
    // and the core app will import and call them
    // But we can make this automatic by using a registration callback system
  }
}
