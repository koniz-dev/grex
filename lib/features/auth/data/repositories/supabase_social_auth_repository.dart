import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:grex/core/performance/performance_service.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/entities/profile_setup_data.dart';
import 'package:grex/features/auth/domain/repositories/social_auth_repository.dart';
import 'package:grex/features/auth/domain/repositories/user_repository.dart';
import 'package:grex/features/auth/domain/services/native_apple_sign_in_service.dart';
import 'package:grex/features/auth/domain/services/nonce_generator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Supabase implementation of [SocialAuthRepository].
///
/// Handles OAuth via Supabase Auth with nonce-based replay protection. On
/// iOS/macOS the Apple flow can use native Apple Authentication Services
/// (Face ID / Touch ID) instead of the web OAuth fallback.
class SupabaseSocialAuthRepository implements SocialAuthRepository {
  SupabaseSocialAuthRepository({
    required supabase.SupabaseClient supabaseClient,
    required UserRepository userRepository,
    required PerformanceService performanceService,
    required NonceGenerator nonceGenerator,
    required NativeAppleSignInService nativeAppleSignInService,
  }) : _supabaseClient = supabaseClient,
       _userRepository = userRepository,
       _performanceService = performanceService,
       _nonceGenerator = nonceGenerator,
       _nativeAppleSignInService = nativeAppleSignInService;

  final supabase.SupabaseClient _supabaseClient;
  final UserRepository _userRepository;
  final PerformanceService _performanceService;
  final NonceGenerator _nonceGenerator;
  final NativeAppleSignInService _nativeAppleSignInService;

  static const String _redirectUrl = 'io.supabase.grex://login-callback/';
  static const Duration _authUserTimeout = Duration(seconds: 10);

  @override
  Future<Either<AuthFailure, User>> signInWithGoogle() {
    return _performanceService.measureOperation(
      name: 'oauth_google_signin',
      attributes: {'provider': 'google'},
      operation: () => _performWebOAuth(
        provider: supabase.OAuthProvider.google,
        providerName: 'Google',
      ),
    );
  }

  @override
  Future<Either<AuthFailure, User>> signInWithApple({
    bool useNativeFlow = true,
  }) {
    return _performanceService.measureOperation(
      name: 'oauth_apple_signin',
      attributes: {
        'provider': 'apple',
        'native_flow': useNativeFlow.toString(),
      },
      operation: () async {
        if (useNativeFlow && _nativeAppleSignInService.isAvailable()) {
          return _performNativeAppleSignIn();
        }
        return _performWebOAuth(
          provider: supabase.OAuthProvider.apple,
          providerName: 'Apple',
        );
      },
    );
  }

  Future<Either<AuthFailure, User>> _performWebOAuth({
    required supabase.OAuthProvider provider,
    required String providerName,
  }) async {
    try {
      final nonce = await _nonceGenerator.generateNonce();

      final response = await _supabaseClient.auth.signInWithOAuth(
        provider,
        redirectTo: _redirectUrl,
        authScreenLaunchMode: supabase.LaunchMode.externalApplication,
        queryParams: {'nonce': nonce.hashedNonce},
      );

      if (!response) {
        return const Left(SocialAuthCancelledFailure());
      }

      final user = await _waitForAuthUser();
      if (user == null) {
        return const Left(SocialAuthFailure('Authentication failed'));
      }

      return Right(User.fromSupabaseUser(user));
    } on supabase.AuthException catch (e) {
      return Left(_mapAuthException(e));
    } on TimeoutException catch (_) {
      return const Left(SocialAuthTimeoutFailure());
    } on Object catch (e) {
      debugPrint('$providerName OAuth failed: $e');
      return Left(SocialAuthFailure(e.toString()));
    }
  }

  Future<Either<AuthFailure, User>> _performNativeAppleSignIn() async {
    try {
      final nonce = await _nonceGenerator.generateNonce();

      final signInResult = await _nativeAppleSignInService.signIn(
        nonce: nonce.hashedNonce,
      );

      return signInResult.fold(
        Left.new,
        (appleResult) async {
          final credentialResult = await _nativeAppleSignInService
              .handleAppleCredential(
                idToken: appleResult.idToken,
                plainNonce: nonce.plainNonce,
                authorizationCode: appleResult.authorizationCode,
                email: appleResult.email,
                fullName: appleResult.fullName,
              );
          return credentialResult;
        },
      );
    } on supabase.AuthException catch (e) {
      return Left(_mapAuthException(e));
    } on TimeoutException catch (_) {
      return const Left(SocialAuthTimeoutFailure());
    } on Object catch (e) {
      debugPrint('Apple Native sign-in failed: $e');
      return Left(SocialAuthFailure(e.toString()));
    }
  }

  @override
  Future<bool> hasUserProfile(String userId) async {
    final result = await _userRepository.getUserProfile(userId);
    return result.isRight();
  }

  @override
  Future<Either<AuthFailure, void>> linkSocialProvider({
    required String userId,
    required SocialAuthProvider provider,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithOAuth(
        provider == SocialAuthProvider.google
            ? supabase.OAuthProvider.google
            : supabase.OAuthProvider.apple,
        redirectTo: _redirectUrl,
        authScreenLaunchMode: supabase.LaunchMode.externalApplication,
      );

      if (!response) {
        return const Left(SocialAuthCancelledFailure());
      }

      final user = await _waitForAuthUser();
      if (user == null) {
        return const Left(AccountLinkingFailure('Failed to link account'));
      }

      return const Right(null);
    } on supabase.AuthException catch (e) {
      return Left(AccountLinkingFailure('Failed to link account: ${e.message}'));
    } on TimeoutException catch (_) {
      return const Left(SocialAuthTimeoutFailure());
    } on Object catch (e) {
      return Left(AccountLinkingFailure('Failed to link account: $e'));
    }
  }

  @override
  Future<Either<AuthFailure, UserProfile>> createUserProfile(
    String userId,
    ProfileSetupData profileData,
  ) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      return const Left(GenericAuthFailure('No authenticated user found'));
    }

    final userProfile = UserProfile(
      id: userId,
      email: currentUser.email ?? '',
      displayName: profileData.displayName,
      preferredCurrency: profileData.preferredCurrency,
      languageCode: profileData.languageCode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _userRepository.createUserProfile(userProfile);
    return result.fold(
      (failure) => Left(
        GenericAuthFailure('Failed to create profile: ${failure.message}'),
      ),
      Right.new,
    );
  }

  /// Polls Supabase for the authenticated user after an OAuth callback.
  /// Throws [TimeoutException] if no user appears within [_authUserTimeout].
  Future<supabase.User?> _waitForAuthUser() async {
    const pollInterval = Duration(milliseconds: 250);
    final maxAttempts = _authUserTimeout.inMilliseconds ~/
        pollInterval.inMilliseconds;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final user = _supabaseClient.auth.currentUser;
      if (user != null) {
        return user;
      }
      await Future<void>.delayed(pollInterval);
    }

    throw TimeoutException(
      'Authentication timeout after ${_authUserTimeout.inSeconds} seconds',
    );
  }

  AuthFailure _mapAuthException(supabase.AuthException exception) {
    final message = exception.message.toLowerCase();

    if (message.contains('nonce')) {
      return const NonceMismatchFailure();
    }
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return const SocialAuthNetworkFailure();
    }
    if (message.contains('cancel') || message.contains('abort')) {
      return const SocialAuthCancelledFailure();
    }
    if (message.contains('already linked') ||
        message.contains('provider already exists')) {
      return AccountLinkingFailure(exception.message);
    }

    return SocialAuthFailure(exception.message);
  }
}
