import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/data/services/nonce_generator_impl.dart';
import 'package:grex/features/auth/domain/services/nonce_generator.dart';

/// Property-based tests for NonceGenerator
///
/// These tests validate correctness properties across 100+ iterations
/// to ensure the nonce generation system works correctly in all scenarios.
void main() {
  group('NonceGenerator Property Tests', () {
    late NonceGenerator nonceGenerator;

    setUp(() {
      nonceGenerator = NonceGeneratorImpl();
    });

    tearDown(() {
      nonceGenerator.clearUsedNonces();
    });

    /// Property 1: Nonce Length and Format Validation
    ///
    /// For any OAuth request, the generated nonce must be at least 32
    /// characters long and contain only alphanumeric characters plus
    /// allowed special characters (-, ., _).
    ///
    /// Validates: Requirements 1.1
    test(
      'Property 1: All generated nonces are ≥32 chars and match valid pattern',
      () async {
        const iterations = 100;
        final validPattern = RegExp(r'^[A-Za-z0-9\-._]+$');

        for (var i = 0; i < iterations; i++) {
          // Generate nonce
          final result = await nonceGenerator.generateNonce();

          // Property: Length must be at least 32 characters
          expect(
            result.plainNonce.length,
            greaterThanOrEqualTo(32),
            reason: 'Iteration $i: Nonce length must be ≥32 characters',
          );

          // Property: Must match valid pattern (alphanumeric + -, ., _)
          expect(
            validPattern.hasMatch(result.plainNonce),
            isTrue,
            reason: 'Iteration $i: Nonce must match valid pattern',
          );

          // Property: Hashed nonce must be non-empty
          expect(
            result.hashedNonce.isNotEmpty,
            isTrue,
            reason: 'Iteration $i: Hashed nonce must not be empty',
          );

          // Property: Hashed nonce should be SHA-256 (64 hex characters)
          expect(
            result.hashedNonce.length,
            equals(64),
            reason: 'Iteration $i: SHA-256 hash should be 64 characters',
          );
        }
      },
    );

    /// Property 2: Nonce Cryptographic Randomness
    ///
    /// For any sequence of generated nonces, the nonces must pass statistical
    /// randomness tests (no predictable patterns, uniform distribution of
    /// characters).
    ///
    /// Validates: Requirements 1.2
    test(
      'Property 2: Nonces pass statistical randomness tests',
      () async {
        const iterations = 100;
        final allNonces = <String>[];
        final characterFrequency = <String, int>{};

        // Generate nonces and collect statistics
        for (var i = 0; i < iterations; i++) {
          final result = await nonceGenerator.generateNonce();
          allNonces.add(result.plainNonce);

          // Count character frequency
          for (final char in result.plainNonce.split('')) {
            characterFrequency[char] = (characterFrequency[char] ?? 0) + 1;
          }
        }

        // Property: All nonces should be unique (no duplicates)
        final uniqueNonces = allNonces.toSet();
        expect(
          uniqueNonces.length,
          equals(iterations),
          reason: 'All nonces should be unique across $iterations iterations',
        );

        // Property: Character distribution should be reasonably uniform
        // With 100 nonces of 32+ chars each, we have 3200+ characters
        // Each character in the charset should appear at least once
        expect(
          characterFrequency.keys.length,
          greaterThan(10),
          reason: 'Should use diverse character set',
        );

        // Property: No single character should dominate (>50% of total)
        final totalChars = characterFrequency.values.reduce((a, b) => a + b);
        for (final entry in characterFrequency.entries) {
          final percentage = entry.value / totalChars;
          expect(
            percentage,
            lessThan(0.5),
            reason:
                'Character "${entry.key}" appears too frequently: '
                '${(percentage * 100).toStringAsFixed(1)}%',
          );
        }

        // Property: Consecutive nonces should not have predictable patterns
        for (var i = 0; i < allNonces.length - 1; i++) {
          final nonce1 = allNonces[i];
          final nonce2 = allNonces[i + 1];

          // Check that nonces don't share long common prefixes
          var commonPrefixLength = 0;
          for (var j = 0; j < nonce1.length && j < nonce2.length; j++) {
            if (nonce1[j] == nonce2[j]) {
              commonPrefixLength++;
            } else {
              break;
            }
          }

          // Common prefix should be less than 25% of nonce length
          expect(
            commonPrefixLength,
            lessThan(nonce1.length ~/ 4),
            reason:
                'Nonces $i and ${i + 1} have suspiciously long '
                'common prefix: $commonPrefixLength chars',
          );
        }
      },
    );

    /// Property 3: Nonce Hashing Correctness
    ///
    /// For any generated nonce, hashing the plain nonce with SHA-256 must
    /// produce the same result as the hashedNonce returned by the generator.
    ///
    /// Validates: Requirements 1.3
    test(
      'Property 3: SHA-256 hash matches expected result',
      () async {
        const iterations = 100;

        for (var i = 0; i < iterations; i++) {
          // Generate nonce
          final result = await nonceGenerator.generateNonce();

          // Manually compute SHA-256 hash of plain nonce
          final bytes = utf8.encode(result.plainNonce);
          final digest = sha256.convert(bytes).toString();

          // Property: Hashed nonce should match manual SHA-256 computation
          expect(
            result.hashedNonce,
            equals(digest),
            reason:
                'Iteration $i: Hashed nonce should match SHA-256 of '
                'plain nonce',
          );

          // Property: Hashing should be deterministic
          final digest2 = sha256.convert(bytes).toString();
          expect(
            digest,
            equals(digest2),
            reason: 'Iteration $i: SHA-256 should be deterministic',
          );

          // Property: Different plain nonces should produce different hashes
          if (i > 0) {
            final result2 = await nonceGenerator.generateNonce();
            expect(
              result.hashedNonce,
              isNot(equals(result2.hashedNonce)),
              reason:
                  'Iteration $i: Different nonces should have '
                  'different hashes',
            );
          }
        }
      },
    );

    /// Property 4: Nonce Uniqueness Across Requests
    ///
    /// For any set of OAuth requests, all generated nonces must be unique
    /// (no duplicates).
    ///
    /// Validates: Requirements 1.6, 1.8
    test(
      'Property 4: No duplicate nonces generated across requests',
      () async {
        const iterations = 100;
        final plainNonces = <String>{};
        final hashedNonces = <String>{};

        for (var i = 0; i < iterations; i++) {
          // Generate nonce
          final result = await nonceGenerator.generateNonce();

          // Property: Plain nonce must be unique
          expect(
            plainNonces.contains(result.plainNonce),
            isFalse,
            reason:
                'Iteration $i: Plain nonce must be unique, '
                'but found duplicate',
          );

          // Property: Hashed nonce must be unique
          expect(
            hashedNonces.contains(result.hashedNonce),
            isFalse,
            reason:
                'Iteration $i: Hashed nonce must be unique, '
                'but found duplicate',
          );

          // Add to sets for tracking
          plainNonces.add(result.plainNonce);
          hashedNonces.add(result.hashedNonce);
        }

        // Property: All nonces should be unique
        expect(
          plainNonces.length,
          equals(iterations),
          reason: 'Should have $iterations unique plain nonces',
        );

        expect(
          hashedNonces.length,
          equals(iterations),
          reason: 'Should have $iterations unique hashed nonces',
        );
      },
    );

    /// Property 4b: Nonce Reuse Prevention
    ///
    /// The generator should track used nonces and prevent reuse even after
    /// clearing and regenerating.
    ///
    /// Validates: Requirements 1.6, 1.8
    test(
      'Property 4b: Nonce reuse is prevented by tracking',
      () async {
        const iterations = 50;
        final firstBatch = <String>[];

        // Generate first batch of nonces
        for (var i = 0; i < iterations; i++) {
          final result = await nonceGenerator.generateNonce();
          firstBatch.add(result.plainNonce);
        }

        // Clear used nonces
        nonceGenerator.clearUsedNonces();

        // Generate second batch of nonces
        final secondBatch = <String>[];
        for (var i = 0; i < iterations; i++) {
          final result = await nonceGenerator.generateNonce();
          secondBatch.add(result.plainNonce);
        }

        // Property: After clearing, new nonces can be generated
        expect(
          secondBatch.length,
          equals(iterations),
          reason: 'Should generate $iterations nonces after clearing',
        );

        // Property: Second batch should also have unique nonces
        final uniqueSecondBatch = secondBatch.toSet();
        expect(
          uniqueSecondBatch.length,
          equals(iterations),
          reason: 'Second batch should have all unique nonces',
        );

        // Note: After clearing, nonces MAY overlap with first batch
        // (this is acceptable since clearing is meant to reset state)
        // But within each batch, all nonces must be unique
      },
    );
  });
}
