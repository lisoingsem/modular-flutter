import 'dart:io';
import 'package:path/path.dart' as path;
import '../../build/generator.dart';
import '../command.dart';

/// Command to generate modules.dart file with auto-registration code
class BuildCommand implements Command {
  @override
  Future<int> run(List<String> arguments) async {
    try {
      final projectRoot = Directory.current.path;

      // Check if we're in a Flutter project
      final pubspecPath = path.join(projectRoot, 'pubspec.yaml');
      if (!File(pubspecPath).existsSync()) {
        print('Error: Not in a Flutter project (pubspec.yaml not found)');
        return 1;
      }

      print('Generating modules.dart...');

      // Try to detect modules path (packages or modules directory)
      String? modulesPath;
      if (Directory(path.join(projectRoot, 'packages')).existsSync()) {
        modulesPath = 'packages';
      } else if (Directory(path.join(projectRoot, 'modules')).existsSync()) {
        modulesPath = 'modules';
      }

      final generator = ModuleCodeGenerator(
        projectRoot: projectRoot,
        localModulesPath: modulesPath,
      );
      await generator.generate();

      print('✓ Successfully generated modules.dart');
      print('');
      print('Next steps:');
      print('  1. Import modules.dart in your main.dart:');
      print("     import 'app/modules.dart';");
      print(
          '  2. Call registerAllModules(registry) before registry.register()');

      return 0;
    } catch (e) {
      print('Error generating modules.dart: $e');
      return 1;
    }
  }
}
