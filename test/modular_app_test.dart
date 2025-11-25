import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:modular_flutter/modular_flutter.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  group('ModularApp', () {
    test('ModularApp can be instantiated', () {
      // Test that ModularApp can be created without errors
      final app = ModularApp(
        title: 'Test App',
        config: ModularAppConfig(
          autoBuildRoutes: false,
          autoRegisterProviders: false,
        ),
      );
      expect(app, isNotNull);
    });

    test('ModularApp exposes static registry getters', () {
      // These are set during initialization
      // They may be null if no ModularApp has been initialized,
      // or they may have values from a previous test run
      // We just verify the getters exist and return the correct types
      final registry = ModularApp.registry;
      final menus = ModularApp.menus;
      final localizations = ModularApp.localizations;

      // Getters should exist (not throw)
      expect(registry, anyOf(isNull, isA<ModuleRegistry>()));
      expect(menus, anyOf(isNull, isA<MenuRegistry>()));
      expect(localizations, anyOf(isNull, isA<LocalizationRegistry>()));
    });

    test('ModularAppConfig can be created with defaults', () {
      final config = ModularAppConfig.defaults();
      expect(config.autoDiscoverModules, isTrue);
      expect(config.autoRegisterProviders, isTrue);
      expect(config.autoBuildRoutes, isTrue);
    });

    test('ModularAppConfig can filter modules', () {
      final config = ModularAppConfig.enabledOnly();
      expect(config.shouldLoadModule, isNotNull);

      final enabledModule = Module(
        name: 'Enabled',
        alias: 'enabled',
        modulePath: '/test',
        metadata: {},
        enabled: true,
      );

      final disabledModule = Module(
        name: 'Disabled',
        alias: 'disabled',
        modulePath: '/test',
        metadata: {},
        enabled: false,
      );

      expect(config.shouldLoadModule!(enabledModule), isTrue);
      expect(config.shouldLoadModule!(disabledModule), isFalse);
    });

    test('ModularAppConfig can use custom filter', () {
      final config = ModularAppConfig.custom(
        filter: (module) => module.name == 'TestModule',
      );

      final testModule = Module(
        name: 'TestModule',
        alias: 'test_module',
        modulePath: '/test',
        metadata: {},
      );

      final otherModule = Module(
        name: 'OtherModule',
        alias: 'other_module',
        modulePath: '/test',
        metadata: {},
      );

      expect(config.shouldLoadModule!(testModule), isTrue);
      expect(config.shouldLoadModule!(otherModule), isFalse);
    });
  });
}
