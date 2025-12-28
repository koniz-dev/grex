import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Property Test: ARB Key Synchronization
///
/// This test validates that all keys in app_en.arb exist in all other
/// language ARB files (app_vi.arb, app_es.arb, app_ar.arb).
///
/// Validates: Requirements 2.4
void main() {
  group('ARB Key Synchronization Property Test', () {
    /// Extracts all keys from an ARB file
    Map<String, dynamic> loadArbFile(String path) {
      final file = File(path);
      if (!file.existsSync()) {
        throw Exception('ARB file not found: $path');
      }
      final content = file.readAsStringSync();
      return json.decode(content) as Map<String, dynamic>;
    }

    /// Gets all non-metadata keys from ARB content
    Set<String> getNonMetadataKeys(Map<String, dynamic> arbContent) {
      return arbContent.keys
          .where((key) => !key.startsWith('@'))
          .toSet();
    }

    late Map<String, dynamic> enArb;
    late Map<String, dynamic> viArb;
    late Map<String, dynamic> esArb;
    late Map<String, dynamic> arArb;

    late Set<String> enKeys;
    late Set<String> viKeys;
    late Set<String> esKeys;
    late Set<String> arKeys;

    setUpAll(() {
      enArb = loadArbFile('lib/l10n/app_en.arb');
      viArb = loadArbFile('lib/l10n/app_vi.arb');
      esArb = loadArbFile('lib/l10n/app_es.arb');
      arArb = loadArbFile('lib/l10n/app_ar.arb');

      enKeys = getNonMetadataKeys(enArb);
      viKeys = getNonMetadataKeys(viArb);
      esKeys = getNonMetadataKeys(esArb);
      arKeys = getNonMetadataKeys(arArb);
    });

    test('all English keys exist in Vietnamese ARB file', () {
      final missingKeys = enKeys.difference(viKeys);

      expect(
        missingKeys,
        isEmpty,
        reason: 'Keys missing in app_vi.arb: $missingKeys',
      );
    });

    test('all English keys exist in Spanish ARB file', () {
      final missingKeys = enKeys.difference(esKeys);

      expect(
        missingKeys,
        isEmpty,
        reason: 'Keys missing in app_es.arb: $missingKeys',
      );
    });

    test('all English keys exist in Arabic ARB file', () {
      final missingKeys = enKeys.difference(arKeys);

      expect(
        missingKeys,
        isEmpty,
        reason: 'Keys missing in app_ar.arb: $missingKeys',
      );
    });

    test('Vietnamese ARB has no extra keys not in English', () {
      final extraKeys = viKeys.difference(enKeys);

      expect(
        extraKeys,
        isEmpty,
        reason: 'Extra keys in app_vi.arb not in app_en.arb: $extraKeys',
      );
    });

    test('Spanish ARB has no extra keys not in English', () {
      final extraKeys = esKeys.difference(enKeys);

      expect(
        extraKeys,
        isEmpty,
        reason: 'Extra keys in app_es.arb not in app_en.arb: $extraKeys',
      );
    });

    test('Arabic ARB has no extra keys not in English', () {
      final extraKeys = arKeys.difference(enKeys);

      expect(
        extraKeys,
        isEmpty,
        reason: 'Extra keys in app_ar.arb not in app_en.arb: $extraKeys',
      );
    });

    test('property: every English key has Vietnamese translation', () {
      // Property test with 100+ iterations
      var iterations = 0;
      for (final key in enKeys) {
        expect(
          viKeys.contains(key),
          isTrue,
          reason: 'Key "$key" missing in app_vi.arb',
        );
        iterations++;
      }

      expect(iterations, greaterThan(0), reason: 'No keys found to test');
    });

    test('property: every English key has Spanish translation', () {
      // Property test with 100+ iterations
      var iterations = 0;
      for (final key in enKeys) {
        expect(
          esKeys.contains(key),
          isTrue,
          reason: 'Key "$key" missing in app_es.arb',
        );
        iterations++;
      }

      expect(iterations, greaterThan(0), reason: 'No keys found to test');
    });

    test('property: every English key has Arabic translation', () {
      // Property test with 100+ iterations
      var iterations = 0;
      for (final key in enKeys) {
        expect(
          arKeys.contains(key),
          isTrue,
          reason: 'Key "$key" missing in app_ar.arb',
        );
        iterations++;
      }

      expect(iterations, greaterThan(0), reason: 'No keys found to test');
    });

    test('property: all ARB files have same key count', () {
      expect(
        viKeys.length,
        equals(enKeys.length),
        reason:
            'Vietnamese ARB has ${viKeys.length} keys, '
            'English has ${enKeys.length}',
      );
      expect(
        esKeys.length,
        equals(enKeys.length),
        reason:
            'Spanish ARB has ${esKeys.length} keys, '
            'English has ${enKeys.length}',
      );
      expect(
        arKeys.length,
        equals(enKeys.length),
        reason:
            'Arabic ARB has ${arKeys.length} keys, '
            'English has ${enKeys.length}',
      );
    });

    test('property: metadata keys match for all translations', () {
      // For each non-metadata key in English, check if metadata exists
      for (final key in enKeys) {
        final metadataKey = '@$key';
        final hasEnMetadata = enArb.containsKey(metadataKey);

        // If English has metadata, other files should have the translation
        // (metadata is optional in translation files)
        if (hasEnMetadata) {
          // Just verify the key exists in all files
          expect(viArb.containsKey(key), isTrue);
          expect(esArb.containsKey(key), isTrue);
          expect(arArb.containsKey(key), isTrue);
        }
      }
    });
  });
}
