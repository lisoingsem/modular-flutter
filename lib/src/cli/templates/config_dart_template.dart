/// Module configuration file
/// Similar to Laravel's config() helper
library;

/// Get config value (similar to config('key') in Laravel)
/// Usage: Config.get('api_url')
class Config {
  static Map<String, dynamic>? _config;

  /// Load config from YAML file
  static Map<String, dynamic> _loadConfig() {
    if (_config != null) {
      return _config!;
    }

    // This would be loaded by the module system
    // For now, return empty - actual loading happens via ConfigLoader
    return _config = {};
  }

  /// Get config value
  static T? get<T>(String key, [T? defaultValue]) {
    final config = _loadConfig();
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

  /// Check if key exists
  static bool has(String key) {
    return get(key) != null;
  }

  /// Get all config
  static Map<String, dynamic> all() {
    return Map<String, dynamic>.from(_loadConfig());
  }
}

