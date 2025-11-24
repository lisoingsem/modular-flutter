import 'module.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

/// Filter options for modules (inspired by Melos)
class ModuleFilter {
  final String? scope;
  final String? ignore;
  final String? diff;
  final String? dependsOn;
  final String? noDependsOn;
  final bool? enabled;
  final bool? disabled;
  final int? priority;
  final bool includeDependencies;
  final bool includeDependents;

  const ModuleFilter({
    this.scope,
    this.ignore,
    this.diff,
    this.dependsOn,
    this.noDependsOn,
    this.enabled,
    this.disabled,
    this.priority,
    this.includeDependencies = false,
    this.includeDependents = false,
  });

  /// Apply filter to list of modules
  List<Module> apply(List<Module> modules) {
    var filtered = List<Module>.from(modules);

    // Scope filter (glob pattern matching)
    if (scope != null) {
      filtered = filtered.where((module) {
        return _matchesGlob(module.name, scope!) ||
            _matchesGlob(module.alias, scope!);
      }).toList();
    }

    // Ignore filter
    if (ignore != null) {
      filtered = filtered.where((module) {
        return !_matchesGlob(module.name, ignore!) &&
            !_matchesGlob(module.alias, ignore!);
      }).toList();
    }

    // Enabled/Disabled filter
    if (enabled == true) {
      filtered = filtered.where((m) => m.enabled).toList();
    } else if (disabled == true) {
      filtered = filtered.where((m) => !m.enabled).toList();
    }

    // Priority filter
    if (priority != null) {
      filtered = filtered.where((m) => m.priority == priority).toList();
    }

    // Depends on filter
    if (dependsOn != null) {
      filtered = filtered.where((module) {
        return module.requires.contains(dependsOn!);
      }).toList();
    }

    // No depends on filter
    if (noDependsOn != null) {
      filtered = filtered.where((module) {
        return !module.requires.contains(noDependsOn!);
      }).toList();
    }

    // Include dependencies
    if (includeDependencies) {
      final additional = <Module>[];
      for (final module in filtered) {
        for (final dep in module.requires) {
          final depModule = modules.firstWhere(
            (m) => m.name.toLowerCase() == dep.toLowerCase(),
            orElse: () => module,
          );
          if (depModule != module && !filtered.contains(depModule)) {
            additional.add(depModule);
          }
        }
      }
      filtered.addAll(additional);
    }

    // Include dependents
    if (includeDependents) {
      final additional = <Module>[];
      for (final module in filtered) {
        final dependents = modules.where((m) => m.requires
            .any((r) => r.toLowerCase() == module.name.toLowerCase()));
        for (final dependent in dependents) {
          if (!filtered.contains(dependent)) {
            additional.add(dependent);
          }
        }
      }
      filtered.addAll(additional);
    }

    // Diff filter (modules changed since git ref)
    if (diff != null) {
      filtered = _filterByDiff(filtered, diff!);
    }

    return filtered;
  }

  /// Simple glob pattern matching
  bool _matchesGlob(String text, String pattern) {
    // Convert glob to regex
    final regexPattern = pattern
        .replaceAll('*', '.*')
        .replaceAll('?', '.')
        .replaceAll('.', r'\.');
    final regex = RegExp('^$regexPattern\$', caseSensitive: false);
    return regex.hasMatch(text);
  }

  /// Filter modules changed since git ref
  List<Module> _filterByDiff(List<Module> modules, String ref) {
    try {
      final result = Process.runSync(
        'git',
        ['diff', '--name-only', ref],
        runInShell: true,
      );

      if (result.exitCode != 0) {
        return modules; // If git fails, return all
      }

      final changedFiles = result.stdout.toString().split('\n');
      final changedModules = <Module>[];

      for (final module in modules) {
        final modulePath = path.relative(module.modulePath);
        final hasChanges = changedFiles.any(
            (file) => file.startsWith(modulePath) || file.contains(modulePath));
        if (hasChanges) {
          changedModules.add(module);
        }
      }

      return changedModules;
    } catch (e) {
      // If git is not available, return all modules
      return modules;
    }
  }
}
