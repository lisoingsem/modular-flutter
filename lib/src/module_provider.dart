import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'module.dart';
import 'localization_registry.dart';
import 'route_registry.dart';

/// Base class for module service providers
/// Handles module initialization, route registration, and service bootstrapping
abstract class ModuleProvider {
  /// The module this provider belongs to
  final Module module;

  /// Localization registry (set during registration)
  LocalizationRegistry? _localizationRegistry;

  ModuleProvider(this.module);

  /// Set localization registry (called by ModuleRegistry)
  void setLocalizationRegistry(LocalizationRegistry registry) {
    _localizationRegistry = registry;
  }

  /// Register services (called during module registration)
  void register() {}

  /// Register routes for this module
  /// Override this method to register routes programmatically
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void registerRoutes(RouteRegistry registry) {
  ///   registry.register('/auth', (context) => const AuthRoute());
  ///   registry.register('/auth/login', (context) => const LoginScreen());
  /// }
  /// ```
  void registerRoutes(RouteRegistry registry) {}

  /// Boot services (called after all modules are registered)
  void boot() {}

  /// Called when module is enabled
  void onEnabled() {}

  /// Called when module is disabled
  void onDisabled() {}

  /// Load localizations from a directory path
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void boot() {
  ///   loadLocalizationsFrom('lib/lang');
  /// }
  /// ```
  void loadLocalizationsFrom(String relativePath) {
    if (_localizationRegistry == null) {
      print(
          'Warning: LocalizationRegistry not set. Localizations will not be registered.');
      return;
    }

    final langPath = path.join(module.modulePath, relativePath);
    final langDir = Directory(langPath);

    if (!langDir.existsSync()) {
      return;
    }

    // Load all localization files from the directory
    _loadLocalizationsFromDirectory(langDir);
  }

  /// Register localizations directly (programmatically)
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void boot() {
  ///   registerLocalizations({
  ///     'en': {
  ///       'custom.key': 'Custom translation',
  ///       'another.key': 'Another translation',
  ///     },
  ///     'es': {
  ///       'custom.key': 'Traducción personalizada',
  ///     },
  ///   });
  /// }
  /// ```
  void registerLocalizations(Map<String, Map<String, String>> translations) {
    if (_localizationRegistry == null) {
      print(
          'Warning: LocalizationRegistry not set. Localizations will not be registered.');
      return;
    }

    final moduleNamespace = module.lowerName;
    final existing =
        _localizationRegistry!.getModuleTranslations(moduleNamespace) ?? {};

    // Merge translations
    for (final localeEntry in translations.entries) {
      final localeTranslations = localeEntry.value;

      // For now, we merge all locales into one namespace
      // In a full implementation, you might want locale-specific namespaces
      existing.addAll(localeTranslations);
    }

    // Register merged translations
    _localizationRegistry!.localizations[moduleNamespace] = existing;
  }

  /// Load localizations from directory
  void _loadLocalizationsFromDirectory(Directory dir) {
    if (_localizationRegistry == null) return;

    try {
      for (final entity in dir.listSync()) {
        if (entity is File) {
          final ext = path.extension(entity.path).toLowerCase();
          if (ext == '.arb' ||
              ext == '.json' ||
              ext == '.yaml' ||
              ext == '.yml') {
            _loadLocalizationFile(entity);
          }
        } else if (entity is Directory) {
          _loadLocalizationsFromDirectory(entity);
        }
      }
    } catch (e) {
      print('Warning: Failed to load localizations from ${dir.path}: $e');
    }
  }

  /// Load a single localization file
  void _loadLocalizationFile(File file) {
    if (_localizationRegistry == null) return;

    try {
      final content = file.readAsStringSync();
      final ext = path.extension(file.path).toLowerCase();

      Map<String, String> translations;
      if (ext == '.arb' || ext == '.json') {
        translations = _parseJsonFile(content, ext == '.arb');
      } else if (ext == '.yaml' || ext == '.yml') {
        translations = _parseYamlFile(content);
      } else {
        return;
      }

      final moduleNamespace = module.lowerName;
      final existing =
          _localizationRegistry!.localizations[moduleNamespace] ?? {};
      existing.addAll(translations);
      _localizationRegistry!.localizations[moduleNamespace] = existing;
    } catch (e) {
      print('Warning: Failed to load localization file ${file.path}: $e');
    }
  }

  /// Parse JSON/ARB file
  Map<String, String> _parseJsonFile(String content, bool isArb) {
    final translations = <String, String>{};
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      for (final entry in json.entries) {
        if (isArb && entry.key.startsWith('@')) {
          continue;
        }
        if (entry.value is String) {
          translations[entry.key] = entry.value as String;
        }
      }
    } catch (e) {
      // Skip invalid JSON
    }
    return translations;
  }

  /// Parse YAML file
  Map<String, String> _parseYamlFile(String content) {
    final translations = <String, String>{};
    try {
      final yaml = loadYaml(content) as Map;
      for (final entry in yaml.entries) {
        if (entry.value is String) {
          translations[entry.key.toString()] = entry.value.toString();
        }
      }
    } catch (e) {
      // Skip invalid YAML
    }
    return translations;
  }
}
