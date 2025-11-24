import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'module.dart';

/// Interface for module activation management
abstract class Activator {
  /// Check if a module has a specific status
  bool hasStatus(Module module, bool status);

  /// Set the active status of a module
  void setActive(Module module, bool active);

  /// Enable a module
  void enable(Module module);

  /// Disable a module
  void disable(Module module);

  /// Delete module status
  void delete(Module module);

  /// Get all enabled module names
  List<String> getEnabledModules();

  /// Get all disabled module names
  List<String> getDisabledModules();
}

/// File-based activator that stores module status in a JSON file
class FileActivator implements Activator {
  final String statusesFilePath;
  Map<String, bool> _statuses = {};

  FileActivator({String? statusesFilePath})
      : statusesFilePath = statusesFilePath ??
            path.join(Directory.current.path, 'modules.json') {
    _loadStatuses();
  }

  /// Load statuses from file
  void _loadStatuses() {
    final file = File(statusesFilePath);
    if (file.existsSync()) {
      try {
        final content = file.readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _statuses = json.map((key, value) => MapEntry(key, value as bool));
      } catch (e) {
        // If file is corrupted, start fresh
        _statuses = {};
      }
    }
  }

  /// Save statuses to file
  void _saveStatuses() {
    final file = File(statusesFilePath);
    file.createSync(recursive: true);
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(_statuses),
    );
  }

  @override
  bool hasStatus(Module module, bool status) {
    final moduleName = module.name.toLowerCase();
    return _statuses[moduleName] == status;
  }

  @override
  void setActive(Module module, bool active) {
    final moduleName = module.name.toLowerCase();
    _statuses[moduleName] = active;
    _saveStatuses();
  }

  @override
  void enable(Module module) {
    setActive(module, true);
  }

  @override
  void disable(Module module) {
    setActive(module, false);
  }

  @override
  void delete(Module module) {
    final moduleName = module.name.toLowerCase();
    _statuses.remove(moduleName);
    _saveStatuses();
  }

  @override
  List<String> getEnabledModules() {
    return _statuses.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  @override
  List<String> getDisabledModules() {
    return _statuses.entries
        .where((entry) => entry.value == false)
        .map((entry) => entry.key)
        .toList();
  }
}
