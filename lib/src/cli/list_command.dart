import 'dart:convert';
import '../module_filter.dart';
import '../module_repository.dart';
import 'command.dart';

class ListCommand implements Command {
  @override
  Future<int> run(List<String> arguments) async {
    // Parse format option
    String format = 'table';
    String? scope;
    String? ignore;
    bool? enabled;
    bool? disabled;

    for (final arg in arguments) {
      if (arg.startsWith('--format=')) {
        format = arg.substring(9);
      } else if (arg.startsWith('--scope=')) {
        scope = arg.substring(8);
      } else if (arg.startsWith('--ignore=')) {
        ignore = arg.substring(9);
      } else if (arg == '--enabled') {
        enabled = true;
      } else if (arg == '--disabled') {
        disabled = true;
      }
    }

    try {
      final repository = ModuleRepository();
      var modules = repository.all();

      // Apply filters
      final filter = ModuleFilter(
        scope: scope,
        ignore: ignore,
        enabled: enabled,
        disabled: disabled,
      );
      modules = filter.apply(modules);

      if (modules.isEmpty) {
        print('No modules found.');
        return 0;
      }

      // Output in requested format
      switch (format) {
        case 'json':
          _printJson(modules);
          break;
        case 'simple':
          _printSimple(modules);
          break;
        case 'table':
        default:
          _printTable(modules);
          break;
      }

      return 0;
    } catch (e) {
      print('Error listing modules: $e');
      return 1;
    }
  }

  void _printTable(List modules) {
    print('Modules:');
    print('');
    print('Name'.padRight(20) +
        'Status'.padRight(10) +
        'Version'.padRight(10) +
        'Priority'.padRight(10) +
        'Description');
    print('-' * 100);

    for (final module in modules) {
      final name = module.name.padRight(20);
      final status = (module.enabled ? 'Enabled' : 'Disabled').padRight(10);
      final version = module.version.padRight(10);
      final priority = module.priority.toString().padRight(10);
      final description = module.description ?? '';
      print('$name$status$version$priority$description');
    }

    print('');
    print('Total: ${modules.length}');
  }

  void _printJson(List modules) {
    final json = modules.map((module) {
      return {
        'name': module.name,
        'alias': module.alias,
        'version': module.version,
        'enabled': module.enabled,
        'priority': module.priority,
        'description': module.description,
        'path': module.modulePath,
        'requires': module.requires,
      };
    }).toList();

    print(const JsonEncoder.withIndent('  ').convert(json));
  }

  void _printSimple(List modules) {
    for (final module in modules) {
      final status = module.enabled ? '✓' : '✗';
      print('$status ${module.name} (${module.version})');
    }
  }
}
