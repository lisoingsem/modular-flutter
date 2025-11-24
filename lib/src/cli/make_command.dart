import '../cli/generators/file_generator.dart';
import 'command.dart';

class MakeCommand implements Command {
  final String type;

  MakeCommand(this.type);

  @override
  Future<int> run(List<String> arguments) async {
    if (arguments.isEmpty) {
      print('Error: Name is required');
      print('Usage: flutter_modules make:$type <name> --module=<module>');
      return 64; // ExitCode.usage
    }

    final name = arguments[0];
    String? moduleName;

    // Parse --module option
    for (final arg in arguments) {
      if (arg.startsWith('--module=')) {
        moduleName = arg.substring(9);
      }
    }

    if (moduleName == null) {
      print('Error: --module option is required');
      print('Usage: flutter_modules make:$type <name> --module=<module>');
      return 64; // ExitCode.usage
    }

    final force = arguments.contains('--force');

    try {
      final generator = FileGenerator();
      await generator.generate(type, name, moduleName, force: force);
      print('$type "$name" created successfully in module "$moduleName"!');
      return 0; // ExitCode.success
    } catch (e) {
      print('Error creating $type: $e');
      return 1; // ExitCode.software
    }
  }
}
