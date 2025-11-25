import 'package:flutter_test/flutter_test.dart';
import 'package:modular_flutter/modular_flutter.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  group('MenuRegistry', () {
    late MenuRegistry menuRegistry;
    late Module testModule;

    setUp(() {
      menuRegistry = MenuRegistry();
      
      // Create a test module with menus
      testModule = Module(
        name: 'TestModule',
        alias: 'test_module',
        modulePath: '/tmp/test_module',
        metadata: {},
        menus: {
          'primary': [
            {
              'title': 'Home',
              'url': '/home',
              'icon': 'home',
              'order': 1,
            },
            {
              'title': 'About',
              'url': '/about',
              'icon': 'info',
              'order': 2,
            },
          ],
          'settings': [
            {
              'title': 'Settings',
              'url': '/settings',
              'icon': 'settings',
              'order': 1,
            },
          ],
        },
      );
    });

    test('starts with no menus', () {
      expect(menuRegistry.getAllMenus(), isEmpty);
      expect(menuRegistry.getMenus('primary'), isEmpty);
    });

    test('can register menus from module', () {
      menuRegistry.registerModuleMenus(testModule);

      final primaryMenus = menuRegistry.getMenus('primary');
      expect(primaryMenus.length, equals(2));
      expect(primaryMenus[0]['title'], equals('Home'));
      expect(primaryMenus[0]['url'], equals('/home'));
      expect(primaryMenus[0]['module'], equals('test_module'));
      expect(primaryMenus[1]['title'], equals('About'));
      expect(primaryMenus[1]['url'], equals('/about'));
    });

    test('can register menus from multiple modules', () {
      final module2 = Module(
        name: 'AnotherModule',
        alias: 'another_module',
        modulePath: '/tmp/another_module',
        metadata: {},
        menus: {
          'primary': [
            {
              'title': 'Contact',
              'url': '/contact',
              'icon': 'mail',
              'order': 3,
            },
          ],
        },
      );

      menuRegistry.registerModuleMenus(testModule);
      menuRegistry.registerModuleMenus(module2);

      final primaryMenus = menuRegistry.getMenus('primary');
      expect(primaryMenus.length, equals(3));
      expect(primaryMenus[0]['title'], equals('Home'));
      expect(primaryMenus[1]['title'], equals('About'));
      expect(primaryMenus[2]['title'], equals('Contact'));
      expect(primaryMenus[2]['module'], equals('another_module'));
    });

    test('can get menus for specific group', () {
      menuRegistry.registerModuleMenus(testModule);

      final primaryMenus = menuRegistry.getMenus('primary');
      final settingsMenus = menuRegistry.getMenus('settings');

      expect(primaryMenus.length, equals(2));
      expect(settingsMenus.length, equals(1));
      expect(settingsMenus[0]['title'], equals('Settings'));
    });

    test('returns empty list for non-existent menu group', () {
      menuRegistry.registerModuleMenus(testModule);

      final footerMenus = menuRegistry.getMenus('footer');
      expect(footerMenus, isEmpty);
    });

    test('can get all menus', () {
      menuRegistry.registerModuleMenus(testModule);

      final allMenus = menuRegistry.getAllMenus();
      expect(allMenus.keys.length, equals(2));
      expect(allMenus.containsKey('primary'), isTrue);
      expect(allMenus.containsKey('settings'), isTrue);
    });

    test('handles module with no menus', () {
      final moduleWithoutMenus = Module(
        name: 'NoMenuModule',
        alias: 'no_menu_module',
        modulePath: '/tmp/no_menu_module',
        metadata: {},
        menus: {},
      );

      menuRegistry.registerModuleMenus(moduleWithoutMenus);
      expect(menuRegistry.getAllMenus(), isEmpty);
    });
  });
}

