/// Parser for provider class names to extract package and import information
class ProviderParser {
  /// Parse a provider class name like "auth_module.providers.AuthServiceProvider"
  /// Returns a map with 'package', 'path', and 'className'
  static Map<String, String> parse(String providerClass) {
    // Format: package_name.providers.ClassName
    // Example: auth_module.providers.AuthServiceProvider

    final parts = providerClass.split('.');

    if (parts.length < 3) {
      throw FormatException(
        'Invalid provider class format: $providerClass. '
        'Expected format: package_name.providers.ClassName',
      );
    }

    final packageName = parts[0];
    final namespace = parts[1]; // Should be 'providers'
    final className = parts[2];

    if (namespace != 'providers') {
      throw FormatException(
        'Invalid provider namespace: $namespace. Expected "providers"',
      );
    }

    // Convert class name to file name (snake_case)
    final fileName = _toSnakeCase(className);

    return {
      'package': packageName,
      'path': 'providers/$fileName.dart',
      'className': className,
      'import': 'package:$packageName/providers/$fileName.dart',
    };
  }

  /// Convert StudlyCase to snake_case
  static String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
            RegExp(r'([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }

  /// Validate provider class name format
  static bool isValid(String providerClass) {
    try {
      parse(providerClass);
      return true;
    } catch (e) {
      return false;
    }
  }
}
