import '../cli/generators/module_generator.dart';
import 'command.dart';

class CreateCommand implements Command {
  @override
  Future<int> run(List<String> arguments) async {
    if (arguments.isEmpty) {
      print('Error: Module name is required');
      print('Usage: modular_flutter create <name> [--force]');
      return 64;
    }

    final moduleName = arguments[0];
    final force = arguments.contains('--force');

    try {
      final generator = ModuleGenerator();
      await generator.generate(moduleName, force: force);
      print('Module "$moduleName" created successfully!');
      return 0;
    } catch (e) {
      print('Error creating module: $e');
      return 1;
    }
  }
}
