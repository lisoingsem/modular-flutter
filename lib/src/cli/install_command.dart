import 'dart:io';
import 'package:path/path.dart' as path;
import 'command.dart';

/// Command to install a module from pub.dev or git
/// Similar to Laravel's module installation
class InstallCommand implements Command {
  @override
  Future<int> run(List<String> arguments) async {
    if (arguments.isEmpty) {
      print('Error: Module package name is required');
      print('Usage: modular_flutter install <package> [options]');
      print('');
      print('Examples:');
      print('  modular_flutter install my_module');
      print('  modular_flutter install my_module --version=1.0.0');
      print('  modular_flutter install my_module --path=../my_module');
      print(
          '  modular_flutter install my_module --git=https://github.com/user/repo.git');
      return 64;
    }

    // Parse arguments manually
    String? packageName;
    String? version;
    String? localPath;
    String? gitUrl;
    bool isDev = false;

    for (final arg in arguments) {
      if (arg.startsWith('--version=')) {
        version = arg.substring(10);
      } else if (arg.startsWith('--path=')) {
        localPath = arg.substring(7);
      } else if (arg.startsWith('--git=')) {
        gitUrl = arg.substring(6);
      } else if (arg == '--dev') {
        isDev = true;
      } else if (!arg.startsWith('--')) {
        packageName = arg;
      }
    }

    if (packageName == null) {
      print('Error: Module package name is required');
      return 64;
    }

    try {
      // Read pubspec.yaml
      final pubspecFile =
          File(path.join(Directory.current.path, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) {
        print('Error: pubspec.yaml not found. Are you in a Flutter project?');
        return 1;
      }

      final pubspecContent = await pubspecFile.readAsString();

      // Determine dependency format
      String dependencyEntry;
      if (localPath != null) {
        dependencyEntry = '  $packageName:\n    path: $localPath';
      } else if (gitUrl != null) {
        final ref = version != null ? '\n    ref: $version' : '';
        dependencyEntry = '  $packageName:\n    git:\n      url: $gitUrl$ref';
      } else {
        dependencyEntry = version != null
            ? '  $packageName: $version'
            : '  $packageName: ^1.0.0';
      }

      // Add to dependencies section
      final section = isDev ? 'dev_dependencies:' : 'dependencies:';
      final sectionIndex = pubspecContent.indexOf(section);

      if (sectionIndex == -1) {
        print('Error: $section not found in pubspec.yaml');
        return 1;
      }

      // Check if already exists
      if (pubspecContent.contains('  $packageName:')) {
        print('Package "$packageName" already exists in pubspec.yaml');
        return 1;
      }

      // Insert dependency
      final insertIndex = pubspecContent.indexOf('\n', sectionIndex) + 1;
      final newContent = pubspecContent.substring(0, insertIndex) +
          dependencyEntry +
          '\n' +
          pubspecContent.substring(insertIndex);

      await pubspecFile.writeAsString(newContent);

      print('Added "$packageName" to pubspec.yaml');
      print('Run "flutter pub get" to install the package.');

      // Optionally run flutter pub get
      print('');
      print('Running "flutter pub get"...');
      final process = await Process.run('flutter', ['pub', 'get']);
      if (process.exitCode != 0) {
        print('Warning: flutter pub get failed');
        print(process.stderr);
        return 1;
      }

      print('Module "$packageName" installed successfully!');
      return 0;
    } catch (e) {
      print('Error installing module: $e');
      return 1;
    }
  }
}
