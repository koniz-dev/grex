import 'package:flutter/foundation.dart';

/// Service for generating cryptographically secure nonces for OAuth requests
///
/// Nonces are used to prevent replay attacks and token injection attacks
/// by ensuring each OAuth request is unique and can only be used once.
abstract class NonceGenerator {
  /// Generates a cryptographically random nonce
  ///
  /// Returns a [NonceResult] containing both the plain nonce (sent to Supabase)
  /// and the hashed nonce (sent to OAuth provider).
  ///
  /// The nonce will be at least [length] characters long and contain only
  /// alphanumeric characters plus allowed special characters (-, ., _).
  ///
  /// Parameters:
  /// - [length]: Minimum length of the nonce (default: 32)
  ///
  /// Returns: A [NonceResult] with plainNonce and hashedNonce
  Future<NonceResult> generateNonce({int length = 32});

  /// Validates nonce format and uniqueness
  ///
  /// Checks that the nonce:
  /// - Is at least 32 characters long
  /// - Contains only alphanumeric characters and allowed special chars
  ///   (-, ., _)
  /// - Matches the expected format pattern
  ///
  /// Parameters:
  /// - [nonce]: The nonce string to validate
  ///
  /// Returns: true if the nonce is valid, false otherwise
  bool validateNonce(String nonce);

  /// Clears used nonces from memory
  ///
  /// This should be called periodically to prevent memory buildup
  /// from tracking used nonces. Typically called after nonces expire
  /// (10 minutes after generation).
  void clearUsedNonces();
}

/// Result of nonce generation containing both plain and hashed versions
///
/// The plain nonce is sent to Supabase for validation, while the hashed
/// nonce is sent to the OAuth provider (Google or Apple).
@immutable
class NonceResult {
  /// Creates a nonce result with plain and hashed versions
  const NonceResult({
    required this.plainNonce,
    required this.hashedNonce,
  });

  /// The plain, unhashed nonce
  ///
  /// This is sent to Supabase's signInWithIdToken method for validation
  final String plainNonce;

  /// The SHA-256 hashed version of the nonce
  ///
  /// This is sent to the OAuth provider in the authorization request
  final String hashedNonce;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NonceResult &&
          runtimeType == other.runtimeType &&
          plainNonce == other.plainNonce &&
          hashedNonce == other.hashedNonce;

  @override
  int get hashCode => plainNonce.hashCode ^ hashedNonce.hashCode;

  @override
  String toString() =>
      'NonceResult(plainNonce: ${plainNonce.substring(0, 8)}..., '
      'hashedNonce: ${hashedNonce.substring(0, 8)}...)';
}
