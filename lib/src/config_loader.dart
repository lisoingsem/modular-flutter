import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'module.dart';

/// Configuration loader for modules
/// Supports customization via app's config directory
class ConfigLoader {
  /// Load configuration from a module's config directory
  /// Checks for app overrides first (allows app-level customization)
  static Map<String, dynamic> loadConfig(Module module, String configName) {
    // First, try to load from app's config directory (customization)
    final appConfigPath = path.join(
      Directory.current.path,
      'config',
      'modules',
      module.lowerName,
      '$configName.yaml',
    );
    final appConfigFile = File(appConfigPath);

    if (appConfigFile.existsSync()) {
      try {
        final content = appConfigFile.readAsStringSync();
        final yaml = loadYaml(content) as Map;
        return Map<String, dynamic>.from(yaml);
      } catch (e) {
        // Fall through to module config
      }
    }

    // Load from module's config directory
    final configFile = File(
      path.join(module.configPath, '$configName.yaml'),
    );

    if (!configFile.existsSync()) {
      // Try .dart file
      return _loadDartConfig(module, configName);
    }

    try {
      final content = configFile.readAsStringSync();
      final yaml = loadYaml(content) as Map;
      return Map<String, dynamic>.from(yaml);
    } catch (e) {
      return {};
    }
  }

  /// Load Dart-based config file
  static Map<String, dynamic> _loadDartConfig(
      Module module, String configName) {
    final configFile = File(
      path.join(module.configPath, '$configName.dart'),
    );

    if (!configFile.existsSync()) {
      return {};
    }

    // For Dart config files, we'd need to execute them
    // For now, return empty - this would require a more complex implementation
    // Users can use YAML for easier loading
    return {};
  }

  /// Get a specific config value
  static T? get<T>(Module module, String configName, String key,
      [T? defaultValue]) {
    final config = loadConfig(module, configName);
    final keys = key.split('.');
    dynamic value = config;

    for (final k in keys) {
      if (value is Map && value.containsKey(k)) {
        value = value[k];
      } else {
        return defaultValue;
      }
    }

    return value as T? ?? defaultValue;
  }

  /// Check if config file exists
  static bool hasConfig(Module module, String configName) {
    final yamlFile = File(path.join(module.configPath, '$configName.yaml'));
    final dartFile = File(path.join(module.configPath, '$configName.dart'));
    return yamlFile.existsSync() || dartFile.existsSync();
  }

  /// Get all config files in module
  static List<String> getAllConfigs(Module module) {
    final configDir = Directory(module.configPath);
    if (!configDir.existsSync()) {
      return [];
    }

    return configDir
        .listSync()
        .whereType<File>()
        .where(
            (file) => file.path.endsWith('.yaml') || file.path.endsWith('.yml'))
        .map((file) => path.basenameWithoutExtension(file.path))
        .toList();
  }
}

/// Module configuration manager
class ModuleConfig {
  final Module module;
  final Map<String, Map<String, dynamic>> _cache = {};

  ModuleConfig(this.module);

  /// Get config value (similar to config('module.key'))
  T? get<T>(String key, [T? defaultValue]) {
    final parts = key.split('.');
    if (parts.isEmpty) {
      return defaultValue;
    }

    final configName = parts[0];
    final configKey = parts.length > 1 ? parts.sublist(1).join('.') : null;

    // Load config if not cached
    if (!_cache.containsKey(configName)) {
      _cache[configName] = ConfigLoader.loadConfig(module, configName);
    }

    final config = _cache[configName]!;

    if (configKey == null) {
      return config as T? ?? defaultValue;
    }

    // Navigate nested keys
    final keys = configKey.split('.');
    dynamic value = config;

    for (final k in keys) {
      if (value is Map && value.containsKey(k)) {
        value = value[k];
      } else {
        return defaultValue;
      }
    }

    return value as T? ?? defaultValue;
  }

  /// Check if config key exists
  bool has(String key) {
    return get(key) != null;
  }

  /// Get all config values
  Map<String, dynamic> all([String? configName]) {
    if (configName != null) {
      if (!_cache.containsKey(configName)) {
        _cache[configName] = ConfigLoader.loadConfig(module, configName);
      }
      return Map<String, dynamic>.from(_cache[configName]!);
    }

    // Return all configs
    final allConfigs = <String, dynamic>{};
    for (final configName in ConfigLoader.getAllConfigs(module)) {
      if (!_cache.containsKey(configName)) {
        _cache[configName] = ConfigLoader.loadConfig(module, configName);
      }
      allConfigs[configName] = _cache[configName]!;
    }
    return allConfigs;
  }

  /// Clear config cache
  void clearCache() {
    _cache.clear();
  }
}
