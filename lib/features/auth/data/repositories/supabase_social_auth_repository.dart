import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:grex/core/performance/performance_service.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/entities/profile_setup_data.dart';
import 'package:grex/features/auth/domain/repositories/social_auth_repository.dart';
import 'package:grex/features/auth/domain/repositories/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Supabase implementation of [SocialAuthRepository].
///
/// This class provides concrete implementations of social authentication
/// operations using Supabase Auth's OAuth provider support. It handles
/// the complete OAuth flow including browser launch, callback handling,
/// session establishment, and error mapping with performance optimizations.
class SupabaseSocialAuthRepository implements SocialAuthRepository {
  /// Creates a [SupabaseSocialAuthRepository] with required dependencies.
  ///
  /// Parameters:
  /// - [supabaseClient]: Supabase client for OAuth operations
  /// - [userRepository]: Repository for user profile operations
  /// - [performanceService]: Service for performance monitoring
  const SupabaseSocialAuthRepository({
    required supabase.SupabaseClient supabaseClient,
    required UserRepository userRepository,
    required PerformanceService performanceService,
  }) : _supabaseClient = supabaseClient,
       _userRepository = userRepository,
       _performanceService = performanceService;

  final supabase.SupabaseClient _supabaseClient;
  final UserRepository _userRepository;
  final PerformanceService _performanceService;

  /// OAuth callback redirect URL for deep linking
  static const String _redirectUrl = 'io.supabase.grex://login-callback/';

  /// Timeout duration for waiting for auth user after OAuth callback
  static const Duration _authUserTimeout = Duration(seconds: 10);

  @override
  Future<Either<AuthFailure, User>> signInWithGoogle() async {
    return _performanceService.measureOperation(
      name: 'oauth_google_signin',
      attributes: {'provider': 'google'},
      operation: () => _performOAuthSignIn(
        provider: supabase.OAuthProvider.google,
        providerName: 'Google',
      ),
    );
  }

  @override
  Future<Either<AuthFailure, User>> signInWithApple() async {
    return _performanceService.measureOperation(
      name: 'oauth_apple_signin',
      attributes: {'provider': 'apple'},
      operation: () => _performOAuthSignIn(
        provider: supabase.OAuthProvider.apple,
        providerName: 'Apple',
      ),
    );
  }

  /// Performs OAuth sign-in with performance monitoring and optimizations.
  ///
  /// This method handles the complete OAuth flow with:
  /// - Fast external browser launch
  /// - Optimized timeout handling (10 seconds)
  /// - Minimal UI redraws during authentication
  /// - Performance tracking
  Future<Either<AuthFailure, User>> _performOAuthSignIn({
    required supabase.OAuthProvider provider,
    required String providerName,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Start OAuth flow with external browser for fastest launch
      final response = await _supabaseClient.auth.signInWithOAuth(
        provider,
        redirectTo: _redirectUrl,
        authScreenLaunchMode: supabase.LaunchMode.externalApplication,
      );

      if (!response) {
        debugPrint('$providerName OAuth cancelled by user');
        return const Left(SocialAuthCancelledFailure());
      }

      // Wait for auth state change with optimized timeout
      final user = await _waitForAuthUserOptimized();

      if (user == null) {
        debugPrint('$providerName OAuth failed - no user received');
        return const Left(SocialAuthFailure('Authentication failed'));
      }

      stopwatch.stop();
      debugPrint(
        '$providerName OAuth completed in ${stopwatch.elapsedMilliseconds}ms',
      );

      return Right(User.fromSupabaseUser(user));
    } on supabase.AuthException catch (e) {
      stopwatch.stop();
      debugPrint('$providerName OAuth failed with AuthException: ${e.message}');
      return Left(_mapAuthException(e));
    } on TimeoutException catch (_) {
      stopwatch.stop();
      debugPrint(
        '$providerName OAuth timed out after ${stopwatch.elapsedMilliseconds}ms',
      );
      return const Left(SocialAuthTimeoutFailure());
    } on Object catch (e) {
      stopwatch.stop();
      debugPrint('$providerName OAuth failed with error: $e');
      return Left(SocialAuthFailure(e.toString()));
    }
  }

