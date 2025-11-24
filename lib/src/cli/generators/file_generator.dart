import 'dart:io';
import 'package:path/path.dart' as path;
import '../templates/module_templates.dart';

class FileGenerator {
  Future<void> generate(
    String type,
    String name,
    String moduleName, {
    bool force = false,
  }) async {
    final modulesPath = path.join(Directory.current.path, 'modules');
    final modulePath = path.join(modulesPath, moduleName);

    if (!Directory(modulePath).existsSync()) {
      throw Exception('Module "$moduleName" not found.');
    }

    final snakeName = _toSnakeCase(name);
    final studlyName = _toStudlyCase(name);
    final moduleSnakeName = _toSnakeCase(moduleName);
    final moduleStudlyName = _toStudlyCase(moduleName);

    String content;
    String filePath;

    switch (type) {
      case 'widget':
        content = ModuleTemplates.widget(
          name: name,
          alias: snakeName,
          studlyName: studlyName,
          moduleName: moduleName,
          moduleAlias: moduleSnakeName,
          moduleStudlyName: moduleStudlyName,
        );
        filePath =
            path.join(modulePath, 'lib', 'widgets', '${snakeName}_widget.dart');
        break;

      case 'service':
        content = ModuleTemplates.service(
          name: name,
          alias: snakeName,
          studlyName: studlyName,
          moduleName: moduleName,
          moduleAlias: moduleSnakeName,
          moduleStudlyName: moduleStudlyName,
        );
        filePath = path.join(
            modulePath, 'lib', 'services', '${snakeName}_service.dart');
        break;

      case 'route':
        content = ModuleTemplates.route(
          name: name,
          alias: snakeName,
          studlyName: studlyName,
          moduleName: moduleName,
          moduleAlias: moduleSnakeName,
          moduleStudlyName: moduleStudlyName,
        );
        filePath =
            path.join(modulePath, 'lib', 'routes', '${snakeName}_route.dart');
        break;

      case 'provider':
        content = ModuleTemplates.provider(
          name: name,
          alias: snakeName,
          studlyName: studlyName,
          moduleName: moduleName,
          moduleAlias: moduleSnakeName,
          moduleStudlyName: moduleStudlyName,
        );
        filePath = path.join(
            modulePath, 'lib', 'providers', '${snakeName}_provider.dart');
        break;

      default:
        throw Exception('Unknown type: $type');
    }

    final file = File(filePath);
    if (file.existsSync() && !force) {
      throw Exception(
          'File already exists: $filePath. Use --force to overwrite.');
    }

    // Ensure directory exists
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
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
