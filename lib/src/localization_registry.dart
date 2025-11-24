import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'module_repository.dart';
import 'localization_loader.dart';
import 'module.dart';

/// Registry for managing module localizations
/// Auto-registers localizations from enabled modules
class LocalizationRegistry {
  final ModuleRepository repository;
  final Map<String, Map<String, String>> _localizations = {};
  bool _registered = false;

  /// Internal access to localizations (for ModuleProvider)
  Map<String, Map<String, String>> get localizations => _localizations;

  LocalizationRegistry({
    ModuleRepository? repository,
  }) : repository = repository ?? ModuleRepository();

  /// Register localizations from all enabled modules
  void register() {
    if (_registered) {
      return;
    }

    final enabledModules = repository.allEnabled();

    for (final module in enabledModules) {
      final moduleLocalizations =
          LocalizationLoader.getModuleLocalizations(module);
      if (moduleLocalizations.isNotEmpty) {
        _registerModuleLocalizations(module, moduleLocalizations);
      }
    }

    _registered = true;
  }

  /// Register localizations for a specific module
  /// Supports: .arb (Flutter default), .json, .yaml, .yml
  void _registerModuleLocalizations(
    Module module,
    List<String> localizationFiles,
  ) {
    final moduleNamespace = LocalizationLoader.getModuleNamespace(module);
    _localizations[moduleNamespace] = {};

    // Load localization files and parse them
    for (final file in localizationFiles) {
      final filePath = path.join(module.l10nPath, file);
      final locFile = File(filePath);
      if (locFile.existsSync()) {
        try {
          final content = locFile.readAsStringSync();
          final ext = path.extension(filePath).toLowerCase();

          Map<String, String> translations;
          if (ext == '.arb' || ext == '.json') {
            translations = _parseJsonFile(content, ext == '.arb');
          } else if (ext == '.yaml' || ext == '.yml') {
            translations = _parseYamlFile(content);
          } else {
            continue;
          }

          _localizations[moduleNamespace]!.addAll(translations);
        } catch (e) {
          print('Warning: Failed to load localization file $filePath: $e');
        }
      }
    }
  }

  /// Parse ARB/JSON file content
  Map<String, String> _parseJsonFile(String content, bool isArb) {
    final translations = <String, String>{};
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      for (final entry in json.entries) {
        // ARB files use @ prefix for metadata, skip those
        // JSON files can have any structure
        if (isArb && entry.key.startsWith('@')) {
          continue;
        }
        if (entry.value is String) {
          translations[entry.key] = entry.value as String;
        } else if (entry.value is Map) {
          // Handle nested JSON structures
          _flattenMap(entry.value as Map, entry.key, translations);
        }
      }
    } catch (e) {
      // Not valid JSON, skip
    }
    return translations;
  }

  /// Parse YAML file content
  Map<String, String> _parseYamlFile(String content) {
    final translations = <String, String>{};
    try {
      final yaml = loadYaml(content) as Map;
      for (final entry in yaml.entries) {
        if (entry.value is String) {
          translations[entry.key.toString()] = entry.value.toString();
        } else if (entry.value is Map) {
          // Handle nested YAML structures
          _flattenMap(entry.value as Map, entry.key.toString(), translations);
        }
      }
    } catch (e) {
      // Not valid YAML, skip
    }
    return translations;
  }

  /// Flatten nested map structures (e.g., {"auth": {"login": "Login"}} -> {"auth.login": "Login"})
  void _flattenMap(Map map, String prefix, Map<String, String> translations) {
    for (final entry in map.entries) {
      final key = '$prefix.${entry.key}';
      if (entry.value is String) {
        translations[key] = entry.value.toString();
      } else if (entry.value is Map) {
        _flattenMap(entry.value as Map, key, translations);
      }
    }
  }

  /// Get translation for a key with module namespace
  /// Example: translate('auth', 'login.title') -> 'Login'
  String? translate(String moduleNamespace, String key) {
    if (!_registered) {
      register();
    }

    final moduleTranslations = _localizations[moduleNamespace];
    if (moduleTranslations == null) {
      return null;
    }

    return moduleTranslations[key];
  }

  /// Get all translations for a module namespace
  Map<String, String>? getModuleTranslations(String moduleNamespace) {
    if (!_registered) {
      register();
    }

    return _localizations[moduleNamespace];
  }

  /// Get all registered localizations
  Map<String, Map<String, String>> getAllLocalizations() {
    if (!_registered) {
      register();
    }

    return Map.unmodifiable(_localizations);
  }

  /// Check if localizations are registered
  bool get isRegistered => _registered;

  /// Clear and re-register localizations
  void refresh() {
    _localizations.clear();
    _registered = false;
    register();
  }
}