  @override
  Future<bool> hasUserProfile(String userId) async {
    final result = await _userRepository.getUserProfile(userId);
    return result.fold(
      (failure) => false,
      (profile) => true,
    );
  }

  @override
  Future<Either<AuthFailure, void>> linkSocialProvider({
    required String userId,
    required SocialAuthProvider provider,
  }) async {
    try {
      // Supabase automatically links providers when same email is used
      // This method initiates the OAuth flow for linking
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

      // Wait for auth state change with timeout
      final user = await _waitForAuthUser();

      if (user == null) {
        return const Left(
          AccountLinkingFailure('Failed to link account'),
        );
      }

      return const Right(null);
    } on supabase.AuthException catch (e) {
      return Left(
        AccountLinkingFailure('Failed to link account: ${e.message}'),
      );
    } on TimeoutException catch (_) {
      return const Left(SocialAuthTimeoutFailure());
    } on Object catch (e) {
      return Left(
        AccountLinkingFailure('Failed to link account: ${e.runtimeType}: $e'),
      );
    }
  }

  @override
  Future<Either<AuthFailure, UserProfile>> createUserProfile(
    String userId,
    ProfileSetupData profileData,
  ) async {
    // Get current user to extract OAuth metadata
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      return const Left(
        GenericAuthFailure('No authenticated user found'),
      );
    }

    // Create UserProfile entity
    final userProfile = UserProfile(
      id: userId,
      email: currentUser.email ?? '',
      displayName: profileData.displayName,
      preferredCurrency: profileData.preferredCurrency,
      languageCode: profileData.languageCode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Use UserRepository to create the profile
    final result = await _userRepository.createUserProfile(userProfile);

    return result.fold(
      (failure) => Left(
        GenericAuthFailure('Failed to create profile: ${failure.message}'),
      ),
      Right.new,
    );
  }

  /// Waits for the authenticated user to be available after OAuth callback.
  ///
  /// Optimized version with:
  /// - Reduced polling interval for faster response
  /// - Early exit on first successful auth
  /// - Better timeout handling (10 seconds as per requirements)
  ///
  /// Returns the authenticated [supabase.User] or null if timeout occurs.
  Future<supabase.User?> _waitForAuthUserOptimized() async {
    const pollInterval = Duration(milliseconds: 250);
    final maxAttempts =
        (_authUserTimeout.inMilliseconds / pollInterval.inMilliseconds).round();

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final user = _supabaseClient.auth.currentUser;
      if (user != null) {
        debugPrint(
          'Auth user received after ${attempt * pollInterval.inMilliseconds}ms',
        );
        return user;
      }

      // Use shorter intervals for faster response
      await Future<void>.delayed(pollInterval);
    }

    throw TimeoutException(
      'Authentication timeout after ${_authUserTimeout.inSeconds} seconds',
    );
  }

  /// Legacy method for backward compatibility
  Future<supabase.User?> _waitForAuthUser() => _waitForAuthUserOptimized();

  /// Maps Supabase [supabase.AuthException] to domain [AuthFailure].
  ///
  /// This method examines the exception message and status code to
  /// determine the appropriate domain failure type.
  AuthFailure _mapAuthException(supabase.AuthException exception) {
    final message = exception.message.toLowerCase();

    // Check for network-related errors
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return const SocialAuthNetworkFailure();
    }

    // Check for cancellation
    if (message.contains('cancel') || message.contains('abort')) {
      return const SocialAuthCancelledFailure();
    }

    // Check for account linking errors
    if (message.contains('already linked') ||
        message.contains('provider already exists')) {
      return AccountLinkingFailure(exception.message);
    }

    // Generic social auth failure
    return SocialAuthFailure(exception.message);
  }
}
