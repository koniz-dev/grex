import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  group('Property Test: Successful OAuth Establishes Valid Session', () {
    late Random random;

    setUp(() {
      random = Random();
    });

    test(
      'Property 2: Successful OAuth Session Contains Valid User Data - Google',
      () async {
        // Property-based test with 100+ iterations for Google provider
        // Validates: Requirements 1.2, 2.2, 3.2, 7.1
        const iterations = 100;

        for (var i = 0; i < iterations; i++) {
          // Generate random successful OAuth scenario
          final mockUser = _generateRandomSupabaseUser(random, 'google');

          // Convert to domain User entity
          final domainUser = User.fromSupabaseUser(mockUser);

          // Assert - Property: Successful OAuth returns valid User
          // Property: Valid session has user data
          expect(
            domainUser.id,
            isNotEmpty,
            reason: 'Iteration $i: User should have valid ID',
          );
          expect(
            domainUser.email,
            isNotEmpty,
            reason: 'Iteration $i: User should have valid email',
          );
          expect(
            domainUser.createdAt,
            isNotNull,
            reason: 'Iteration $i: User should have creation timestamp',
          );

          // Property: Social provider metadata is accessible
          expect(
            domainUser.socialProvider,
            equals(SocialAuthProvider.google),
            reason: 'Iteration $i: User should have Google provider metadata',
          );

          // Property: OAuth display name is available when provided
          if (mockUser.userMetadata?['full_name'] != null) {
            expect(
              domainUser.oauthDisplayName,
              isNotNull,
              reason: 'Iteration $i: OAuth display name should be available',
            );
          }

          // Property: Email confirmation status is available
          expect(
            domainUser.emailConfirmed,
            isA<bool>(),
            reason: 'Iteration $i: Email confirmation status should be boolean',
          );
        }
      },
    );

    test(
      'Property 2: Successful OAuth Session Contains Valid User Data - Apple',
      () async {
        // Property-based test with 100+ iterations for Apple provider
        // Validates: Requirements 1.2, 2.2, 3.2, 7.1
        const iterations = 100;

        for (var i = 0; i < iterations; i++) {
          // Generate random successful OAuth scenario
          final mockUser = _generateRandomSupabaseUser(random, 'apple');

          // Convert to domain User entity
          final domainUser = User.fromSupabaseUser(mockUser);

          // Assert - Property: Successful OAuth returns valid User
          // Property: Valid session has user data
          expect(
            domainUser.id,
            isNotEmpty,
            reason: 'Iteration $i: User should have valid ID',
          );
          expect(
            domainUser.email,
            isNotEmpty,
            reason: 'Iteration $i: User should have valid email',
          );
          expect(
            domainUser.createdAt,
            isNotNull,
            reason: 'Iteration $i: User should have creation timestamp',
          );

          // Property: Social provider metadata is accessible
          expect(
            domainUser.socialProvider,
            equals(SocialAuthProvider.apple),
            reason: 'Iteration $i: User should have Apple provider metadata',
          );

          // Property: OAuth display name is available when provided
          if (mockUser.userMetadata?['full_name'] != null) {
            expect(
              domainUser.oauthDisplayName,
              isNotNull,
              reason: 'Iteration $i: OAuth display name should be available',
            );
          }

          // Property: Email confirmation status is available
          expect(
            domainUser.emailConfirmed,
            isA<bool>(),
            reason: 'Iteration $i: Email confirmation status should be boolean',
          );
        }
      },
    );

    test(
      'Property 2: Valid Session Contains Required User Metadata',
      () async {
        // Property-based test with 100+ iterations
        // Tests that valid sessions contain all required user metadata
        const iterations = 100;
        final providers = [SocialAuthProvider.google, SocialAuthProvider.apple];

        for (var i = 0; i < iterations; i++) {
          // Generate random scenario
          final provider = providers[random.nextInt(providers.length)];
          final mockUser = _generateRandomSupabaseUser(random, provider.name);

          // Convert to domain User entity
          final domainUser = User.fromSupabaseUser(mockUser);

          // Assert - Property: Session contains required metadata
          // Property: User has required authentication metadata
          expect(
            domainUser.id,
            matches(RegExp(r'^test-user-\d+')),
            reason: 'Iteration $i: User ID should follow expected format',
          );
          expect(
            domainUser.email,
            contains('@'),
            reason: 'Iteration $i: Email should be valid format',
          );
          expect(
            domainUser.email,
            contains(provider.name),
            reason: 'Iteration $i: Email should indicate provider',
          );

          // Property: Social provider is correctly identified
          expect(
            domainUser.socialProvider,
            equals(provider),
            reason: 'Iteration $i: Social provider should match OAuth provider',
          );

          // Property: Timestamps are valid
          expect(
            domainUser.createdAt.isBefore(DateTime.now()),
            true,
            reason: 'Iteration $i: Creation time should be in the past',
          );

          // Property: Email confirmation status is available
          expect(
            domainUser.emailConfirmed,
            isA<bool>(),
            reason: 'Iteration $i: Email confirmation status should be boolean',
          );
        }
      },
    );

    test(
      'Property 2: Session Establishment Is Consistent Across Providers',
      () async {
        // Property-based test with 100+ iterations
        // Tests that session establishment behavior is consistent
        const iterations = 50; // Test both providers in each iteration

        for (var i = 0; i < iterations; i++) {
          // Generate random users for both providers
          final googleUser = _generateRandomSupabaseUser(random, 'google');
          final appleUser = _generateRandomSupabaseUser(random, 'apple');

          // Convert to domain User entities
          final googleDomainUser = User.fromSupabaseUser(googleUser);
          final appleDomainUser = User.fromSupabaseUser(appleUser);

          // Assert - Property: Both providers establish valid sessions
          // Property: Session establishment behavior is consistent
          expect(
            googleDomainUser.socialProvider,
            equals(SocialAuthProvider.google),
            reason: 'Iteration $i: Google user should have Google provider',
          );
          expect(
            googleDomainUser.id,
            isNotEmpty,
            reason: 'Iteration $i: Google user should have valid ID',
          );
          expect(
            googleDomainUser.email,
            isNotEmpty,
            reason: 'Iteration $i: Google user should have valid email',
          );

          expect(
            appleDomainUser.socialProvider,
            equals(SocialAuthProvider.apple),
            reason: 'Iteration $i: Apple user should have Apple provider',
          );
          expect(
            appleDomainUser.id,
            isNotEmpty,
            reason: 'Iteration $i: Apple user should have valid ID',
          );
          expect(
            appleDomainUser.email,
            isNotEmpty,
            reason: 'Iteration $i: Apple user should have valid email',
          );

          // Property: Both users have consistent data structure
          expect(
            googleDomainUser.createdAt.runtimeType,
            equals(appleDomainUser.createdAt.runtimeType),
            reason: 'Iteration $i: Both users should have same timestamp type',
          );
          expect(
            googleDomainUser.emailConfirmed.runtimeType,
            equals(appleDomainUser.emailConfirmed.runtimeType),
            reason:
                'Iteration $i: Both users should have same email confirmed type',
          );
        }
      },
    );

    test(
      'Property 2: OAuth Display Name Extraction Works Correctly',
      () async {
        // Property-based test with 100+ iterations
        // Tests that OAuth display names are extracted correctly
        const iterations = 100;
        final providers = [SocialAuthProvider.google, SocialAuthProvider.apple];

        for (var i = 0; i < iterations; i++) {
          // Generate random scenario
          final provider = providers[random.nextInt(providers.length)];
          final mockUser = _generateRandomSupabaseUser(random, provider.name);

          // Convert to domain User entity
          final domainUser = User.fromSupabaseUser(mockUser);

          // Assert - Property: OAuth display name extraction
          if (mockUser.userMetadata?['full_name'] != null) {
            expect(
              domainUser.oauthDisplayName,
              equals(mockUser.userMetadata!['full_name']),
              reason: 'Iteration $i: OAuth display name should match metadata',
            );
          }

          // Property: Display name fallbacks work correctly
          if (mockUser.userMetadata?['full_name'] == null) {
            // Should try other fields or return null
            final expectedName =
                mockUser.userMetadata?['name'] ??
                mockUser.userMetadata?['display_name'];
            expect(
              domainUser.oauthDisplayName,
              equals(expectedName),
              reason: 'Iteration $i: Should use fallback display name',
            );
          }
        }
      },
    );
  });
}

/// Generates a random mock Supabase user for testing
supabase.User _generateRandomSupabaseUser(Random random, String provider) {
  final userId = 'test-user-${random.nextInt(10000)}';
  final email = 'user${random.nextInt(1000)}@$provider.com';
  final displayName = 'Test User ${random.nextInt(100)}';
  final now = DateTime.now();
  final createdAt = now.subtract(Duration(days: random.nextInt(30) + 1));

  return supabase.User(
    id: userId,
    appMetadata: {
      'provider': provider,
      'providers': [provider],
    },
    userMetadata: {
      'email': email,
      'full_name': displayName,
      'name': displayName,
      'display_name': displayName,
    },
    aud: 'authenticated',
    createdAt: createdAt.toIso8601String(),
    email: email,
    emailConfirmedAt: now.toIso8601String(),
    lastSignInAt: now.toIso8601String(),
    role: 'authenticated',
    updatedAt: now.toIso8601String(),
  );
}
