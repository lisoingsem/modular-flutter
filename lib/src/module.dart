import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'exceptions/module_exceptions.dart';
import 'config_loader.dart';

/// Base class representing a Flutter module
class Module {
  /// The module name
  final String name;

  /// The module alias (lowercase, snake_case)
  final String alias;

  /// The module path
  final String modulePath;

  /// Module metadata from module.yaml
  final Map<String, dynamic> metadata;

  /// Module priority (lower number = higher priority)
  final int priority;

  /// Module version
  final String version;

  /// Module description
  final String? description;

  /// Module dependencies
  final List<String> requires;

  /// Service providers
  final List<String> providers;

  /// Route definitions
  final List<Map<String, dynamic>> routes;

  /// Menu definitions (grouped by menu name)
  final Map<String, List<Map<String, dynamic>>> menus;

  /// Whether the module is enabled
  bool _enabled;

  /// Get the enabled status
  bool get enabled => _enabled;

  /// Set the enabled status
  set enabled(bool value) {
    _enabled = value;
  }

  Module({
    required this.name,
    required this.alias,
    required this.modulePath,
    required this.metadata,
    this.priority = 999,
    this.version = '0.1.0',
    this.description,
    this.requires = const [],
    this.providers = const [],
    this.routes = const [],
    this.menus = const {},
    bool enabled = true,
  }) : _enabled = enabled;

  /// Create a Module instance from a module.yaml file
  factory Module.fromPath(String modulePath) {
    final moduleYamlPath = path.join(modulePath, 'module.yaml');
    final file = File(moduleYamlPath);

    if (!file.existsSync()) {
      throw InvalidModuleException(
        'module.yaml not found in $modulePath',
      );
    }

    try {
      final yamlContent = file.readAsStringSync();
      final yaml = loadYaml(yamlContent) as Map;

      final name = yaml['name'] as String?;
      if (name == null || name.isEmpty) {
        throw InvalidModuleException('Module name is required');
      }

      final alias = yaml['alias'] as String? ?? _toSnakeCase(name);
      final priority = yaml['priority'] as int? ?? 999;
      final version = yaml['version'] as String? ?? '0.1.0';
      final description = yaml['description'] as String?;
      final enabled = yaml['enabled'] as bool? ?? true;

      final requires = (yaml['requires'] as List?)?.cast<String>() ?? [];
      final providers = (yaml['providers'] as List?)?.cast<String>() ?? [];
      final routes = (yaml['routes'] as List?)
              ?.map((r) => Map<String, dynamic>.from(r as Map))
              .toList() ??
          [];
      final menusRaw = (yaml['menus'] as Map?);
      final menus = <String, List<Map<String, dynamic>>>{};
      if (menusRaw != null) {
        for (final entry in menusRaw.entries) {
          final key = entry.key.toString();
          final value = entry.value;
          if (value is List) {
            menus[key] =
                value.map((m) => Map<String, dynamic>.from(m as Map)).toList();
          } else {
            menus[key] = [];
          }
        }
      }

      return Module(
        name: name,
        alias: alias,
        modulePath: modulePath,
        metadata: Map<String, dynamic>.from(yaml),
        priority: priority,
        version: version,
        description: description,
        requires: requires,
        providers: providers,
        routes: routes,
        menus: menus,
        enabled: enabled,
      );
    } catch (e) {
      if (e is InvalidModuleException) {
        rethrow;
      }
      throw InvalidModuleJsonException(
        'Failed to parse module.yaml: ${e.toString()}',
      );
    }
  }

  /// Get the module's lib directory path
  String get libPath => path.join(modulePath, 'lib');

  /// Get the module's assets directory path
  String get assetsPath => path.join(modulePath, 'assets');

  /// Get the module's localization directory path
  /// Supports both 'lang' and 'l10n' directories
  String get l10nPath {
    final langPath = path.join(modulePath, 'lang');
    final l10nPath = path.join(modulePath, 'l10n');

    // Prefer 'lang' directory, fallback to 'l10n'
    if (Directory(langPath).existsSync()) {
      return langPath;
    }
    return l10nPath;
  }

  /// Get the module's config directory path
  String get configPath => path.join(modulePath, 'lib', 'config');

  /// Get module config manager
  ModuleConfig get config => ModuleConfig(this);

  /// Get a specific path within the module
  String getPath(String relativePath) {
    return path.join(modulePath, relativePath);
  }

  /// Check if a path exists in the module
  bool pathExists(String relativePath) {
    return File(getPath(relativePath)).existsSync() ||
        Directory(getPath(relativePath)).existsSync();
  }

  /// Get module name in different cases
  String get lowerName => alias.toLowerCase();
  String get studlyName => _toStudlyCase(name);
  String get kebabName => _toKebabCase(name);
  String get snakeName => alias;

  /// Get a value from metadata
  T? get<T>(String key, [T? defaultValue]) {
    return metadata[key] as T? ?? defaultValue;
  }

  @override
  String toString() => studlyName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Module &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          modulePath == other.modulePath;

  @override
  int get hashCode => name.hashCode ^ modulePath.hashCode;

  static String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }

  static String _toStudlyCase(String input) {
    return input
        .split(RegExp(r'[_\s-]'))
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join();
  }

  static String _toKebabCase(String input) {
    return _toSnakeCase(input).replaceAll('_', '-');
  }
}
