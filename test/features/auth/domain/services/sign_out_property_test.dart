import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/services/simple_session_service.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../helpers/supabase_mocks.dart';

/// **Property 24: Sign Out Revokes Session and Clears Data**
/// **Validates: Requirements 7.5**
///
/// For any authenticated user who signs out, the system should revoke the
/// social auth session and clear all cached authentication data.
void main() {
  group('Property 24: Sign Out Revokes Session and Clears Data', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuth;
    late SimpleSessionService sessionService;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      when(mockSupabaseClient.auth).thenReturn(mockAuth);
      sessionService = SimpleSessionService(mockSupabaseClient);
    });

    test('should revoke session and clear data for Google OAuth users', () async {
      // Property test with 100+ iterations
      for (var i = 0; i < 100; i++) {
        // Generate test data
        final userId = 'google-user-$i';
        final email = 'user$i@gmail.com';
        final displayName = 'Google User $i';

        // Create mock Supabase user with Google OAuth metadata
        final mockSupabaseUser = _createMockSupabaseUser(
          id: userId,
          email: email,
          displayName: displayName,
          providers: ['google'],
        );

        // Create valid session
        final mockSession = _createMockSession(
          user: mockSupabaseUser,
          expiresAt:
              DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch ~/
              1000,
        );

        // Setup initial authenticated state
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

        // Verify user is initially authenticated
        final initialUser = sessionService.getCurrentUser();
        expect(
          initialUser,
          isNotNull,
          reason: 'User should be authenticated initially for iteration $i',
        );
        expect(
          initialUser!.socialProvider,
          equals(SocialAuthProvider.google),
          reason: 'Should be Google user for iteration $i',
        );

        final initialSession = await sessionService.hasValidSession();
        expect(
          initialSession,
          isTrue,
          reason: 'Session should be valid initially for iteration $i',
        );

        // Mock successful sign out
        when(mockAuth.signOut()).thenAnswer((_) async {
          // Simulate session clearing after sign out
          when(mockAuth.currentSession).thenReturn(null);
          when(mockAuth.currentUser).thenReturn(null);
        });

        // Perform sign out
        await sessionService.signOut();

        // Verify sign out was called
        verify(mockAuth.signOut()).called(1);

        // Verify session is cleared
        final postSignOutUser = sessionService.getCurrentUser();
        expect(
          postSignOutUser,
          isNull,
          reason: 'User should be null after sign out for iteration $i',
        );

        final postSignOutSession = await sessionService.hasValidSession();
        expect(
          postSignOutSession,
          isFalse,
          reason: 'Session should be invalid after sign out for iteration $i',
        );

        // Verify authentication method is null
        final authMethod = sessionService.getAuthenticationMethod();
        expect(
          authMethod,
          isNull,
          reason:
              'Authentication method should be null after sign out for iteration $i',
        );

        // Verify not recognized as social login user
        final isSocialUser = sessionService.isSocialLoginUser();
        expect(
          isSocialUser,
          isFalse,
          reason:
              'Should not be social login user after sign out for iteration $i',
        );

        // Reset mocks for next iteration
        reset(mockAuth);
        when(mockSupabaseClient.auth).thenReturn(mockAuth);
      }
    });

    test(
      'should revoke session and clear data for Apple OAuth users',
      () async {
        // Property test with 100+ iterations
        for (var i = 0; i < 100; i++) {
          // Generate test data
          final userId = 'apple-user-$i';
          final email = 'user$i@privaterelay.appleid.com';
          final displayName = 'Apple User $i';

          // Create mock Supabase user with Apple OAuth metadata
          final mockSupabaseUser = _createMockSupabaseUser(
            id: userId,
            email: email,
            displayName: displayName,
            providers: ['apple'],
          );

          // Create valid session
          final mockSession = _createMockSession(
            user: mockSupabaseUser,
            expiresAt:
                DateTime.now()
                    .add(const Duration(hours: 1))
                    .millisecondsSinceEpoch ~/
                1000,
          );

          // Setup initial authenticated state
          when(mockAuth.currentSession).thenReturn(mockSession);
          when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

          // Verify user is initially authenticated
          final initialUser = sessionService.getCurrentUser();
          expect(
            initialUser,
            isNotNull,
            reason: 'User should be authenticated initially for iteration $i',
          );
          expect(
            initialUser!.socialProvider,
            equals(SocialAuthProvider.apple),
            reason: 'Should be Apple user for iteration $i',
          );

          // Mock successful sign out
          when(mockAuth.signOut()).thenAnswer((_) async {
            // Simulate session clearing after sign out
            when(mockAuth.currentSession).thenReturn(null);
            when(mockAuth.currentUser).thenReturn(null);
          });

          // Perform sign out
          await sessionService.signOut();

          // Verify sign out was called
          verify(mockAuth.signOut()).called(1);

          // Verify session is cleared
          final postSignOutUser = sessionService.getCurrentUser();
          expect(
            postSignOutUser,
            isNull,
            reason: 'User should be null after sign out for iteration $i',
          );

          final postSignOutSession = await sessionService.hasValidSession();
          expect(
            postSignOutSession,
            isFalse,
            reason: 'Session should be invalid after sign out for iteration $i',
          );

          // Reset mocks for next iteration
          reset(mockAuth);
          when(mockSupabaseClient.auth).thenReturn(mockAuth);
        }
      },
    );

    test('should revoke session and clear data for email users', () async {
      // Property test with 100+ iterations
      for (var i = 0; i < 100; i++) {
        // Generate test data
        final userId = 'email-user-$i';
        final email = 'user$i@example.com';
        final displayName = 'Email User $i';

        // Create mock Supabase user with email authentication
        final mockSupabaseUser = _createMockSupabaseUser(
          id: userId,
          email: email,
          displayName: displayName,
          providers: ['email'],
        );

        // Create valid session
        final mockSession = _createMockSession(
          user: mockSupabaseUser,
          expiresAt:
              DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch ~/
              1000,
        );

        // Setup initial authenticated state
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

        // Verify user is initially authenticated
        final initialUser = sessionService.getCurrentUser();
        expect(
          initialUser,
          isNotNull,
          reason: 'User should be authenticated initially for iteration $i',
        );
        expect(
          initialUser!.socialProvider,
          isNull,
          reason: 'Should be email user (no social provider) for iteration $i',
        );

        final authMethod = sessionService.getAuthenticationMethod();
        expect(
          authMethod,
          equals('email'),
          reason: 'Should be email authentication for iteration $i',
        );

        // Mock successful sign out
        when(mockAuth.signOut()).thenAnswer((_) async {
          // Simulate session clearing after sign out
          when(mockAuth.currentSession).thenReturn(null);
          when(mockAuth.currentUser).thenReturn(null);
        });

        // Perform sign out
        await sessionService.signOut();

        // Verify sign out was called
        verify(mockAuth.signOut()).called(1);

        // Verify session is cleared
        final postSignOutUser = sessionService.getCurrentUser();
        expect(
          postSignOutUser,
          isNull,
          reason: 'User should be null after sign out for iteration $i',
        );

        final postSignOutSession = await sessionService.hasValidSession();
        expect(
          postSignOutSession,
          isFalse,
          reason: 'Session should be invalid after sign out for iteration $i',
        );

        // Reset mocks for next iteration
        reset(mockAuth);
        when(mockSupabaseClient.auth).thenReturn(mockAuth);
      }
    });

    test('should handle sign out failures gracefully', () async {
      // Property test with 100+ iterations
      for (var i = 0; i < 100; i++) {
        // Generate test data
        final userId = 'user-$i';
        final email = 'user$i@example.com';

        final mockSupabaseUser = _createMockSupabaseUser(
          id: userId,
          email: email,
          displayName: 'User $i',
          providers: ['google'],
        );

        final mockSession = _createMockSession(
          user: mockSupabaseUser,
          expiresAt:
              DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch ~/
              1000,
        );

        // Setup initial authenticated state
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

        // Mock sign out failure
        when(
          mockAuth.signOut(),
        ).thenThrow(const AuthException('Network error during sign out'));

        // Sign out should throw exception
        await expectLater(
          sessionService.signOut(),
          throwsA(isA<AuthException>()),
          reason: 'Sign out should throw exception for iteration $i',
        );

        // Verify sign out was attempted
        verify(mockAuth.signOut()).called(1);

        // User might still be present (sign out failed)
        final postSignOutUser = sessionService.getCurrentUser();
        expect(
          postSignOutUser,
          isNotNull,
          reason:
              'User might still be present after failed sign out for iteration $i',
        );

        // Reset mocks for next iteration
        reset(mockAuth);
        when(mockSupabaseClient.auth).thenReturn(mockAuth);
      }
    });

    test('should handle multiple sign out calls', () async {
      // Property test with 100+ iterations
      for (var i = 0; i < 100; i++) {
        // Generate test data
        final userId = 'user-$i';
        final email = 'user$i@example.com';

        final mockSupabaseUser = _createMockSupabaseUser(
          id: userId,
          email: email,
          displayName: 'User $i',
          providers: ['apple'],
        );

        final mockSession = _createMockSession(
          user: mockSupabaseUser,
          expiresAt:
              DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch ~/
              1000,
        );

        // Setup initial authenticated state
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

        // Mock successful sign out
        when(mockAuth.signOut()).thenAnswer((_) async {
          // Simulate session clearing after sign out
          when(mockAuth.currentSession).thenReturn(null);
          when(mockAuth.currentUser).thenReturn(null);
        });

        // Perform multiple sign out calls
        await sessionService.signOut();
        await sessionService.signOut();
        await sessionService.signOut();

        // Verify sign out was called multiple times
        verify(mockAuth.signOut()).called(3);

        // Session should still be cleared
        final postSignOutUser = sessionService.getCurrentUser();
        expect(
          postSignOutUser,
          isNull,
          reason:
              'User should be null after multiple sign outs for iteration $i',
        );

        // Reset mocks for next iteration
        reset(mockAuth);
        when(mockSupabaseClient.auth).thenReturn(mockAuth);
      }
    });
  });
}

/// Helper function to create mock Supabase user
MockUser _createMockSupabaseUser({
  required String id,
  required String email,
  required String displayName,
  required List<String> providers,
}) {
  final mockUser = MockUser();
  when(mockUser.id).thenReturn(id);
  when(mockUser.email).thenReturn(email);
  when(mockUser.emailConfirmedAt).thenReturn(DateTime.now().toIso8601String());
  when(mockUser.createdAt).thenReturn(DateTime.now().toIso8601String());
  when(mockUser.lastSignInAt).thenReturn(DateTime.now().toIso8601String());
  when(mockUser.appMetadata).thenReturn({
    'providers': providers,
  });
  when(mockUser.userMetadata).thenReturn({
    'display_name': displayName,
  });
  return mockUser;
}

/// Helper function to create mock session
MockSession _createMockSession({
  required MockUser user,
  required int expiresAt,
}) {
  final mockSession = MockSession();
  when(mockSession.user).thenReturn(user);
  when(mockSession.expiresAt).thenReturn(expiresAt);
  when(mockSession.accessToken).thenReturn('mock-access-token');
  when(mockSession.refreshToken).thenReturn('mock-refresh-token');
  return mockSession;
}
