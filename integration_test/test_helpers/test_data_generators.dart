import 'dart:math';

import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';
import 'package:grex/features/auth/domain/entities/user.dart';
import 'package:grex/features/auth/domain/entities/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Test data generators for social login integration tests
class TestDataGenerators {
  static final _random = Random();

  /// Generate a new user for OAuth testing
  static User generateNewUser() {
    final id = 'new-user-${_random.nextInt(10000)}';
    final email = 'newuser${_random.nextInt(10000)}@example.com';
    final displayName = 'New User ${_random.nextInt(1000)}';

    return User(
      id: id,
      email: email,
      createdAt: DateTime.now(),
      lastSignInAt: DateTime.now(),
      appMetadata: const {
        'providers': ['google'],
        'provider': 'google',
      },
      userMetadata: {
        'full_name': displayName,
        'email': email,
        'email_verified': true,
        'phone_verified': false,
        'sub': id,
      },
    );
  }

  /// Generate an existing user with profile
  static User generateExistingUser() {
    final id = 'existing-user-${_random.nextInt(10000)}';
    final email = 'existing${_random.nextInt(10000)}@example.com';
    final displayName = 'Existing User ${_random.nextInt(1000)}';

    return User(
      id: id,
      email: email,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastSignInAt: DateTime.now(),
      appMetadata: const {
        'providers': ['google'],
        'provider': 'google',
      },
      userMetadata: {
        'full_name': displayName,
        'email': email,
        'email_verified': true,
        'phone_verified': false,
        'sub': id,
      },
    );
  }

  /// Generate a new user with specific email
  static User generateNewUserWithEmail(String email) {
    final id = 'new-user-${_random.nextInt(10000)}';
    final displayName = 'User ${_random.nextInt(1000)}';

    return User(
      id: id,
      email: email,
      createdAt: DateTime.now(),
      lastSignInAt: DateTime.now(),
      appMetadata: const {
        'providers': ['google'],
        'provider': 'google',
      },
      userMetadata: {
        'full_name': displayName,
        'email': email,
        'email_verified': true,
        'phone_verified': false,
        'sub': id,
      },
    );
  }

  /// Generate a user profile for testing
  static UserProfile generateUserProfile(String userId) {
    return UserProfile(
      id: userId,
      email: 'user${_random.nextInt(10000)}@example.com',
      displayName: 'Test User ${_random.nextInt(1000)}',
      preferredCurrency: 'VND',
      languageCode: 'vi',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  /// Generate a user profile with specific email
  static UserProfile generateUserProfileWithEmail(String email) {
    return UserProfile(
      id: 'profile-${_random.nextInt(10000)}',
      email: email,
      displayName: 'Existing User ${_random.nextInt(1000)}',
      preferredCurrency: 'USD',
      languageCode: 'en',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  /// Generate a Supabase User for mocking
  static supabase.User generateSupabaseUser({
    String? id,
    String? email,
    String? displayName,
    SocialAuthProvider? provider,
  }) {
    final userId = id ?? 'user-${_random.nextInt(10000)}';
    final userEmail = email ?? 'user${_random.nextInt(10000)}@example.com';
    final userName = displayName ?? 'User ${_random.nextInt(1000)}';
    final authProvider = provider ?? SocialAuthProvider.google;

    return supabase.User(
      id: userId,
      appMetadata: {
        'providers': [authProvider.name],
        'provider': authProvider.name,
      },
      userMetadata: {
        'full_name': userName,
        'email': userEmail,
        'email_verified': true,
        'phone_verified': false,
        'sub': userId,
      },
      aud: 'authenticated',
      email: userEmail,
      createdAt: DateTime.now().toIso8601String(),
      emailConfirmedAt: DateTime.now().toIso8601String(),
      lastSignInAt: DateTime.now().toIso8601String(),
      role: 'authenticated',
      updatedAt: DateTime.now().toIso8601String(),
      identities: [
        supabase.UserIdentity(
          identityId: 'identity-$userId',
          id: userId,
          userId: userId,
          identityData: {
            'email': userEmail,
            'full_name': userName,
            'provider': authProvider.name,
            'sub': userId,
          },
          provider: authProvider.name,
          createdAt: DateTime.now().toIso8601String(),
          lastSignInAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      ],
    );
  }

  /// Generate a Supabase Session for mocking
  static supabase.Session generateSupabaseSession({
    supabase.User? user,
    String? accessToken,
    String? refreshToken,
  }) {
    final sessionUser = user ?? generateSupabaseUser();
    final token = accessToken ?? 'access_token_${_random.nextInt(10000)}';
    final refresh = refreshToken ?? 'refresh_token_${_random.nextInt(10000)}';

    return supabase.Session(
      accessToken: token,
      refreshToken: refresh,
      expiresIn: 3600,
      tokenType: 'bearer',
      user: sessionUser,
    );
  }

  /// Generate random OAuth data
  static Map<String, dynamic> generateOAuthData({
    SocialAuthProvider? provider,
    String? email,
    String? displayName,
  }) {
    final authProvider = provider ?? SocialAuthProvider.google;
    final userEmail = email ?? 'oauth${_random.nextInt(10000)}@example.com';
    final userName = displayName ?? 'OAuth User ${_random.nextInt(1000)}';

    return {
      'provider': authProvider.name,
      'email': userEmail,
      'full_name': userName,
      'email_verified': true,
      'sub': 'oauth-${_random.nextInt(10000)}',
    };
  }

  /// Generate random provider
  static SocialAuthProvider randomProvider() {
    return _random.nextBool()
        ? SocialAuthProvider.google
        : SocialAuthProvider.apple;
  }

  /// Generate random email
  static String generateRandomEmail() {
    return 'test${_random.nextInt(10000)}@example.com';
  }

  /// Generate random display name
  static String generateRandomDisplayName() {
    final names = [
      'John Doe',
      'Jane Smith',
      'Bob Johnson',
      'Alice Brown',
      'Charlie Wilson',
    ];
    return names[_random.nextInt(names.length)];
  }

  /// Generate random currency
  static String generateRandomCurrency() {
    final currencies = ['VND', 'USD', 'EUR', 'GBP'];
    return currencies[_random.nextInt(currencies.length)];
  }

  /// Generate random language code
  static String generateRandomLanguageCode() {
    final languages = ['vi', 'en', 'es', 'ar'];
    return languages[_random.nextInt(languages.length)];
  }
}
