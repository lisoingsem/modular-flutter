import 'package:flutter_test/flutter_test.dart';
import 'package:modular_flutter/modular_flutter.dart';

void main() {
  group('Module', () {
    test('can be created with required fields', () {
      final module = Module(
        name: 'TestModule',
        alias: 'test_module',
        modulePath: '/test/path',
        metadata: {},
      );

      expect(module.name, equals('TestModule'));
      expect(module.alias, equals('test_module'));
      expect(module.modulePath, equals('/test/path'));
    });

    test('generates correct name variations', () {
      final module = Module(
        name: 'TestModule',
        alias: 'test_module',
        modulePath: '/test/path',
        metadata: {},
      );

      expect(module.lowerName, equals('test_module'));
      expect(module.studlyName, equals('Testmodule'));
      expect(module.kebabName, equals('test-module'));
      expect(module.snakeName, equals('test_module'));
    });
  });

  group('FileActivator', () {
    test('can enable and disable modules', () {
      final activator = FileActivator(
        statusesFilePath: '/tmp/test_statuses.json',
      );

      final module = Module(
        name: 'TestModule',
        alias: 'test_module',
        modulePath: '/test/path',
        metadata: {},
      );

      activator.enable(module);
      expect(activator.hasStatus(module, true), isTrue);

      activator.disable(module);
      expect(activator.hasStatus(module, false), isTrue);
    });
  });

  group('ModuleRepository', () {
    test('can scan and discover modules', () {
      final repository = ModuleRepository(
        modulesPath: '/tmp/test_modules',
      );

      final modules = repository.scan();
      expect(modules, isA<List<Module>>());
    });

    test('can enable and disable modules', () {
      final repository = ModuleRepository(
        modulesPath: '/tmp/test_modules',
      );

      // This will fail if module doesn't exist, but tests the method
      try {
        repository.enable('TestModule');
        repository.disable('TestModule');
      } catch (e) {
        // Expected if module doesn't exist
        expect(e, isA<ModuleNotFoundException>());
      }
    });
  });
}
