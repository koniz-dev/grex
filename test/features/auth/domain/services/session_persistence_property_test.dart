import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/services/simple_session_service.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/supabase_mocks.dart';

/// **Property 21: Session Persistence Across App Restarts**
/// **Validates: Requirements 7.2**
///
/// For any valid social auth session, when the app restarts, the system should
/// automatically restore the authenticated state without requiring re-login.
void main() {
  group('Property 21: Session Persistence Across App Restarts', () {
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
      'should restore session after app restart for Google OAuth users',
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
            userMetadata: {
              'full_name': displayName,
              'provider': 'google',
            },
          );

          // Create mock session
          final mockSession = _createMockSession(
            user: mockSupabaseUser,
            expiresAt:
                DateTime.now()
                    .add(const Duration(hours: 1))
                    .millisecondsSinceEpoch ~/
                1000,
          );

          // Simulate app restart - session should be restored
          when(mockAuth.currentSession).thenReturn(mockSession);
          when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

          // Verify session is valid after restart
          final hasValidSession = await sessionService.hasValidSession();
          expect(
            hasValidSession,
            isTrue,
            reason:
                'Session should be valid after app restart for iteration $i',
          );

          // Verify user is restored
          final currentUser = sessionService.getCurrentUser();
          expect(
            currentUser,
            isNotNull,
            reason:
                'User should be restored after app restart for iteration $i',
          );
          expect(
            currentUser!.id,
            equals(userId),
            reason: 'User ID should match for iteration $i',
          );
          expect(
            currentUser.email,
            equals(email),
            reason: 'User email should match for iteration $i',
          );
          expect(
            currentUser.socialProvider,
            equals(SocialAuthProvider.google),
            reason: 'Social provider should be Google for iteration $i',
          );

          // Verify authentication method is detected correctly
          final authMethod = sessionService.getAuthenticationMethod();
          expect(
            authMethod,
            equals('google'),
            reason: 'Authentication method should be google for iteration $i',
          );

          // Verify it's recognized as social login user
          final isSocialUser = sessionService.isSocialLoginUser();
          expect(
            isSocialUser,
            isTrue,
            reason:
                'Should be recognized as social login user for iteration $i',
          );
        }
      },
    );

    test(
      'should restore session after app restart for Apple OAuth users',
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
            userMetadata: {
              'name': displayName,
              'provider': 'apple',
            },
          );

          // Create mock session
          final mockSession = _createMockSession(
            user: mockSupabaseUser,
            expiresAt:
                DateTime.now()
                    .add(const Duration(hours: 1))
                    .millisecondsSinceEpoch ~/
                1000,
          );

          // Simulate app restart - session should be restored
          when(mockAuth.currentSession).thenReturn(mockSession);
          when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

          // Verify session is valid after restart
          final hasValidSession = await sessionService.hasValidSession();
          expect(
            hasValidSession,
            isTrue,
            reason:
                'Session should be valid after app restart for iteration $i',
          );

          // Verify user is restored
          final currentUser = sessionService.getCurrentUser();
          expect(
            currentUser,
            isNotNull,
            reason:
                'User should be restored after app restart for iteration $i',
          );
          expect(
            currentUser!.id,
            equals(userId),
            reason: 'User ID should match for iteration $i',
          );
          expect(
            currentUser.email,
            equals(email),
            reason: 'User email should match for iteration $i',
          );
          expect(
            currentUser.socialProvider,
            equals(SocialAuthProvider.apple),
            reason: 'Social provider should be Apple for iteration $i',
          );

          // Verify authentication method is detected correctly
          final authMethod = sessionService.getAuthenticationMethod();
          expect(
            authMethod,
            equals('apple'),
            reason: 'Authentication method should be apple for iteration $i',
          );

          // Verify it's recognized as social login user
          final isSocialUser = sessionService.isSocialLoginUser();
          expect(
            isSocialUser,
            isTrue,
            reason:
                'Should be recognized as social login user for iteration $i',
          );
        }
      },
    );

    test('should restore session after app restart for email users', () async {
      // Property test with 100+ iterations for email users
      for (var i = 0; i < 100; i++) {
        // Generate test data
        final userId = 'email-user-$i';
        final email = 'user$i@example.com';
        final displayName = 'Email User $i';

        // Create mock Supabase user with email authentication (no OAuth
        // providers)
        final mockSupabaseUser = _createMockSupabaseUser(
          id: userId,
          email: email,
          displayName: displayName,
          providers: ['email'], // Email authentication
          userMetadata: {
            'display_name': displayName,
          },
        );

        // Create mock session
        final mockSession = _createMockSession(
          user: mockSupabaseUser,
          expiresAt:
              DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch ~/
              1000,
        );

        // Simulate app restart - session should be restored
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

        // Verify session is valid after restart
        final hasValidSession = await sessionService.hasValidSession();
        expect(
          hasValidSession,
          isTrue,
          reason: 'Session should be valid after app restart for iteration $i',
        );

        // Verify user is restored
        final currentUser = sessionService.getCurrentUser();
        expect(
          currentUser,
          isNotNull,
          reason: 'User should be restored after app restart for iteration $i',
        );
        expect(
          currentUser!.id,
          equals(userId),
          reason: 'User ID should match for iteration $i',
        );
        expect(
          currentUser.email,
          equals(email),
          reason: 'User email should match for iteration $i',
        );
        expect(
          currentUser.socialProvider,
          isNull,
          reason:
              'Social provider should be null for email users for iteration $i',
        );

        // Verify authentication method is detected correctly
        final authMethod = sessionService.getAuthenticationMethod();
        expect(
          authMethod,
          equals('email'),
          reason: 'Authentication method should be email for iteration $i',
        );

        // Verify it's not recognized as social login user
        final isSocialUser = sessionService.isSocialLoginUser();
        expect(
          isSocialUser,
          isFalse,
          reason:
              'Should not be recognized as social login user for iteration $i',
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
  Map<String, dynamic>? userMetadata,
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
  when(mockUser.userMetadata).thenReturn(userMetadata ?? {});
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
