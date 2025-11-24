import 'create_command.dart';
import 'make_command.dart';
import 'make_config_command.dart';
import 'enable_command.dart';
import 'disable_command.dart';
import 'list_command.dart';
import 'exec_command.dart';
import 'publish_command.dart';
import 'install_command.dart';
import 'command.dart';

/// Main command runner for modular_flutter CLI
class CommandRunner {
  final Map<String, Command> _commands = {};

  CommandRunner() {
    _setupCommands();
  }

  void _setupCommands() {
    _commands['create'] = CreateCommand();
    _commands['make:widget'] = MakeCommand('widget');
    _commands['make:service'] = MakeCommand('service');
    _commands['make:route'] = MakeCommand('route');
    _commands['make:provider'] = MakeCommand('provider');
    _commands['make:config'] = MakeConfigCommand();
    _commands['enable'] = EnableCommand();
    _commands['disable'] = DisableCommand();
    _commands['list'] = ListCommand();
    _commands['exec'] = ExecCommand();
    _commands['publish'] = PublishCommand();
    _commands['install'] = InstallCommand();
  }

  Future<int> run(List<String> arguments) async {
    if (arguments.isEmpty) {
      _printUsage();
      return 64; // ExitCode.usage
    }

    final commandName = arguments[0];
    final commandArgs = arguments.skip(1).toList();

    // Handle make:* commands
    if (commandName.startsWith('make:')) {
      final makeType = commandName.substring(5);
      final makeCommand = MakeCommand(makeType);
      return await makeCommand.run(commandArgs);
    }

    final command = _commands[commandName];
    if (command == null) {
      print('Unknown command: $commandName');
      _printUsage();
      return 64; // ExitCode.usage
    }

    return await command.run(commandArgs);
  }

  void _printUsage() {
    print('Flutter Modules CLI');
    print('');
    print('Usage: modular_flutter <command> [arguments]');
    print('');
    print('Available commands:');
    print('  create <name>              Create a new module');
    print('  make:widget <name>         Generate a widget');
    print('  make:service <name>        Generate a service');
    print('  make:route <name>          Generate a route');
    print('  make:provider <name>       Generate a state provider');
    print('  make:config <name>         Generate a config file');
    print('  enable <name>              Enable a module');
    print('  disable <name>             Disable a module');
    print('  list                       List all modules');
    print('  exec -- <command>          Execute command across modules');
    print('  publish <name>             Publish module assets/config');
    print('  install <package>          Install module from pub.dev/git/path');
    print('');
    print('Options:');
    print('  --module=<name>            Specify module for make commands');
    print('  --force                    Overwrite existing files');
    print('  --scope=<glob>             Filter modules by name pattern');
    print('  --ignore=<glob>            Exclude modules matching pattern');
    print('  --enabled                  Only enabled modules');
    print('  --disabled                 Only disabled modules');
    print('  --format=<format>          Output format (table, json, simple)');
    print('  --concurrency=<n>         Parallel execution count (exec only)');
    print('  --fail-fast                Stop on first failure (exec only)');
  }
}
