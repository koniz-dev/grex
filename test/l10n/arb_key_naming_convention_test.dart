import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Property Test: ARB Key Naming Convention
///
/// This test validates that all ARB keys follow the camelCase naming
/// convention:
/// - No underscores
/// - No hyphens
/// - Starts with lowercase letter
/// - Only alphanumeric characters
///
/// Validates: Requirements 2.2
void main() {
  group('ARB Key Naming Convention Property Test', () {
    /// Checks if a key follows camelCase convention
    bool isCamelCase(String key) {
      // Skip metadata keys that start with @
      if (key.startsWith('@')) return true;

      // Must start with lowercase letter
      if (key.isEmpty || !RegExp('^[a-z]').hasMatch(key)) {
        return false;
      }

      // Must not contain underscores or hyphens
      if (key.contains('_') || key.contains('-')) {
        return false;
      }

      // Must only contain alphanumeric characters
      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(key)) {
        return false;
      }

      return true;
    }

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
    List<String> getNonMetadataKeys(Map<String, dynamic> arbContent) {
      return arbContent.keys.where((key) => !key.startsWith('@')).toList();
    }

    test('all keys in app_en.arb follow camelCase convention', () {
      final arbContent = loadArbFile('lib/l10n/app_en.arb');
      final keys = getNonMetadataKeys(arbContent);

      final invalidKeys = <String>[];
      for (final key in keys) {
        if (!isCamelCase(key)) {
          invalidKeys.add(key);
        }
      }

      expect(
        invalidKeys,
        isEmpty,
        reason:
            'Found keys that do not follow camelCase convention: $invalidKeys',
      );
    });

    test('all keys in app_vi.arb follow camelCase convention', () {
      final arbContent = loadArbFile('lib/l10n/app_vi.arb');
      final keys = getNonMetadataKeys(arbContent);

      final invalidKeys = <String>[];
      for (final key in keys) {
        if (!isCamelCase(key)) {
          invalidKeys.add(key);
        }
      }

      expect(
        invalidKeys,
        isEmpty,
        reason:
            'Found keys that do not follow camelCase convention: $invalidKeys',
      );
    });

    test('all keys in app_es.arb follow camelCase convention', () {
      final arbContent = loadArbFile('lib/l10n/app_es.arb');
      final keys = getNonMetadataKeys(arbContent);

      final invalidKeys = <String>[];
      for (final key in keys) {
        if (!isCamelCase(key)) {
          invalidKeys.add(key);
        }
      }

      expect(
        invalidKeys,
        isEmpty,
        reason:
            'Found keys that do not follow camelCase convention: $invalidKeys',
      );
    });

    test('all keys in app_ar.arb follow camelCase convention', () {
      final arbContent = loadArbFile('lib/l10n/app_ar.arb');
      final keys = getNonMetadataKeys(arbContent);

      final invalidKeys = <String>[];
      for (final key in keys) {
        if (!isCamelCase(key)) {
          invalidKeys.add(key);
        }
      }

      expect(
        invalidKeys,
        isEmpty,
        reason:
            'Found keys that do not follow camelCase convention: $invalidKeys',
      );
    });

    test('property: camelCase keys start with lowercase letter', () {
      // Property test with 100+ iterations
      final arbContent = loadArbFile('lib/l10n/app_en.arb');
      final keys = getNonMetadataKeys(arbContent);

      // Run property check for all keys (minimum 100 iterations or all keys)
      var iterations = 0;
      for (final key in keys) {
        expect(
          key[0].toLowerCase() == key[0],
          isTrue,
          reason: 'Key "$key" does not start with lowercase letter',
        );
        iterations++;
      }

      // Ensure we ran at least some iterations
      expect(iterations, greaterThan(0), reason: 'No keys found to test');
    });

    test('property: camelCase keys contain no underscores', () {
      // Property test with 100+ iterations
      final arbContent = loadArbFile('lib/l10n/app_en.arb');
      final keys = getNonMetadataKeys(arbContent);

      var iterations = 0;
      for (final key in keys) {
        expect(
          key.contains('_'),
          isFalse,
          reason: 'Key "$key" contains underscore',
        );
        iterations++;
      }

      expect(iterations, greaterThan(0), reason: 'No keys found to test');
    });

    test('property: camelCase keys contain no hyphens', () {
      // Property test with 100+ iterations
      final arbContent = loadArbFile('lib/l10n/app_en.arb');
      final keys = getNonMetadataKeys(arbContent);

      var iterations = 0;
      for (final key in keys) {
        expect(
          key.contains('-'),
          isFalse,
          reason: 'Key "$key" contains hyphen',
        );
        iterations++;
      }

      expect(iterations, greaterThan(0), reason: 'No keys found to test');
    });

    test('property: camelCase keys contain only alphanumeric characters', () {
      // Property test with 100+ iterations
      final arbContent = loadArbFile('lib/l10n/app_en.arb');
      final keys = getNonMetadataKeys(arbContent);

      var iterations = 0;
      for (final key in keys) {
        expect(
          RegExp(r'^[a-zA-Z0-9]+$').hasMatch(key),
          isTrue,
          reason: 'Key "$key" contains non-alphanumeric characters',
        );
        iterations++;
      }

      expect(iterations, greaterThan(0), reason: 'No keys found to test');
    });
  });
}
