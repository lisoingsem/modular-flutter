import 'package:flutter_test/flutter_test.dart';
import 'package:modular_flutter/modular_flutter.dart';

void main() {
  group('RouteRegistry', () {
    late RouteRegistry registry;

    setUp(() {
      registry = RouteRegistry();
    });

    test('starts with no routes', () {
      expect(registry.getAllRoutes(), isEmpty);
    });

    test('can register routes from module', () {
      final module = Module(
        name: 'TestModule',
        alias: 'test_module',
        modulePath: '/test/path',
        metadata: {},
        routes: [
          {
            'path': '/test',
            'widget': 'modules.test.routes.TestRoute',
          },
        ],
      );

      registry.registerModuleRoutes(module);
      expect(registry.getAllRoutes().length, equals(1));
    });

    test('can get route by name', () {
      final module = Module(
        name: 'TestModule',
        alias: 'test_module',
        modulePath: '/test/path',
        metadata: {},
        routes: [
          {
            'path': '/test',
            'widget': 'modules.test.routes.TestRoute',
            'name': 'test',
          },
        ],
      );

      registry.registerModuleRoutes(module);
      final route = registry.getRoute('test');
      expect(route, isNotNull);
      expect(route?.path, equals('/test'));
    });

    test('can check if route exists', () {
      final module = Module(
        name: 'TestModule',
        alias: 'test_module',
        modulePath: '/test/path',
        metadata: {},
        routes: [
          {
            'path': '/test',
            'widget': 'modules.test.routes.TestRoute',
            'name': 'test',
          },
        ],
      );

      registry.registerModuleRoutes(module);
      expect(registry.hasRoute('test'), isTrue);
      expect(registry.hasRoute('nonexistent'), isFalse);
    });
  });
}
