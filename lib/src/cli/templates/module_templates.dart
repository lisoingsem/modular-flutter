class ModuleTemplates {
  static String moduleYaml({
    required String name,
    required String alias,
    required String studlyName,
  }) {
    return '''name: $name
alias: $alias
description: $studlyName module
version: 0.1.0
priority: 999
enabled: true
providers:
  - modules.$alias.providers.${alias}_service_provider
routes:
  - path: /$alias
    widget: modules.$alias.routes.${alias}_route
requires: []
''';
  }

  static String moduleClass({
    required String name,
    required String alias,
    required String studlyName,
  }) {
    return '''/// $studlyName Module
library ${alias}_module;

export 'widgets/${alias}_widget.dart';
export 'routes/${alias}_route.dart';
export 'providers/${alias}_service_provider.dart';
export 'config/config.dart';
''';
  }

  static String configFile({
    required String name,
    required String alias,
    required String studlyName,
  }) {
    return '''# $studlyName Configuration
# Similar to Laravel's config files

name: $name
version: 1.0.0
enabled: true

# Add your configuration here
# Example:
# api_url: https://api.example.com
# timeout: 30
# features:
#   feature1: true
#   feature2: false
# database:
#   host: localhost
#   port: 5432
''';
  }

  static String serviceProvider({
    required String name,
    required String alias,
    required String studlyName,
  }) {
    return '''import 'package:modular_flutter/modular_flutter.dart';

/// Service provider for $studlyName module
class ${studlyName}ServiceProvider extends ModuleProvider {
  ${studlyName}ServiceProvider(super.module);

  @override
  void register() {
    // Register services, dependencies, etc.
  }

  @override
  void boot() {
    // Boot services after all modules are registered
  }
}
''';
  }

  static String widget({
    required String name,
    required String alias,
    required String studlyName,
    String? moduleName,
    String? moduleAlias,
    String? moduleStudlyName,
  }) {
    return '''import 'package:flutter/material.dart';

/// $studlyName Widget
class ${studlyName}Widget extends StatelessWidget {
  const ${studlyName}Widget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$studlyName'),
      ),
      body: const Center(
        child: Text('$studlyName Widget'),
      ),
    );
  }
}
''';
  }

  static String service({
    required String name,
    required String alias,
    required String studlyName,
    String? moduleName,
    String? moduleAlias,
    String? moduleStudlyName,
  }) {
    return '''/// $studlyName Service
class ${studlyName}Service {
  // Add your service methods here
}
''';
  }

  static String route({
    required String name,
    required String alias,
    required String studlyName,
    String? moduleName,
    String? moduleAlias,
    String? moduleStudlyName,
  }) {
    return '''import 'package:flutter/material.dart';
import 'widgets/${alias}_widget.dart';

/// $studlyName Route
class ${studlyName}Route {
  static const String path = '/$alias';
  
  static Widget build() {
    return const ${studlyName}Widget();
  }
}
''';
  }

  static String provider({
    required String name,
    required String alias,
    required String studlyName,
    String? moduleName,
    String? moduleAlias,
    String? moduleStudlyName,
  }) {
    return '''import 'package:flutter/material.dart';

/// $studlyName Provider (for state management)
class ${studlyName}Provider extends ChangeNotifier {
  // Add your state and methods here
  
  void update() {
    notifyListeners();
  }
}
''';
  }

  static String pubspecYaml({
    required String name,
    required String studlyName,
  }) {
    return '''name: $name
description: $studlyName module for Flutter
version: 0.1.0
homepage: https://github.com/yourusername/$name

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter
  modular_flutter: ^0.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
''';
  }

  static String readme({
    required String name,
    required String alias,
    required String studlyName,
  }) {
    return '''# $studlyName Module

A Flutter module built with modular_flutter.

## Installation

Add to your app's \`pubspec.yaml\`:

\`\`\`yaml
dependencies:
  $name:
    path: modules/$name
    # Or from pub.dev:
    # $name: ^0.1.0
\`\`\`

## Usage

\`\`\`dart
import 'package:$name/$name.dart';
\`\`\`

## Publishing

To publish this module to pub.dev:

1. Update version in \`pubspec.yaml\`
2. Run \`flutter pub publish --dry-run\` to check
3. Run \`flutter pub publish\` to publish

## Customization

You can customize this module by:
- Publishing config: \`modular_flutter publish $name --tag=config\`
- Publishing assets: \`modular_flutter publish $name --tag=assets\`
- Override in your app's \`config/modules/$alias/\` directory
''';
  }
}
