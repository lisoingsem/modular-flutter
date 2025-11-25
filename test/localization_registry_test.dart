import 'package:flutter_test/flutter_test.dart';
import 'package:modular_flutter/modular_flutter.dart';

void main() {
  group('LocalizationRegistry', () {
    late LocalizationRegistry localizationRegistry;

    setUp(() {
      localizationRegistry = LocalizationRegistry();
    });

    test('starts with no localizations', () {
      expect(localizationRegistry.getAllLocalizations(), isEmpty);
      expect(localizationRegistry.translate('test_module', 'key'), isNull);
    });

    test('can translate with module namespace', () {
      // Manually add translations (simulating what happens during registration)
      localizationRegistry.localizations['test_module'] = {
        'welcome': 'Welcome',
        'hello': 'Hello',
      };

      expect(
        localizationRegistry.translate('test_module', 'welcome'),
        equals('Welcome'),
      );
      expect(
        localizationRegistry.translate('test_module', 'hello'),
        equals('Hello'),
      );
    });

    test('can get all translations for a module', () {
      localizationRegistry.localizations['test_module'] = {
        'key1': 'Value1',
        'key2': 'Value2',
      };

      final translations =
          localizationRegistry.getModuleTranslations('test_module');
      expect(translations, isNotNull);
      expect(translations!['key1'], equals('Value1'));
      expect(translations['key2'], equals('Value2'));
    });

    test('can get all localizations', () {
      localizationRegistry.localizations['module1'] = {
        'key1': 'Value1',
      };
      localizationRegistry.localizations['module2'] = {
        'key2': 'Value2',
      };

      final all = localizationRegistry.getAllLocalizations();
      expect(all.keys.length, equals(2));
      expect(all.containsKey('module1'), isTrue);
      expect(all.containsKey('module2'), isTrue);
    });

    test('returns null for non-existent module', () {
      expect(
        localizationRegistry.translate('non_existent', 'key'),
        isNull,
      );
    });

    test('returns null for non-existent key', () {
      localizationRegistry.localizations['test_module'] = {
        'key1': 'Value1',
      };

      expect(
        localizationRegistry.translate('test_module', 'non_existent'),
        isNull,
      );
    });

    test('can refresh localizations', () {
      localizationRegistry.localizations['test_module'] = {
        'key1': 'Value1',
      };

      expect(localizationRegistry.isRegistered, isFalse);

      localizationRegistry.refresh();

      expect(localizationRegistry.isRegistered, isTrue);
    });
  });
}
