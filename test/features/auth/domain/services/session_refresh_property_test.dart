import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/services/simple_session_service.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../helpers/supabase_mocks.dart';

/// **Property 25: Automatic Session Refresh Before Expiration**
/// **Validates: Requirements 7.6**
///
/// For any social auth session approaching expiration, the system should
/// automatically refresh the session tokens before they expire.
void main() {
  group('Property 25: Automatic Session Refresh Before Expiration', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuth;
    late SimpleSessionService sessionService;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      when(mockSupabaseClient.auth).thenReturn(mockAuth);
      sessionService = SimpleSessionService(mockSupabaseClient);
    });

    test(
      'should refresh session successfully for Google OAuth users',
      () async {
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

          // Create session that's about to expire (expires in 5 minutes)
          final nearExpiryTime =
              DateTime.now()
                  .add(const Duration(minutes: 5))
                  .millisecondsSinceEpoch ~/
              1000;

          final mockSession = _createMockSession(
            user: mockSupabaseUser,
            expiresAt: nearExpiryTime,
          );

          // Create refreshed session (expires in 1 hour)
          final refreshedUser = _createMockSupabaseUser(
            id: userId,
            email: email,
            displayName: displayName,
            providers: ['google'],
          );

          final refreshedSession = _createMockSession(
            user: refreshedUser,
            expiresAt:
                DateTime.now()
                    .add(const Duration(hours: 1))
                    .millisecondsSinceEpoch ~/
                1000,
          );

          // Setup initial session
          when(mockAuth.currentSession).thenReturn(mockSession);
          when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

          // Mock successful refresh
          final mockAuthResponse = MockAuthResponse();
          when(mockAuthResponse.session).thenReturn(refreshedSession);
          when(
            mockAuth.refreshSession(),
          ).thenAnswer((_) async => mockAuthResponse);

          // Verify initial session is valid but near expiry
          final initialSessionValid = await sessionService.hasValidSession();
          expect(
            initialSessionValid,
            isTrue,
            reason: 'Initial session should be valid for iteration $i',
          );

          // Perform session refresh
          final refreshSuccess = await sessionService.refreshSession();
          expect(
            refreshSuccess,
            isTrue,
            reason: 'Session refresh should succeed for iteration $i',
          );

          // Verify refresh was called
          verify(mockAuth.refreshSession()).called(1);

          // User should still be accessible
          final currentUser = sessionService.getCurrentUser();
          expect(
            currentUser,
            isNotNull,
            reason: 'User should be accessible after refresh for iteration $i',
          );
          expect(
            currentUser!.id,
            equals(userId),
            reason: 'User ID should remain same after refresh for iteration $i',
          );
          expect(
            currentUser.socialProvider,
            equals(SocialAuthProvider.google),
            reason: 'Social provider should remain Google for iteration $i',
          );

          // Authentication method should remain the same
          final authMethod = sessionService.getAuthenticationMethod();
          expect(
            authMethod,
            equals('google'),
            reason:
                'Authentication method should remain google for iteration $i',
          );

          // Reset mocks for next iteration
          reset(mockAuth);
          reset(mockAuthResponse);
          when(mockSupabaseClient.auth).thenReturn(mockAuth);
        }
      },
    );

    test('should refresh session successfully for Apple OAuth users', () async {
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

        // Create session that's about to expire
        final nearExpiryTime =
            DateTime.now()
                .add(const Duration(minutes: 3))
                .millisecondsSinceEpoch ~/
            1000;

        final mockSession = _createMockSession(
          user: mockSupabaseUser,
          expiresAt: nearExpiryTime,
        );

        // Create refreshed session
        final refreshedUser = _createMockSupabaseUser(
          id: userId,
          email: email,
          displayName: displayName,
          providers: ['apple'],
        );

        final refreshedSession = _createMockSession(
          user: refreshedUser,
          expiresAt:
              DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch ~/
              1000,
        );

        // Setup initial session
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

        // Mock successful refresh
        final mockAuthResponse = MockAuthResponse();
        when(mockAuthResponse.session).thenReturn(refreshedSession);
        when(
          mockAuth.refreshSession(),
        ).thenAnswer((_) async => mockAuthResponse);

        // Perform session refresh
        final refreshSuccess = await sessionService.refreshSession();
        expect(
          refreshSuccess,
          isTrue,
          reason:
              'Session refresh should succeed for Apple user for iteration $i',
        );

        // Verify refresh was called
        verify(mockAuth.refreshSession()).called(1);

        // User should still be accessible with Apple provider
        final currentUser = sessionService.getCurrentUser();
        expect(
          currentUser,
          isNotNull,
          reason: 'User should be accessible after refresh for iteration $i',
        );
        expect(
          currentUser!.socialProvider,
          equals(SocialAuthProvider.apple),
          reason: 'Social provider should remain Apple for iteration $i',
        );

        // Reset mocks for next iteration
        reset(mockAuth);
        reset(mockAuthResponse);
        when(mockSupabaseClient.auth).thenReturn(mockAuth);
      }
    });

    test('should refresh session successfully for email users', () async {
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

        // Create session that's about to expire
        final nearExpiryTime =
            DateTime.now()
                .add(const Duration(minutes: 2))
                .millisecondsSinceEpoch ~/
            1000;

        final mockSession = _createMockSession(
          user: mockSupabaseUser,
          expiresAt: nearExpiryTime,
        );

        // Create refreshed session
        final refreshedUser = _createMockSupabaseUser(
          id: userId,
          email: email,
          displayName: displayName,
          providers: ['email'],
        );

        final refreshedSession = _createMockSession(
          user: refreshedUser,
          expiresAt:
              DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch ~/
              1000,
        );

        // Setup initial session
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

        // Mock successful refresh
        final mockAuthResponse = MockAuthResponse();
        when(mockAuthResponse.session).thenReturn(refreshedSession);
        when(
          mockAuth.refreshSession(),
        ).thenAnswer((_) async => mockAuthResponse);

        // Perform session refresh
        final refreshSuccess = await sessionService.refreshSession();
        expect(
          refreshSuccess,
          isTrue,
          reason:
              'Session refresh should succeed for email user for iteration $i',
        );

        // Verify refresh was called
        verify(mockAuth.refreshSession()).called(1);

        // User should still be accessible
        final currentUser = sessionService.getCurrentUser();
        expect(
          currentUser,
          isNotNull,
          reason: 'User should be accessible after refresh for iteration $i',
        );
        expect(
          currentUser!.socialProvider,
          isNull,
          reason:
              'Social provider should be null for email users for iteration $i',
        );

        // Authentication method should be email
        final authMethod = sessionService.getAuthenticationMethod();
        expect(
          authMethod,
          equals('email'),
          reason: 'Authentication method should be email for iteration $i',
        );

        // Reset mocks for next iteration
        reset(mockAuth);
        reset(mockAuthResponse);
        when(mockSupabaseClient.auth).thenReturn(mockAuth);
      }
    });

    test('should handle refresh failures gracefully', () async {
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

        // Create session that's about to expire
        final nearExpiryTime =
            DateTime.now()
                .add(const Duration(minutes: 1))
                .millisecondsSinceEpoch ~/
            1000;

        final mockSession = _createMockSession(
          user: mockSupabaseUser,
          expiresAt: nearExpiryTime,
        );

        // Setup initial session
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

        // Mock refresh failure
        when(
          mockAuth.refreshSession(),
        ).thenThrow(const AuthException('Refresh token expired'));

        // Perform session refresh
        final refreshSuccess = await sessionService.refreshSession();
        expect(
          refreshSuccess,
          isFalse,
          reason: 'Session refresh should fail gracefully for iteration $i',
        );

        // Verify refresh was attempted
        verify(mockAuth.refreshSession()).called(1);

        // User should still be accessible (for logout purposes)
        final currentUser = sessionService.getCurrentUser();
        expect(
          currentUser,
          isNotNull,
          reason:
              'User should still be accessible after failed refresh for '
              'iteration $i',
        );

        // Reset mocks for next iteration
        reset(mockAuth);
        when(mockSupabaseClient.auth).thenReturn(mockAuth);
      }
    });

    test('should handle null session refresh response', () async {
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
                  .add(const Duration(minutes: 5))
                  .millisecondsSinceEpoch ~/
              1000,
        );

        // Setup initial session
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

        // Mock refresh response with null session
        final mockAuthResponse = MockAuthResponse();
        when(mockAuthResponse.session).thenReturn(null);
        when(
          mockAuth.refreshSession(),
        ).thenAnswer((_) async => mockAuthResponse);

        // Perform session refresh
        final refreshSuccess = await sessionService.refreshSession();
        expect(
          refreshSuccess,
          isFalse,
          reason:
              'Session refresh should fail when response session is null for '
              'iteration $i',
        );

        // Verify refresh was attempted
        verify(mockAuth.refreshSession()).called(1);

        // Reset mocks for next iteration
        reset(mockAuth);
        reset(mockAuthResponse);
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
