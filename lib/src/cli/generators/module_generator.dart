import 'dart:io';
import 'package:path/path.dart' as path;
import '../templates/module_templates.dart';

class ModuleGenerator {
  Future<void> generate(String moduleName, {bool force = false}) async {
    final modulesPath = path.join(Directory.current.path, 'modules');
    final modulePath = path.join(modulesPath, moduleName);
    final moduleDir = Directory(modulePath);

    // Check if module already exists
    if (moduleDir.existsSync() && !force) {
      throw Exception(
          'Module "$moduleName" already exists. Use --force to overwrite.');
    }

    // Create directory structure
    final dirs = [
      path.join(modulePath, 'lib'),
      path.join(modulePath, 'lib', 'widgets'),
      path.join(modulePath, 'lib', 'services'),
      path.join(modulePath, 'lib', 'routes'),
      path.join(modulePath, 'lib', 'providers'),
      path.join(modulePath, 'lib', 'models'),
      path.join(modulePath, 'lib', 'config'),
      path.join(modulePath, 'assets'),
      path.join(modulePath, 'lang'),
      path.join(modulePath, 'test'),
    ];

    for (final dir in dirs) {
      Directory(dir).createSync(recursive: true);
    }

    // Generate files
    final snakeName = _toSnakeCase(moduleName);
    final studlyName = _toStudlyCase(moduleName);

    // module.yaml
    final moduleYaml = ModuleTemplates.moduleYaml(
      name: moduleName,
      alias: snakeName,
      studlyName: studlyName,
    );
    File(path.join(modulePath, 'module.yaml')).writeAsStringSync(moduleYaml);

    // Module class
    final moduleClass = ModuleTemplates.moduleClass(
      name: moduleName,
      alias: snakeName,
      studlyName: studlyName,
    );
    File(path.join(modulePath, 'lib', '${snakeName}_module.dart'))
        .writeAsStringSync(moduleClass);

    // Service provider
    final provider = ModuleTemplates.serviceProvider(
      name: moduleName,
      alias: snakeName,
      studlyName: studlyName,
    );
    File(path.join(modulePath, 'lib', 'providers',
            '${snakeName}_service_provider.dart'))
        .writeAsStringSync(provider);

    // Example widget
    final widget = ModuleTemplates.widget(
      name: moduleName,
      alias: snakeName,
      studlyName: studlyName,
    );
    File(path.join(modulePath, 'lib', 'widgets', '${snakeName}_widget.dart'))
        .writeAsStringSync(widget);

    // Example route
    final route = ModuleTemplates.route(
      name: moduleName,
      alias: snakeName,
      studlyName: studlyName,
    );
    File(path.join(modulePath, 'lib', 'routes', '${snakeName}_route.dart'))
        .writeAsStringSync(route);

    // Default config file
    final config = ModuleTemplates.configFile(
      name: moduleName,
      alias: snakeName,
      studlyName: studlyName,
    );
    File(path.join(modulePath, 'lib', 'config', 'config.yaml'))
        .writeAsStringSync(config);

    // pubspec.yaml for publishable modules
    final pubspec = ModuleTemplates.pubspecYaml(
      name: snakeName,
      studlyName: studlyName,
    );
    File(path.join(modulePath, 'pubspec.yaml')).writeAsStringSync(pubspec);

    // README.md
    final readme = ModuleTemplates.readme(
      name: moduleName,
      alias: snakeName,
      studlyName: studlyName,
    );
    File(path.join(modulePath, 'README.md')).writeAsStringSync(readme);
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }

  String _toStudlyCase(String input) {
    return input
        .split(RegExp(r'[_\s-]'))
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join();
  }
}
