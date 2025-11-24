import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'command.dart';

class DisableCommand implements Command {
  @override
  Future<int> run(List<String> arguments) async {
    if (arguments.isEmpty) {
      print('Error: Module name is required');
      print('Usage: flutter_modules disable <name>');
      return 64; // ExitCode.usage
    }

    final moduleName = arguments[0];
    final statusesPath =
        path.join(Directory.current.path, 'modules_statuses.json');

    try {
      // Load current statuses
      Map<String, bool> statuses = {};
      final statusesFile = File(statusesPath);
      if (statusesFile.existsSync()) {
        final content = statusesFile.readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;
        statuses = json.map((key, value) => MapEntry(key, value as bool));
      }

      // Disable the module
      statuses[moduleName.toLowerCase()] = false;

      // Save statuses
      statusesFile.createSync(recursive: true);
      statusesFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(statuses),
      );

      print('Module "$moduleName" disabled successfully!');
      print('Status saved to: $statusesPath');
      return 0; // ExitCode.success
    } catch (e) {
      print('Error disabling module: $e');
      return 1; // ExitCode.software
    }
  }
}
