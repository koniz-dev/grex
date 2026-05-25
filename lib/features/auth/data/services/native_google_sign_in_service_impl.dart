import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/services/native_google_sign_in_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Implementation of [NativeGoogleSignInService] using the
/// `google_sign_in` plugin.
///
/// Requires:
/// - `serverClientId`: Web OAuth client ID registered in Google Cloud. Used
///   so Google issues an idToken with the correct audience for Supabase.
/// - `iosClientId`: iOS OAuth client ID (only needed on iOS/macOS so Google
///   can verify the bundle ID). Pass `null` when running on Android only.
class NativeGoogleSignInServiceImpl implements NativeGoogleSignInService {
  /// Creates a [NativeGoogleSignInServiceImpl].
  NativeGoogleSignInServiceImpl({
    required supabase.SupabaseClient supabaseClient,
    required String serverClientId,
    String? iosClientId,
    GoogleSignIn? googleSignIn,
  }) : _supabaseClient = supabaseClient,
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             clientId: iosClientId,
             serverClientId: serverClientId,
             scopes: const ['email', 'profile', 'openid'],
           );

  final supabase.SupabaseClient _supabaseClient;
  final GoogleSignIn _googleSignIn;

  @override
  bool isAvailable() {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  @override
  Future<Either<AuthFailure, GoogleSignInTokens>> signIn() async {
    try {
      if (!isAvailable()) {
        return const Left(
          SocialAuthFailure(
            'Native Google Sign In not available on this platform',
          ),
        );
      }

      final account = await _googleSignIn.signIn();
      if (account == null) {
        return const Left(SocialAuthCancelledFailure());
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;

      if (idToken == null || accessToken == null) {
        return const Left(
          SocialAuthFailure(
            'Google Sign In failed - missing idToken or accessToken',
          ),
        );
      }

      return Right(
        GoogleSignInTokens(
          idToken: idToken,
          accessToken: accessToken,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == GoogleSignIn.kSignInCanceledError) {
        return const Left(SocialAuthCancelledFailure());
      }
      if (e.code == GoogleSignIn.kNetworkError) {
        return const Left(SocialAuthNetworkFailure());
      }
      return Left(SocialAuthFailure('Google Sign In failed: ${e.message}'));
    } on Object catch (e) {
      debugPrint('Google native sign-in failed: $e');
      return Left(SocialAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, User>> handleGoogleCredential({
    required String idToken,
    required String accessToken,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        return const Left(
          SocialAuthFailure(
            'Google Sign In failed - no user returned from Supabase',
          ),
        );
      }

      final user = User.fromSupabaseUser(response.user!);

      if ((displayName != null && displayName.isNotEmpty) ||
          (photoUrl != null && photoUrl.isNotEmpty)) {
        await _saveProfileMetadata(
          displayName: displayName,
          photoUrl: photoUrl,
        );
      }

      return Right(user);
    } on supabase.AuthException catch (e) {
      if (e.message.toLowerCase().contains('nonce')) {
        return const Left(NonceMismatchFailure());
      }
      return Left(
        SocialAuthFailure('Google authentication failed: ${e.message}'),
      );
    } on Object catch (e) {
      return Left(
        SocialAuthFailure('Unexpected error during Google authentication: $e'),
      );
    }
  }

  Future<void> _saveProfileMetadata({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (displayName != null && displayName.isNotEmpty) {
        data['full_name'] = displayName;
      }
      if (photoUrl != null && photoUrl.isNotEmpty) {
        data['avatar_url'] = photoUrl;
      }
      if (data.isEmpty) return;

      await _supabaseClient.auth.updateUser(
        supabase.UserAttributes(data: data),
      );
    } on Object catch (e) {
      debugPrint('Failed to save Google profile metadata: $e');
    }
  }
}
