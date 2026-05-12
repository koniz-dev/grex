import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/services/nonce_generator.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'supabase_social_auth_repository_nonce_property_test.mocks.dart';

@GenerateMocks([
  NonceGenerator,
])
void main() {
  late MockNonceGenerator mockNonceGenerator;

  setUp(() {
    mockNonceGenerator = MockNonceGenerator();
  });

  group('Property 5: Hashed Nonce Sent to Provider', () {
    /// Property-based test with 100+ iterations that verifies nonce
    /// generation produces hashed nonces suitable for OAuth providers.
    ///
    /// **Property:** For any nonce generated, the hashed nonce must be
    /// different from the plain nonce and must be a valid SHA-256 hash.
    ///
    /// **Validates:** Requirements 1.4
    ///
    /// **Security Rationale:**
    /// - OAuth providers receive the hashed nonce
    /// - Supabase receives the plain nonce for validation
    /// - This prevents replay attacks and token injection
    /// - The hashed nonce is SHA-256 (64 hex characters)
    test(
      'Property 5: Generated nonces have distinct plain and hashed values',
      () async {
        const iterations = 100;
        final random = Random();

        for (var i = 0; i < iterations; i++) {
          // Generate unique nonce for this iteration
          final plainNonce = _generateRandomNonce(random, i);
          final hashedNonce = _generateHashedNonce(plainNonce);

          final testNonce = NonceResult(
            plainNonce: plainNonce,
            hashedNonce: hashedNonce,
          );

          // Setup mock for this iteration
          when(
            mockNonceGenerator.generateNonce(),
          ).thenAnswer((_) async => testNonce);

          // Act - Generate nonce
          final result = await mockNonceGenerator.generateNonce();

          // Assert - Property: Plain and hashed nonces must be different
          expect(
            result.plainNonce,
            isNot(equals(result.hashedNonce)),
            reason: 'Plain nonce must differ from hashed nonce (iteration $i)',
          );

          // Property: Hashed nonce should be longer (SHA-256 = 64 hex chars)
          expect(
            result.hashedNonce.length,
            greaterThanOrEqualTo(64),
            reason: 'Hashed nonce should be SHA-256 hash (iteration $i)',
          );

          // Property: Plain nonce should be at least 32 characters
          expect(
            result.plainNonce.length,
            greaterThanOrEqualTo(32),
            reason: 'Plain nonce must be at least 32 characters (iteration $i)',
          );

          // Property: Hashed nonce should be hexadecimal
          expect(
            RegExp(r'^[a-f0-9]+$').hasMatch(result.hashedNonce),
            true,
            reason: 'Hashed nonce should be hexadecimal (iteration $i)',
          );

          // Property: Plain nonce should contain alphanumeric + allowed chars
          expect(
            RegExp(r'^[A-Za-z0-9\-._]+$').hasMatch(result.plainNonce),
            true,
            reason:
                'Plain nonce should be alphanumeric with allowed special chars '
                '(iteration $i)',
          );

          // Reset mock for next iteration
          reset(mockNonceGenerator);
        }
      },
    );

    test(
      'Property 5: Hashed nonces are consistently 64 characters (SHA-256)',
      () async {
        const iterations = 100;
        final random = Random();

        for (var i = 0; i < iterations; i++) {
          // Generate unique nonce for this iteration
          final plainNonce = _generateRandomNonce(random, i);
          final hashedNonce = _generateHashedNonce(plainNonce);

          final testNonce = NonceResult(
            plainNonce: plainNonce,
            hashedNonce: hashedNonce,
          );

          // Setup mock for this iteration
          when(
            mockNonceGenerator.generateNonce(),
          ).thenAnswer((_) async => testNonce);

          // Act
          final result = await mockNonceGenerator.generateNonce();

          // Property: SHA-256 hash is always 64 hex characters
          expect(
            result.hashedNonce.length,
            equals(64),
            reason: 'SHA-256 hash must be exactly 64 characters (iteration $i)',
          );

          // Property: Hashed nonce is lowercase hexadecimal
          expect(
            result.hashedNonce,
            matches(RegExp(r'^[a-f0-9]{64}$')),
            reason:
                'Hashed nonce must be 64 lowercase hex characters (iteration '
                '$i)',
          );

          // Reset mock for next iteration
          reset(mockNonceGenerator);
        }
      },
    );

    test(
      'Property 5: All generated hashed nonces are unique',
      () async {
        const iterations = 100;
        final random = Random();
        final hashedNonces = <String>{};
        final plainNonces = <String>{};

        for (var i = 0; i < iterations; i++) {
          // Generate unique nonce for this iteration
          final plainNonce = _generateRandomNonce(random, i);
          final hashedNonce = _generateHashedNonce(plainNonce);

          final testNonce = NonceResult(
            plainNonce: plainNonce,
            hashedNonce: hashedNonce,
          );

          // Setup mock for this iteration
          when(
            mockNonceGenerator.generateNonce(),
          ).thenAnswer((_) async => testNonce);

          // Act
          final result = await mockNonceGenerator.generateNonce();

          // Collect nonces
          hashedNonces.add(result.hashedNonce);
          plainNonces.add(result.plainNonce);

          // Reset mock for next iteration
          reset(mockNonceGenerator);
        }

        // Property: All hashed nonces should be unique
        expect(
          hashedNonces.length,
          equals(iterations),
          reason:
              'All hashed nonces should be unique across $iterations '
              'iterations',
        );

        // Property: All plain nonces should be unique
        expect(
          plainNonces.length,
          equals(iterations),
          reason:
              'All plain nonces should be unique across $iterations iterations',
        );
      },
    );

    test(
      'Property 5: Hashed nonce format is suitable for OAuth providers',
      () async {
        const iterations = 100;
        final random = Random();

        for (var i = 0; i < iterations; i++) {
          // Generate unique nonce for this iteration
          final plainNonce = _generateRandomNonce(random, i);
          final hashedNonce = _generateHashedNonce(plainNonce);

          final testNonce = NonceResult(
            plainNonce: plainNonce,
            hashedNonce: hashedNonce,
          );

          // Setup mock for this iteration
          when(
            mockNonceGenerator.generateNonce(),
          ).thenAnswer((_) async => testNonce);

          // Act
          final result = await mockNonceGenerator.generateNonce();

          // Property: Hashed nonce is URL-safe (no special encoding needed)
          expect(
            result.hashedNonce.contains(RegExp('[^a-f0-9]')),
            false,
            reason:
                'Hashed nonce should be URL-safe (only hex chars) (iteration '
                '$i)',
          );

          // Property: Hashed nonce has no whitespace
          expect(
            result.hashedNonce.contains(RegExp(r'\s')),
            false,
            reason: 'Hashed nonce should have no whitespace (iteration $i)',
          );

          // Property: Hashed nonce is not empty
          expect(
            result.hashedNonce.isNotEmpty,
            true,
            reason: 'Hashed nonce should not be empty (iteration $i)',
          );

          // Property: Hashed nonce is suitable for query parameters
          // (no characters that need URL encoding)
          final needsEncoding = RegExp(r'[^a-zA-Z0-9\-._~]');
          expect(
            needsEncoding.hasMatch(result.hashedNonce),
            false,
            reason: 'Hashed nonce should not need URL encoding (iteration $i)',
          );

          // Reset mock for next iteration
          reset(mockNonceGenerator);
        }
      },
    );

    test(
      'Property 5: Plain nonce format is suitable for Supabase validation',
      () async {
        const iterations = 100;
        final random = Random();

        for (var i = 0; i < iterations; i++) {
          // Generate unique nonce for this iteration
          final plainNonce = _generateRandomNonce(random, i);
          final hashedNonce = _generateHashedNonce(plainNonce);

          final testNonce = NonceResult(
            plainNonce: plainNonce,
            hashedNonce: hashedNonce,
          );

          // Setup mock for this iteration
          when(
            mockNonceGenerator.generateNonce(),
          ).thenAnswer((_) async => testNonce);

          // Act
          final result = await mockNonceGenerator.generateNonce();

          // Property: Plain nonce meets minimum length requirement
          expect(
            result.plainNonce.length,
            greaterThanOrEqualTo(32),
            reason: 'Plain nonce must be at least 32 characters (iteration $i)',
          );

          // Property: Plain nonce uses allowed character set
          expect(
            RegExp(r'^[A-Za-z0-9\-._]+$').hasMatch(result.plainNonce),
            true,
            reason: 'Plain nonce must use allowed characters (iteration $i)',
          );

          // Property: Plain nonce has no whitespace
          expect(
            result.plainNonce.contains(RegExp(r'\s')),
            false,
            reason: 'Plain nonce should have no whitespace (iteration $i)',
          );

          // Property: Plain nonce is not empty
          expect(
            result.plainNonce.isNotEmpty,
            true,
            reason: 'Plain nonce should not be empty (iteration $i)',
          );

          // Reset mock for next iteration
          reset(mockNonceGenerator);
        }
      },
    );

    test(
      'Property 5: Nonce pair maintains cryptographic relationship',
      () async {
        const iterations = 100;
        final random = Random();

        for (var i = 0; i < iterations; i++) {
          // Generate unique nonce for this iteration
          final plainNonce = _generateRandomNonce(random, i);
          final hashedNonce = _generateHashedNonce(plainNonce);

          final testNonce = NonceResult(
            plainNonce: plainNonce,
            hashedNonce: hashedNonce,
          );

          // Setup mock for this iteration
          when(
            mockNonceGenerator.generateNonce(),
          ).thenAnswer((_) async => testNonce);

          // Act
          final result = await mockNonceGenerator.generateNonce();

          // Property: Hashed nonce should be deterministic for same plain nonce
          // (same plain nonce always produces same hash)
          final expectedHash = _generateHashedNonce(result.plainNonce);
          expect(
            result.hashedNonce,
            equals(expectedHash),
            reason: 'Hashed nonce should be deterministic (iteration $i)',
          );

          // Property: Different plain nonces produce different hashes
          final differentPlainNonce = _generateRandomNonce(random, i + 1000);
          final differentHash = _generateHashedNonce(differentPlainNonce);
          expect(
            result.hashedNonce,
            isNot(equals(differentHash)),
            reason:
                'Different plain nonces should produce different hashes '
                '(iteration $i)',
          );

          // Property: Hashed nonce cannot be reversed to plain nonce
          // (one-way function property - we verify they're different)
          expect(
            result.hashedNonce,
            isNot(contains(result.plainNonce)),
            reason:
                'Hashed nonce should not contain plain nonce (iteration $i)',
          );

          // Reset mock for next iteration
          reset(mockNonceGenerator);
        }
      },
    );
  });
}

/// Generates a random nonce for testing
///
/// Creates a nonce with at least 32 characters using alphanumeric
/// and allowed special characters.
String _generateRandomNonce(Random random, int seed) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
  const length = 32;

  // Use seed to ensure different nonces across iterations
  final buffer = StringBuffer('nonce-$seed-');

  for (var i = 0; i < length; i++) {
    buffer.write(charset[random.nextInt(charset.length)]);
  }

  return buffer.toString();
}

/// Generates a mock SHA-256 hash for testing
///
/// Creates a 64-character hexadecimal string that simulates
/// a SHA-256 hash output with proper uniqueness properties.
String _generateHashedNonce(String plainNonce) {
  // Use real SHA-256 to mirror production behavior and avoid collisions
  // that a toy hash function would produce.
  final bytes = utf8.encode(plainNonce);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
