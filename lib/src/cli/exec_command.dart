import 'dart:io';
import 'package:flutter_modular/src/module_repository.dart';
import 'package:flutter_modular/src/module_filter.dart';
import 'package:flutter_modular/src/module.dart';
import 'command.dart';

/// Execute command across filtered modules (inspired by Melos exec)
class ExecCommand implements Command {
  @override
  Future<int> run(List<String> arguments) async {
    if (arguments.isEmpty) {
      print('Error: Command is required');
      print('Usage: flutter_modular exec -- <command>');
      print('');
      print('Options:');
      print('  --scope=<glob>        Include only modules matching glob');
      print('  --ignore=<glob>       Exclude modules matching glob');
      print('  --enabled             Only enabled modules');
      print('  --disabled            Only disabled modules');
      print('  --concurrency=<n>     Run N commands in parallel (default: 1)');
      print('  --fail-fast           Stop on first failure');
      return 64; // ExitCode.usage
    }

    // Parse options
    final commandArgs = <String>[];
    String? scope;
    String? ignore;
    bool? enabled;
    bool? disabled;
    int concurrency = 1;
    bool failFast = false;

    for (final arg in arguments) {
      if (arg == '--') {
        continue;
      } else if (arg.startsWith('--scope=')) {
        scope = arg.substring(8);
      } else if (arg.startsWith('--ignore=')) {
        ignore = arg.substring(9);
      } else if (arg == '--enabled') {
        enabled = true;
      } else if (arg == '--disabled') {
        disabled = true;
      } else if (arg.startsWith('--concurrency=')) {
        concurrency = int.tryParse(arg.substring(14)) ?? 1;
      } else if (arg == '--fail-fast') {
        failFast = true;
      } else {
        commandArgs.add(arg);
      }
    }

    if (commandArgs.isEmpty) {
      print('Error: Command is required after --');
      return 64;
    }

    final command = commandArgs.join(' ');

    try {
      final repository = ModuleRepository();
      final modules = repository.all();

      // Apply filters
      final filter = ModuleFilter(
        scope: scope,
        ignore: ignore,
        enabled: enabled,
        disabled: disabled,
      );
      final filteredModules = filter.apply(modules);

      if (filteredModules.isEmpty) {
        print('No modules match the filter criteria.');
        return 0;
      }

      print('Executing: $command');
      print('In ${filteredModules.length} module(s)');
      print('');

      // Execute command in each module
      final results = <Map<String, dynamic>>[];

      for (var i = 0; i < filteredModules.length; i += concurrency) {
        final batch = filteredModules.skip(i).take(concurrency).toList();
        final futures =
            batch.map((module) => _executeInModule(module, command));

        final batchResults = await Future.wait(futures);
        results.addAll(batchResults);

        // Check for failures if fail-fast is enabled
        if (failFast) {
          final failures = results.where((r) => r['exitCode'] != 0).toList();
          if (failures.isNotEmpty) {
            print('');
            print('Failed in: ${failures.map((f) => f['module']).join(', ')}');
            return 1;
          }
        }
      }

      // Print summary
      print('');
      final successes = results.where((r) => r['exitCode'] == 0).length;
      final failures = results.where((r) => r['exitCode'] != 0).length;

      print('Summary:');
      print('  Success: $successes');
      print('  Failed: $failures');

      return failures > 0 ? 1 : 0;
    } catch (e) {
      print('Error executing command: $e');
      return 1;
    }
  }

  Future<Map<String, dynamic>> _executeInModule(
    Module module,
    String command,
  ) async {
    print('[${module.name}] Running: $command');

    try {
      final result = await Process.run(
        'sh',
        ['-c', command],
        workingDirectory: module.modulePath,
        runInShell: true,
        environment: {
          'MODULE_NAME': module.name,
          'MODULE_PATH': module.modulePath,
          'MODULE_ALIAS': module.alias,
          'MODULE_VERSION': module.version,
        },
      );

      if (result.exitCode == 0) {
        if (result.stdout.toString().trim().isNotEmpty) {
          print('[${module.name}] ${result.stdout}');
        }
      } else {
        print('[${module.name}] Error: ${result.stderr}');
      }

      return {
        'module': module.name,
        'exitCode': result.exitCode,
        'stdout': result.stdout.toString(),
        'stderr': result.stderr.toString(),
      };
    } catch (e) {
      print('[${module.name}] Exception: $e');
      return {
        'module': module.name,
        'exitCode': 1,
        'error': e.toString(),
      };
    }
  }
}
