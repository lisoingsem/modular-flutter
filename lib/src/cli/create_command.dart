import 'dart:io';
import 'package:path/path.dart' as path;
import '../cli/generators/module_generator.dart';
import 'commands/build_command.dart';
import 'command.dart';

class CreateCommand implements Command {
  @override
  Future<int> run(List<String> arguments) async {
    if (arguments.isEmpty) {
      print('Error: Module name is required');
      print('Usage: modular_flutter create <name> [--force]');
      print('');
      print('Options:');
      print('  --force       Overwrite existing module');
      return 64;
    }

    final moduleName = arguments[0];
    final force = arguments.contains('--force');

    try {
      final generator = ModuleGenerator();
      await generator.generate(moduleName, force: force);
      print('Module "$moduleName" created successfully!');

      // Auto-regenerate modules.dart if it exists
      final modulesPath =
          path.join(Directory.current.path, 'lib', 'app', 'modules.dart');
      if (File(modulesPath).existsSync()) {
        print('Regenerating modules.dart...');
        final buildCommand = BuildCommand();
        await buildCommand.run([]);
      }

      return 0;
    } catch (e) {
      print('Error creating module: $e');
      return 1;
    }
  }
}
