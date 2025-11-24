import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  group('ModuleRepository', () {
    late String testModulesPath;
    late ModuleRepository repository;

    setUp(() {
      testModulesPath = path.join(Directory.systemTemp.path,
          'test_modules_${DateTime.now().millisecondsSinceEpoch}');
      repository = ModuleRepository(modulesPath: testModulesPath);
    });

    tearDown(() {
      // Clean up test directory
      try {
        Directory(testModulesPath).deleteSync(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('returns empty list when modules directory does not exist', () {
      final modules = repository.scan();
      expect(modules, isEmpty);
    });

    test('can count modules', () {
      expect(repository.count(), equals(0));
    });

    test('can check if module exists', () {
      expect(repository.has('NonExistent'), isFalse);
    });
  });
}
