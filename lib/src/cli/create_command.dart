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
      print('Usage: modular_flutter create <name> [--force] [--submodule]');
      print('');
      print('Options:');
      print('  --force       Overwrite existing module');
      print('  --submodule   Initialize as git submodule (flutter-{name}.git)');
      return 64;
    }

    final moduleName = arguments[0];
    final force = arguments.contains('--force');
    final asSubmodule = arguments.contains('--submodule');

    try {
      final generator = ModuleGenerator();
      await generator.generate(moduleName, force: force);
      print('Module "$moduleName" created successfully!');

      // Initialize as git submodule if requested
      if (asSubmodule) {
        await _initAsSubmodule(moduleName);
      }

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

  Future<void> _initAsSubmodule(String moduleName) async {
    try {
      // Determine module path (packages or modules directory)
      final packagesPath = path.join(Directory.current.path, 'packages');
      final modulesPath = path.join(Directory.current.path, 'modules');
      final basePath =
          Directory(packagesPath).existsSync() ? packagesPath : modulesPath;
      final modulePath = path.join(basePath, moduleName);
      final moduleDir = Directory(modulePath);

      if (!moduleDir.existsSync()) {
        print('Warning: Module directory not found, skipping submodule init');
        return;
      }

      // Initialize git in module if not already
      final gitDir = Directory(path.join(modulePath, '.git'));
      if (!gitDir.existsSync()) {
        print('Initializing git repository in module...');
        final result = await Process.run(
          'git',
          ['init'],
          workingDirectory: modulePath,
        );
        if (result.exitCode != 0) {
          print('Warning: Failed to initialize git: ${result.stderr}');
          return;
        }
      }

      // Check if remote exists
      final remoteCheck = await Process.run(
        'git',
        ['remote', 'get-url', 'origin'],
        workingDirectory: modulePath,
      );

      if (remoteCheck.exitCode != 0) {
        // No remote, suggest creating one
        final snakeName = moduleName
            .replaceAllMapped(
                RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}')
            .replaceFirst(RegExp(r'^_'), '')
            .toLowerCase();
        print('');
        print('⚠️  Module is not a git submodule yet.');
        print('To set it up as a submodule:');
        print('');
        print('1. Create repository:');
        print('   cd ../');
        print('   git clone <your-flutter-repo> flutter-$snakeName');
        print('   cd flutter-$snakeName');
        print('   # Copy module files here');
        print('   git add .');
        print('   git commit -m "Initial commit"');
        print(
            '   git remote set-url origin git@github.com:lisoingsem/flutter-$snakeName.git');
        print('   git push -u origin main');
        print('');
        print('2. Add as submodule:');
        print('   cd /path/to/flutter');
        print(
            '   git submodule add -b main ../flutter-$snakeName.git $basePath/$moduleName');
        print('');
      } else {
        print('✓ Git repository initialized');
        print('  Remote: ${remoteCheck.stdout}');
      }
    } catch (e) {
      print('Warning: Failed to initialize submodule: $e');
    }
  }
}
