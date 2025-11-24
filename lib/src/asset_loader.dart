import 'dart:io';
import 'package:path/path.dart' as path;
import 'module.dart';

/// Loader for module assets
class AssetLoader {
  /// Get asset paths from a module
  static List<String> getModuleAssets(Module module) {
    final assetsDir = Directory(module.assetsPath);
    if (!assetsDir.existsSync()) {
      return [];
    }

    final assets = <String>[];
    _collectAssets(assetsDir, assets, module.assetsPath);
    return assets;
  }

  /// Recursively collect all asset files
  static void _collectAssets(
    Directory dir,
    List<String> assets,
    String basePath,
  ) {
    try {
      for (final entity in dir.listSync()) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: basePath);
          assets.add(relativePath);
        } else if (entity is Directory) {
          _collectAssets(entity, assets, basePath);
        }
      }
    } catch (e) {
      // Skip directories that can't be read
    }
  }

  /// Get asset path for a module asset
  static String? getAssetPath(Module module, String assetName) {
    final assetFile = File(path.join(module.assetsPath, assetName));
    if (assetFile.existsSync()) {
      return assetFile.path;
    }
    return null;
  }
}
