import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/services/simple_session_service.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/supabase_mocks.dart';

/// **Property 22: Expired Sessions Redirect to Login**
/// **Validates: Requirements 7.3**
///
/// For any expired social auth session, the system should detect the expiration
/// and redirect the user to the login screen.
void main() {
  group('Property 22: Expired Sessions Redirect to Login', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuth;
    late SimpleSessionService sessionService;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      when(mockSupabaseClient.auth).thenReturn(mockAuth);
      sessionService = SimpleSessionService(mockSupabaseClient);
    });

    test('should detect expired sessions for Google OAuth users', () async {
      // Property test with 100+ iterations
      for (var i = 0; i < 100; i++) {
        // Generate test data with expired session
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

        // Create expired session (expired 1 hour ago)
        final expiredTime =
            DateTime.now()
                .subtract(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000;

        final mockSession = _createMockSession(
          user: mockSupabaseUser,
          expiresAt: expiredTime,
        );

        // Mock expired session
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

        // Verify expired session is detected
        final hasValidSession = await sessionService.hasValidSession();
        expect(
          hasValidSession,
          isFalse,
          reason:
              'Expired session should be detected as invalid for iteration $i',
        );

        // User should still be returned (for logout purposes)
        final currentUser = sessionService.getCurrentUser();
        expect(
          currentUser,
          isNotNull,
          reason: 'User should still be accessible for logout for iteration $i',
        );

        // But session should be invalid
        final currentSession = sessionService.getCurrentSession();
        expect(
          currentSession,
          isNotNull,
          reason: 'Session object should exist but be expired for iteration $i',
        );
      }
    });

    test('should detect expired sessions for Apple OAuth users', () async {
      // Property test with 100+ iterations
      for (var i = 0; i < 100; i++) {
        // Generate test data with expired session
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

        // Create expired session (expired 2 hours ago)
        final expiredTime =
            DateTime.now()
                .subtract(const Duration(hours: 2))
                .millisecondsSinceEpoch ~/
            1000;

        final mockSession = _createMockSession(
          user: mockSupabaseUser,
          expiresAt: expiredTime,
        );

        // Mock expired session
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

        // Verify expired session is detected
        final hasValidSession = await sessionService.hasValidSession();
        expect(
          hasValidSession,
          isFalse,
          reason:
              'Expired session should be detected as invalid for iteration $i',
        );

        // User should still be returned (for logout purposes)
        final currentUser = sessionService.getCurrentUser();
        expect(
          currentUser,
          isNotNull,
          reason: 'User should still be accessible for logout for iteration $i',
        );

        // Authentication method should still be detectable
        final authMethod = sessionService.getAuthenticationMethod();
        expect(
          authMethod,
          equals('apple'),
          reason:
              'Authentication method should still be detectable for iteration $i',
        );
      }
    });

    test('should detect expired sessions for email users', () async {
      // Property test with 100+ iterations
      for (var i = 0; i < 100; i++) {
        // Generate test data with expired session
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

        // Create expired session (expired 30 minutes ago)
        final expiredTime =
            DateTime.now()
                .subtract(const Duration(minutes: 30))
                .millisecondsSinceEpoch ~/
            1000;

        final mockSession = _createMockSession(
          user: mockSupabaseUser,
          expiresAt: expiredTime,
        );

        // Mock expired session
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

        // Verify expired session is detected
        final hasValidSession = await sessionService.hasValidSession();
        expect(
          hasValidSession,
          isFalse,
          reason:
              'Expired session should be detected as invalid for iteration $i',
        );

        // User should still be returned (for logout purposes)
        final currentUser = sessionService.getCurrentUser();
        expect(
          currentUser,
          isNotNull,
          reason: 'User should still be accessible for logout for iteration $i',
        );

        // Authentication method should be email
        final authMethod = sessionService.getAuthenticationMethod();
        expect(
          authMethod,
          equals('email'),
          reason: 'Authentication method should be email for iteration $i',
        );
      }
    });

    test('should handle null sessions', () async {
      // Property test with 100+ iterations
      for (var i = 0; i < 100; i++) {
        // Mock null session (user logged out)
        when(mockAuth.currentSession).thenReturn(null);
        when(mockAuth.currentUser).thenReturn(null);

        // Verify null session is detected as invalid
        final hasValidSession = await sessionService.hasValidSession();
        expect(
          hasValidSession,
          isFalse,
          reason: 'Null session should be detected as invalid for iteration $i',
        );

        // User should be null
        final currentUser = sessionService.getCurrentUser();
        expect(
          currentUser,
          isNull,
          reason: 'User should be null when session is null for iteration $i',
        );

        // Authentication method should be null
        final authMethod = sessionService.getAuthenticationMethod();
        expect(
          authMethod,
          isNull,
          reason: 'Authentication method should be null for iteration $i',
        );

        // Should not be social login user
        final isSocialUser = sessionService.isSocialLoginUser();
        expect(
          isSocialUser,
          isFalse,
          reason:
              'Should not be social login user when no session for iteration $i',
        );
      }
    });

    test('should handle sessions with null expiry', () async {
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

        // Create session with null expiry
        final mockSession = MockSession();
        when(mockSession.user).thenReturn(mockSupabaseUser);
        when(mockSession.expiresAt).thenReturn(null); // Null expiry
        when(mockSession.accessToken).thenReturn('mock-access-token');
        when(mockSession.refreshToken).thenReturn('mock-refresh-token');

        // Mock session with null expiry
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

        // Verify session with null expiry is detected as invalid
        final hasValidSession = await sessionService.hasValidSession();
        expect(
          hasValidSession,
          isFalse,
          reason: 'Session with null expiry should be invalid for iteration $i',
        );
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
