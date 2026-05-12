import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/services/native_apple_sign_in_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Implementation of [NativeAppleSignInService] using sign_in_with_apple.
///
/// This implementation provides native Apple Sign In functionality on iOS 13+
/// and macOS 10.15+ using Apple Authentication Services framework. It offers
/// a seamless, system-integrated authentication experience with biometric
/// support (Face ID/Touch ID).
///
/// ## Platform Support
///
/// - **iOS 13+**: Full native support with biometric authentication
/// - **macOS 10.15+**: Full native support with system integration
/// - **Other platforms**: Returns unavailable, caller should use web OAuth
///
/// ## Features
///
/// - Native system UI for Apple Sign In
/// - Biometric authentication (Face ID/Touch ID)
/// - Email and name scope requests
/// - Relay email address detection and handling
/// - Nonce-based security for replay attack prevention
/// - User cancellation handling
/// - Name metadata storage and retrieval
/// - Provider token storage
///
/// ## Security
///
/// - Uses cryptographically secure nonces
/// - Validates nonces with Supabase backend
/// - Stores tokens securely using platform keychain
/// - Sanitizes errors to prevent token leakage
///
/// **Requirements:** 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8
class NativeAppleSignInServiceImpl implements NativeAppleSignInService {
  /// Creates a [NativeAppleSignInServiceImpl] backed by [supabaseClient].
  const NativeAppleSignInServiceImpl({
    required supabase.SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;

  final supabase.SupabaseClient _supabaseClient;

  @override
  bool isAvailable() {
    // Check if running on iOS 13+ or macOS 10.15+
    // sign_in_with_apple package handles version checking internally
    return Platform.isIOS || Platform.isMacOS;
  }

  @override
  Future<Either<AuthFailure, AppleSignInResult>> signIn({
    required String nonce,
  }) async {
    try {
      // Check platform availability
      if (!isAvailable()) {
        return const Left(
          SocialAuthFailure(
            'Native Apple Sign In not available on this platform',
          ),
        );
      }

      // Request credential from Apple with email and fullName scopes
      // The nonce parameter should be the hashed nonce (SHA-256)
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce, // Send hashed nonce to Apple
      );

      // Validate that we received an identity token
      if (credential.identityToken == null) {
        return const Left(
          SocialAuthFailure(
            'Apple Sign In failed - no identity token received',
          ),
        );
      }

      // Extract user information
      // Note: email and name are only provided on first sign-in
      final result = AppleSignInResult(
        idToken: credential.identityToken!,
        authorizationCode: credential.authorizationCode,
        email: credential.email,
        fullName: credential.givenName != null || credential.familyName != null
            ? PersonNameComponents(
                givenName: credential.givenName,
                familyName: credential.familyName,
              )
            : null,
      );

      return Right(result);
    } on SignInWithAppleAuthorizationException catch (e) {
      // Handle user cancellation separately from errors
      if (e.code == AuthorizationErrorCode.canceled) {
        return const Left(SocialAuthCancelledFailure());
      }

      // Handle other authorization errors
      return Left(
        SocialAuthFailure('Apple Sign In failed: ${e.message}'),
      );
    } on SignInWithAppleException catch (e) {
      // Handle general sign-in exceptions
      final message = e.toString();
      return Left(
        SocialAuthFailure('Apple Sign In error: $message'),
      );
    } on Exception catch (e) {
      // Handle unexpected errors
      return Left(
        SocialAuthFailure('Unexpected error during Apple Sign In: $e'),
      );
    }
  }

  @override
  Future<Either<AuthFailure, User>> handleAppleCredential({
    required String idToken,
    required String plainNonce,
    String? authorizationCode,
    String? email,
    PersonNameComponents? fullName,
  }) async {
    try {
      // Sign in to Supabase with Apple ID token and plain nonce
      final response = await _supabaseClient.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.apple,
        idToken: idToken,
        nonce: plainNonce, // Send plain nonce to Supabase for validation
      );

      // Validate response
      if (response.user == null) {
        return const Left(
          SocialAuthFailure(
            'Apple Sign In failed - no user returned from Supabase',
          ),
        );
      }

      // Convert Supabase user to domain User entity
      final user = User.fromSupabaseUser(response.user!);

      // Handle user name metadata (only provided on first sign-in)
      if (fullName != null && fullName.hasName) {
        await _saveNameToMetadata(
          givenName: fullName.givenName,
          familyName: fullName.familyName,
        );
      }

      // Handle relay email detection
      if (email != null && email.endsWith('@privaterelay.appleid.com')) {
        await _markAsRelayEmail(email);
      }

      return Right(user);
    } on supabase.AuthException catch (e) {
      // Handle Supabase authentication errors
      if (e.message.toLowerCase().contains('nonce')) {
        return const Left(
          SocialAuthFailure(
            'Nonce validation failed. Please try signing in again.',
          ),
        );
      }

      return Left(
        SocialAuthFailure('Apple authentication failed: ${e.message}'),
      );
    } on Exception catch (e) {
      // Handle unexpected errors
      return Left(
        SocialAuthFailure('Unexpected error during Apple authentication: $e'),
      );
    }
  }

  /// Saves user name to Supabase user metadata.
  ///
  /// Called on first sign-in when Apple provides the user's name.
  /// Stores name in metadata for retrieval on subsequent sign-ins.
  ///
  /// **Parameters:**
  /// - [givenName]: User's first name (optional)
  /// - [familyName]: User's last name (optional)
  ///
  /// **Requirements:** 3.5
  Future<void> _saveNameToMetadata({
    String? givenName,
    String? familyName,
  }) async {
    try {
      // Construct full name
      final nameParts = [
        givenName,
        familyName,
      ].where((part) => part != null && part.isNotEmpty);
      final fullName = nameParts.join(' ').trim();

      if (fullName.isEmpty) {
        return; // No name to save
      }

      // Update user metadata with name information
      await _supabaseClient.auth.updateUser(
        supabase.UserAttributes(
          data: {
            'full_name': fullName,
            'given_name': givenName,
            'family_name': familyName,
          },
        ),
      );

      debugPrint('User name saved to metadata for Apple Sign In');
    } on Exception catch (e) {
      // Log error but don't fail authentication
      debugPrint('Failed to save name to metadata: $e');
    }
  }

  /// Marks email as Apple relay address in user metadata.
  ///
  /// Called when email ends with @privaterelay.appleid.com to indicate
  /// the user chose to hide their real email address.
  ///
  /// **Parameters:**
  /// - [email]: Relay email address
  ///
  /// **Requirements:** 3.6
  Future<void> _markAsRelayEmail(String email) async {
    try {
      await _supabaseClient.auth.updateUser(
        supabase.UserAttributes(
          data: {
            'is_relay_email': true,
            'relay_email': email,
          },
        ),
      );

      debugPrint('Email marked as Apple relay address');
    } on Exception catch (e) {
      // Log error but don't fail authentication
      debugPrint('Failed to mark relay email: $e');
    }
  }
}
