import 'dart:io';
import 'package:path/path.dart' as path;
import '../../modular_flutter.dart';
import 'command.dart';

/// Command to publish module assets/config to the application
/// Similar to Laravel's `module:publish`
class PublishCommand implements Command {
  @override
  Future<int> run(List<String> arguments) async {
    if (arguments.isEmpty) {
      print('Error: Module name is required');
      print('Usage: modular_flutter publish <module> [--tag=<tag>] [--force]');
      print('');
      print('Tags:');
      print('  assets    - Publish module assets');
      print('  config    - Publish module config files');
      print('  (default) - Publish all');
      return 64;
    }

    // Parse arguments manually
    String? moduleName;
    String? tag;
    bool force = false;

    for (final arg in arguments) {
      if (arg.startsWith('--tag=')) {
        tag = arg.substring(6);
      } else if (arg == '--force' || arg == '-f') {
        force = true;
      } else if (!arg.startsWith('--')) {
        moduleName = arg;
      }
    }

    if (moduleName == null) {
      print('Error: Module name is required');
      return 64;
    }

    try {
      final repository = ModuleRepository();
      final modules = repository.all();

      final module = modules.firstWhere(
        (m) => m.name.toLowerCase() == moduleName!.toLowerCase(),
        orElse: () => throw Exception('Module "$moduleName" not found'),
      );

      if (tag == null || tag == 'assets') {
        await _publishAssets(module, force);
      }

      if (tag == null || tag == 'config') {
        await _publishConfig(module, force);
      }

      print('Module "${module.name}" published successfully!');
      return 0;
    } catch (e) {
      print('Error publishing module: $e');
      return 1;
    }
  }

  Future<void> _publishAssets(Module module, bool force) async {
    final sourcePath = module.assetsPath;
    final sourceDir = Directory(sourcePath);

    if (!sourceDir.existsSync()) {
      print('No assets to publish for module "${module.name}"');
      return;
    }

    // Publish to app's assets directory
    final destPath = path.join(
        Directory.current.path, 'assets', 'modules', module.lowerName);
    final destDir = Directory(destPath);

    if (destDir.existsSync() && !force) {
      print('Assets already exist at $destPath. Use --force to overwrite.');
      return;
    }

    destDir.createSync(recursive: true);

    // Copy assets recursively
    await _copyDirectory(sourceDir, destDir, force);
    print('Published assets to $destPath');
  }

  Future<void> _publishConfig(Module module, bool force) async {
    final sourcePath = module.configPath;
    final sourceDir = Directory(sourcePath);

    if (!sourceDir.existsSync()) {
      print('No config files to publish for module "${module.name}"');
      return;
    }

    // Publish to app's config directory
    final destPath = path.join(
        Directory.current.path, 'config', 'modules', module.lowerName);
    final destDir = Directory(destPath);

    if (destDir.existsSync() && !force) {
      print('Config already exists at $destPath. Use --force to overwrite.');
      return;
    }

    destDir.createSync(recursive: true);

    // Copy config files
    await _copyDirectory(sourceDir, destDir, force);
    print('Published config to $destPath');
  }

  Future<void> _copyDirectory(
      Directory source, Directory dest, bool force) async {
    await for (final entity in source.list(recursive: true)) {
      final relativePath = path.relative(entity.path, from: source.path);
      final destPath = path.join(dest.path, relativePath);
      final destFile = File(destPath);

      if (entity is File) {
        if (destFile.existsSync() && !force) {
          continue;
        }
        destFile.parent.createSync(recursive: true);
        await entity.copy(destPath);
      }
    }
  }
}
