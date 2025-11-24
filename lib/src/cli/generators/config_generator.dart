import 'dart:io';
import 'package:path/path.dart' as path;
import '../templates/module_templates.dart';

/// Generator for module config files
class ConfigGenerator {
  Future<void> generate(String configName, String moduleName,
      {bool force = false}) async {
    final modulesPath = path.join(Directory.current.path, 'modules');
    final modulePath = path.join(modulesPath, moduleName);
    final configPath = path.join(modulePath, 'lib', 'config');
    final configFile = File(path.join(configPath, '$configName.yaml'));

    if (configFile.existsSync() && !force) {
      throw Exception(
        'Config file "$configName.yaml" already exists. Use --force to overwrite.',
      );
    }

    // Ensure directory exists
    Directory(configPath).createSync(recursive: true);

    // Generate YAML config file
    final content = ModuleTemplates.configFile(
      name: configName,
      alias: configName.toLowerCase(),
      studlyName: configName,
    );
    configFile.writeAsStringSync(content);
  }
}
