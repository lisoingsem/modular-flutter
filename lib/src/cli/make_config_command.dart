import '../cli/generators/config_generator.dart';
import 'command.dart';

class MakeConfigCommand implements Command {
  @override
  Future<int> run(List<String> arguments) async {
    if (arguments.isEmpty) {
      print('Error: Config name is required');
      print('Usage: modular_flutter make:config <name> --module=<module>');
      return 64;
    }

    final configName = arguments[0];
    String? moduleName;

    // Parse --module option
    for (final arg in arguments) {
      if (arg.startsWith('--module=')) {
        moduleName = arg.substring(9);
      }
    }

    if (moduleName == null) {
      print('Error: --module option is required');
      print('Usage: modular_flutter make:config <name> --module=<module>');
      return 64;
    }

    final force = arguments.contains('--force');

    try {
      final generator = ConfigGenerator();
      await generator.generate(configName, moduleName, force: force);
      print(
          'Config "$configName" created successfully in module "$moduleName"!');
      return 0;
    } catch (e) {
      print('Error creating config: $e');
      return 1;
    }
  }
}
