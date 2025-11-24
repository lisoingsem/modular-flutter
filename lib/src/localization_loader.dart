import 'dart:io';
import 'package:path/path.dart' as path;
import 'module.dart';
import 'module_repository.dart';

/// Loader for module localizations
/// Similar to Laravel's translation namespace system
class LocalizationLoader {
  /// Get all localization files from enabled modules
  static Map<String, List<String>> getAllModuleLocalizations(
    ModuleRepository repository,
  ) {
    final localizations = <String, List<String>>{};
    final enabledModules = repository.allEnabled();

    for (final module in enabledModules) {
      final moduleLocalizations = getModuleLocalizations(module);
      if (moduleLocalizations.isNotEmpty) {
        localizations[module.lowerName] = moduleLocalizations;
      }
    }

    return localizations;
  }

  /// Get localization files from a module
  static List<String> getModuleLocalizations(Module module) {
    final l10nDir = Directory(module.l10nPath);
    if (!l10nDir.existsSync()) {
      return [];
    }

    final localizations = <String>[];
    _collectLocalizations(l10nDir, localizations, module.l10nPath);
    return localizations;
  }

  /// Recursively collect all localization files
  /// Supports: .arb (Flutter default), .json, .yaml, .yml
  static void _collectLocalizations(
    Directory dir,
    List<String> localizations,
    String basePath,
  ) {
    try {
      for (final entity in dir.listSync()) {
        if (entity is File) {
          // Support multiple formats: ARB (Flutter default), JSON, YAML
          final ext = path.extension(entity.path).toLowerCase();
          if (ext == '.arb' ||
              ext == '.json' ||
              ext == '.yaml' ||
              ext == '.yml') {
            final relativePath = path.relative(entity.path, from: basePath);
            localizations.add(relativePath);
          }
        } else if (entity is Directory) {
          _collectLocalizations(entity, localizations, basePath);
        }
      }
    } catch (e) {
      // Skip directories that can't be read
    }
  }

  /// Get localization file path for a specific locale
  /// Supports: .arb (Flutter default), .json, .yaml, .yml
  /// File naming: Simple locale name (e.g., en.arb, es.json) is preferred
  static String? getLocalizationPath(Module module, String locale) {
    final extensions = ['.arb', '.json', '.yaml', '.yml'];

    // Try simple locale name first (e.g., en.arb, es.json) - preferred
    for (final ext in extensions) {
      final file = File(path.join(module.l10nPath, '$locale$ext'));
      if (file.existsSync()) {
        return file.path;
      }
    }

    // Fallback to common patterns
    final baseNames = [
      'app_$locale',
      '${module.lowerName}_$locale',
      'messages_$locale',
    ];

    for (final baseName in baseNames) {
      for (final ext in extensions) {
        final file = File(path.join(module.l10nPath, '$baseName$ext'));
        if (file.existsSync()) {
          return file.path;
        }
      }
    }

    // Try to find any localization file in locale subdirectory
    final localeDir = Directory(path.join(module.l10nPath, locale));
    if (localeDir.existsSync()) {
      for (final entity in localeDir.listSync()) {
        if (entity is File) {
          final ext = path.extension(entity.path).toLowerCase();
          if (ext == '.arb' ||
              ext == '.json' ||
              ext == '.yaml' ||
              ext == '.yml') {
            return entity.path;
          }
        }
      }
    }

    return null;
  }

  /// Get all supported locales from enabled modules
  static Set<String> getSupportedLocales(ModuleRepository repository) {
    final locales = <String>{};
    final enabledModules = repository.allEnabled();

    for (final module in enabledModules) {
      final moduleLocales = _getModuleLocales(module);
      locales.addAll(moduleLocales);
    }

    return locales;
  }

  /// Get locales supported by a module
  static Set<String> _getModuleLocales(Module module) {
    final locales = <String>{};
    final l10nDir = Directory(module.l10nPath);

    if (!l10nDir.existsSync()) {
      return locales;
    }

    try {
      for (final entity in l10nDir.listSync()) {
        if (entity is File) {
          // Support multiple formats: .arb, .json, .yaml, .yml
          final ext = path.extension(entity.path).toLowerCase();
          if (ext == '.arb' ||
              ext == '.json' ||
              ext == '.yaml' ||
              ext == '.yml') {
            // Extract locale from filename (e.g., app_en.arb -> en)
            final filename = path.basenameWithoutExtension(entity.path);
            final parts = filename.split('_');
            if (parts.length > 1) {
              locales.add(parts.last); // Last part is usually locale
            } else {
              locales.add(filename); // Filename itself might be locale
            }
          }
        } else if (entity is Directory) {
          // Directory name might be locale (e.g., l10n/en/)
          final dirName = path.basename(entity.path);
          if (RegExp(r'^[a-z]{2}(-[A-Z]{2})?$').hasMatch(dirName)) {
            locales.add(dirName);
          }
        }
      }
    } catch (e) {
      // Skip if can't read
    }

    return locales;
  }

  /// Generate pubspec.yaml localization entries for all enabled modules
  /// Returns a map of module names to their ARB file paths
  static Map<String, List<String>> generatePubspecLocalizations(
    ModuleRepository repository,
  ) {
    final localizations = <String, List<String>>{};
    final enabledModules = repository.allEnabled();

    for (final module in enabledModules) {
      final moduleL10n = getModuleLocalizations(module);
      if (moduleL10n.isNotEmpty) {
        // Convert to absolute paths for pubspec.yaml
        final absolutePaths = moduleL10n
            .map((relative) => path.join(module.l10nPath, relative))
            .toList();
        localizations[module.lowerName] = absolutePaths;
      }
    }

    return localizations;
  }

  /// Get localization namespace for a module (similar to Laravel's module::key)
  /// Returns the module's namespace prefix
  static String getModuleNamespace(Module module) {
    return module.lowerName;
  }

  /// Format translation key with module namespace
  /// Example: 'auth::login.title' -> 'auth.login.title'
  static String formatKey(Module module, String key) {
    return '${getModuleNamespace(module)}.$key';
  }
}
