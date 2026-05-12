import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:grex/features/auth/domain/services/nonce_generator.dart';

/// Implementation of [NonceGenerator] using cryptographically secure random
/// number generation and SHA-256 hashing.
///
/// This implementation:
/// - Uses Random.secure() for cryptographic randomness
/// - Generates nonces with alphanumeric and allowed special characters
/// - Hashes nonces using SHA-256 from the crypto package
/// - Tracks used nonces to prevent reuse
/// - Validates nonce format with RegExp
class NonceGeneratorImpl implements NonceGenerator {
  /// Cryptographically secure random number generator
  final Random _random = Random.secure();

  /// Set of used nonces to prevent reuse
  final Set<String> _usedNonces = {};

  /// Character set for nonce generation
  ///
  /// Includes:
  /// - Digits: 0-9
  /// - Uppercase letters: A-Z
  /// - Lowercase letters: a-z
  /// - Special characters: - . _
  static const String _charset =
      '0123456789'
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
      'abcdefghijklmnopqrstuvwxyz'
      '-._';

  /// Regular expression for validating nonce format
  ///
  /// Matches strings containing only alphanumeric characters
  /// and allowed special characters (-, ., _)
  static final RegExp _validPattern = RegExp(r'^[A-Za-z0-9\-._]+$');

  @override
  Future<NonceResult> generateNonce({int length = 32}) async {
    if (length < 32) {
      throw ArgumentError(
        'Nonce length must be at least 32 characters',
      );
    }

    // Generate random string using secure random
    var plainNonce = '';
    var attempts = 0;
    const maxAttempts = 100;

    do {
      plainNonce = _generateRandomString(length);
      attempts++;

      if (attempts >= maxAttempts) {
        throw StateError(
          'Failed to generate unique nonce after $maxAttempts attempts',
        );
      }
    } while (_usedNonces.contains(plainNonce));

    // Track this nonce as used
    _usedNonces.add(plainNonce);

    // Hash the nonce using SHA-256
    final bytes = utf8.encode(plainNonce);
    final digest = sha256.convert(bytes);
    final hashedNonce = digest.toString();

    return NonceResult(
      plainNonce: plainNonce,
      hashedNonce: hashedNonce,
    );
  }

  /// Generates a random string of the specified length
  ///
  /// Uses [Random.secure()] to ensure cryptographic randomness.
  ///
  /// Parameters:
  /// - [length]: The length of the string to generate
  ///
  /// Returns: A random string from the allowed character set
  String _generateRandomString(int length) {
    return List.generate(
      length,
      (_) => _charset[_random.nextInt(_charset.length)],
    ).join();
  }

  @override
  bool validateNonce(String nonce) {
    // Check minimum length
    if (nonce.length < 32) {
      return false;
    }

    // Check format: alphanumeric + allowed special chars
    if (!_validPattern.hasMatch(nonce)) {
      return false;
    }

    return true;
  }

  @override
  void clearUsedNonces() {
    _usedNonces.clear();
  }

  /// Gets the count of currently tracked used nonces
  ///
  /// This is useful for monitoring memory usage and determining
  /// when to call [clearUsedNonces].
  ///
  /// Returns: The number of nonces currently being tracked
  int get usedNonceCount => _usedNonces.length;
}
