import 'dart:async';

import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';
import 'package:grex/features/auth/domain/entities/user.dart' as grex_user;
import 'package:grex/features/auth/domain/entities/user_profile.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mock_supabase_client.dart';
import 'test_data_generators.dart';

/// OAuth flow simulator for integration testing
class OAuthSimulator {
  OAuthSimulator(this.mockSupabaseClient);
  final MockSupabaseClient mockSupabaseClient;

  /// Simulate successful OAuth flow
  Future<void> simulateSuccessfulOAuth({
    required SocialAuthProvider provider,
    required grex_user.User user,
    required bool isNewUser,
  }) async {
    final mockAuth = mockSupabaseClient.auth as MockGoTrueClient;

    // Mock OAuth initiation success
    when(
      mockSupabaseClient.auth.signInWithOAuth(
        provider == SocialAuthProvider.google
            ? OAuthProvider.google
            : OAuthProvider.apple,
        redirectTo: anyNamed('redirectTo'),
      ),
    ).thenAnswer((_) async => true);

    // Generate Supabase user and session
    final supabaseUser = TestDataGenerators.generateSupabaseUser(
      id: user.id,
      email: user.email,
      displayName: user.oauthDisplayName,
      provider: provider,
    );

    final session = TestDataGenerators.generateSupabaseSession(
      user: supabaseUser,
    );

    // Set current user and session
    mockAuth
      ..setCurrentUserForTesting(supabaseUser)
      ..setCurrentSessionForTesting(session);

    // Simulate callback processing delay
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  /// Simulate OAuth with existing email (account linking scenario)
  Future<void> simulateOAuthWithExistingEmail({
    required SocialAuthProvider provider,
    required grex_user.User user,
    required UserProfile existingProfile,
  }) async {
    final mockAuth = mockSupabaseClient.auth as MockGoTrueClient;

    // Mock OAuth initiation success
    when(
      mockSupabaseClient.auth.signInWithOAuth(
        provider == SocialAuthProvider.google
            ? OAuthProvider.google
            : OAuthProvider.apple,
        redirectTo: anyNamed('redirectTo'),
      ),
    ).thenAnswer((_) async => true);

    // Generate Supabase user and session
    final supabaseUser = TestDataGenerators.generateSupabaseUser(
      id: user.id,
      email: user.email,
      displayName: user.oauthDisplayName,
      provider: provider,
    );

    final session = TestDataGenerators.generateSupabaseSession(
      user: supabaseUser,
    );

    // Set current user and session
    mockAuth
      ..setCurrentUserForTesting(supabaseUser)
      ..setCurrentSessionForTesting(session);

    // Mock account linking
    when(mockSupabaseClient.auth.linkIdentity(OAuthProvider.google)).thenAnswer(
      (_) async => true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  /// Simulate OAuth cancellation
  Future<void> simulateOAuthCancellation({
    required SocialAuthProvider provider,
  }) async {
    // Mock OAuth cancellation (returns false)
    when(
      mockSupabaseClient.auth.signInWithOAuth(
        provider == SocialAuthProvider.google
            ? OAuthProvider.google
            : OAuthProvider.apple,
        redirectTo: anyNamed('redirectTo'),
      ),
    ).thenAnswer((_) async => false);

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  /// Simulate network error during OAuth
  Future<void> simulateNetworkError({
    required SocialAuthProvider provider,
  }) async {
    // Mock network error
    when(
      mockSupabaseClient.auth.signInWithOAuth(
        provider == SocialAuthProvider.google
            ? OAuthProvider.google
            : OAuthProvider.apple,
        redirectTo: anyNamed('redirectTo'),
      ),
    ).thenThrow(const AuthException('Network error occurred'));

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  /// Simulate deep link callback
  Future<void> simulateDeepLinkCallback(
    String callbackUrl, {
    required bool appClosed,
  }) async {
    final uri = Uri.parse(callbackUrl);

    // Extract tokens from URL
    final accessToken = uri.queryParameters['access_token'];
    final refreshToken = uri.queryParameters['refresh_token'];

    if (accessToken != null && refreshToken != null) {
      // Generate user and session from tokens
      final user = TestDataGenerators.generateSupabaseUser();
      final session = TestDataGenerators.generateSupabaseSession(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      // Mock session from URL
      when(mockSupabaseClient.auth.getSessionFromUrl(uri)).thenAnswer(
        (_) async => AuthSessionUrlResponse(
          session: session,
          redirectType: null,
        ),
      );

      // Set current session
      (mockSupabaseClient.auth as MockGoTrueClient)
        ..setCurrentUserForTesting(user)
        ..setCurrentSessionForTesting(session);
    }

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  /// Simulate OAuth timeout
  Future<void> simulateOAuthTimeout({
    required SocialAuthProvider provider,
  }) async {
    // Mock timeout error
    when(
      mockSupabaseClient.auth.signInWithOAuth(
        provider == SocialAuthProvider.google
            ? OAuthProvider.google
            : OAuthProvider.apple,
        redirectTo: anyNamed('redirectTo'),
      ),
    ).thenThrow(TimeoutException('OAuth timeout', const Duration(seconds: 10)));

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  /// Simulate invalid OAuth callback
  Future<void> simulateInvalidCallback(String invalidUrl) async {
    final uri = Uri.parse(invalidUrl);

    // Mock invalid callback handling
    when(
      mockSupabaseClient.auth.getSessionFromUrl(uri),
    ).thenThrow(const AuthException('Invalid callback URL'));

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  /// Simulate session restoration
  Future<void> simulateSessionRestoration({
    required grex_user.User user,
    required UserProfile profile,
  }) async {
    final supabaseUser = TestDataGenerators.generateSupabaseUser(
      id: user.id,
      email: user.email,
      displayName: user.oauthDisplayName,
    );

    final session = TestDataGenerators.generateSupabaseSession(
      user: supabaseUser,
    );

    // Set restored session
    (mockSupabaseClient.auth as MockGoTrueClient)
      ..setCurrentUserForTesting(supabaseUser)
      ..setCurrentSessionForTesting(session);

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  /// Simulate expired session
  Future<void> simulateExpiredSession() async {
    final mockAuth = mockSupabaseClient.auth as MockGoTrueClient;

    // Create expired session
    final expiredSession = Session(
      accessToken: 'expired_token',
      refreshToken: 'expired_refresh',
      expiresIn: 0,
      tokenType: 'bearer',
      user: User(
        id: 'expired_user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
      ),
    );

    mockAuth
      ..setCurrentSessionForTesting(expiredSession)
      ..setCurrentUserForTesting(null);

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  /// Simulate profile setup completion
  Future<void> simulateProfileSetupCompletion({
    required grex_user.User user,
    required Map<String, dynamic> profileData,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  /// Simulate account linking confirmation
  Future<void> simulateAccountLinkingConfirmation({
    required grex_user.User newUser,
    required UserProfile existingProfile,
    required SocialAuthProvider provider,
  }) async {
    // Mock successful account linking
    when(
      mockSupabaseClient.auth.linkIdentity(
        provider == SocialAuthProvider.google
            ? OAuthProvider.google
            : OAuthProvider.apple,
      ),
    ).thenAnswer((_) async => true);

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
