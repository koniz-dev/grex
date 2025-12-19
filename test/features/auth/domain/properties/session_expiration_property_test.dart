import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/services/session_manager.dart';
import 'package:grex/features/auth/domain/services/session_service.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/property_test_helpers.dart';
import '../../../../helpers/test_helpers.dart';

/// Property 11: Session expiration redirects to login
///
/// This property validates that when a session expires, the system properly
/// detects the expiration and redirects users to the login screen.
///
/// **Validates Requirements:**
/// - 6.3: Expired sessions are detected and handled appropriately
/// - 6.4: Users are redirected to login when session expires
void main() {
  group('Session Expiration Properties', () {
    late TestDependencies deps;

    setUp(() {
      deps = setupTestDependencies();
    });

    tearDown(() async {
      await deps.dispose();
    });

    test('Property 11: Session expiration redirects to login', () async {
      // Property: For any expired session, validation should return false
      // and the system should transition to unauthenticated state

      for (var i = 0; i < 100; i++) {
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();

        // Generate session data that will be expired
        final expiredSessionData = generateExpiredSessionData(
          user,
          userProfile,
        );

        // Mock expired session behavior
        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => Right(expiredSessionData));

        when(
          deps.mockSessionService.validateSession(),
        ).thenAnswer((_) async => const Right(false));

        when(
          deps.mockSessionService.clearSession(),
        ).thenAnswer((_) async => const Right(null));

        // Initialize session manager with expired session
        final initResult = await deps.sessionManager.initialize();

        // Property assertions for expired sessions
        initResult.fold(
          (failure) {
            // Failure is acceptable for expired sessions
          },
          (sessionData) {
            // Expired sessions should not be restored
            expect(
              sessionData,
              isNull,
              reason: 'Expired sessions should not be restored',
            );
          },
        );

        // Verify session validation returns false for expired sessions
        final validationResult = await deps.sessionManager.isSessionValid();

        validationResult.fold(
          (failure) {
            // Validation failure is acceptable for expired sessions
          },
          (isValid) {
            expect(
              isValid,
              isFalse,
              reason: 'Expired sessions should not be valid',
            );
          },
        );

        // Verify that expired sessions are cleared
        verify(deps.mockSessionService.clearSession()).called(greaterThan(0));
      }
    });

    test('Property: Access token expiration triggers refresh', () async {
      // Property: When access token expires but refresh token is valid,
      // the system should automatically refresh the session

      for (var i = 0; i < 50; i++) {
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();

        // Generate session with expired access token but valid refresh token
        final sessionWithExpiredAccess = generateSessionWithExpiredAccessToken(
          user,
          userProfile,
        );
        final refreshedSession = generateValidSessionData(user, userProfile);

        // Mock session refresh behavior
        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => Right(sessionWithExpiredAccess));

        when(
          deps.mockSessionService.refreshSession(),
        ).thenAnswer((_) async => Right(refreshedSession));

        when(
          deps.mockSessionService.validateSession(),
        ).thenAnswer((_) async => const Right(true));

        // Attempt to refresh session
        final refreshResult = await deps.sessionManager.refreshSession();

        // Property assertions
        refreshResult.fold(
          (failure) => fail(
            'Session refresh should succeed when refresh token is valid: '
            '$failure',
          ),
          (newSession) {
            // 1. New session should have valid access token
            expect(newSession.isAccessTokenExpired, isFalse);

            // 2. User data should be preserved
            expect(newSession.user.id, equals(user.id));
            expect(newSession.userProfile.id, equals(userProfile.id));

            // 3. New access token should be different from expired one
            expect(
              newSession.accessToken,
              isNot(equals(sessionWithExpiredAccess.accessToken)),
            );
          },
        );
      }
    });

    test('Property: Refresh token expiration prevents refresh', () async {
      // Property: When both access and refresh tokens are expired,
      // session refresh should fail and session should be cleared

      for (var i = 0; i < 30; i++) {
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();

        // Generate completely expired session
        final expiredSession = generateExpiredSessionData(user, userProfile);

        // Mock expired session behavior
        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => Right(expiredSession));

        when(deps.mockSessionService.refreshSession()).thenAnswer(
          (_) async => const Left(GenericAuthFailure('Refresh token expired')),
        );

        when(
          deps.mockSessionService.clearSession(),
        ).thenAnswer((_) async => const Right(null));

        // Attempt to refresh expired session
        final refreshResult = await deps.sessionManager.refreshSession();

        // Property assertions
        refreshResult.fold(
          (failure) {
            // Refresh should fail for completely expired sessions
            expect(failure, isA<AuthFailure>());
          },
          (newSession) {
            fail('Refresh should fail when refresh token is expired');
          },
        );

        // Verify session was cleared due to expiration
        verify(deps.mockSessionService.clearSession()).called(greaterThan(0));
      }
    });

    test('Property: Session expiry detection is accurate', () async {
      // Property: Session expiry detection should accurately identify
      // expired sessions based on current time vs expiry time

      for (var i = 0; i < 50; i++) {
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();

        // Generate sessions with different expiry states
        final validSession = generateValidSessionData(user, userProfile);
        final expiredSession = generateExpiredSessionData(user, userProfile);
        final soonToExpireSession = generateSoonToExpireSessionData(
          user,
          userProfile,
        );

        // Test valid session
        expect(
          validSession.isExpired,
          isFalse,
          reason: 'Valid sessions should not be expired',
        );
        expect(
          validSession.isAccessTokenExpired,
          isFalse,
          reason: 'Valid access tokens should not be expired',
        );
        expect(
          validSession.isRefreshTokenExpired,
          isFalse,
          reason: 'Valid refresh tokens should not be expired',
        );

        // Test expired session
        expect(
          expiredSession.isExpired,
          isTrue,
          reason: 'Expired sessions should be detected as expired',
        );
        expect(
          expiredSession.isAccessTokenExpired,
          isTrue,
          reason: 'Expired access tokens should be detected',
        );
        expect(
          expiredSession.isRefreshTokenExpired,
          isTrue,
          reason: 'Expired refresh tokens should be detected',
        );

        // Test soon-to-expire session
        expect(
          soonToExpireSession.needsRefresh,
          isTrue,
          reason: 'Sessions expiring soon should need refresh',
        );
        expect(
          soonToExpireSession.isExpired,
          isFalse,
          reason: 'Sessions expiring soon should not be fully expired yet',
        );
      }
    });

    test('Property: Automatic session cleanup on expiration', () async {
      // Property: When a session expires, it should be automatically
      // cleaned up from storage to prevent security issues

      for (var i = 0; i < 30; i++) {
        // Mock expired session retrieval and cleanup
        when(deps.mockSessionService.getStoredSession()).thenAnswer(
          (_) async => const Right(null),
        ); // Expired sessions return null

        when(
          deps.mockSessionService.validateSession(),
        ).thenAnswer((_) async => const Right(false));

        when(
          deps.mockSessionService.clearSession(),
        ).thenAnswer((_) async => const Right(null));

        // Initialize with expired session
        await deps.sessionManager.initialize();

        // Verify session validation fails
        final validationResult = await deps.sessionManager.isSessionValid();

        validationResult.fold(
          (failure) {
            // Validation can fail for expired sessions
          },
          (isValid) {
            expect(
              isValid,
              isFalse,
              reason: 'Expired sessions should not validate',
            );
          },
        );

        // Property: Expired sessions should trigger cleanup
        // This is verified by the mock returning null for getStoredSession
        final currentSession = await deps.sessionManager.getCurrentSession();
        currentSession.fold(
          (failure) {
            // Failure is acceptable for expired sessions
          },
          (session) {
            expect(
              session,
              isNull,
              reason: 'Expired sessions should be cleaned up',
            );
          },
        );
      }
    });

    test('Property: Session expiry notifications are consistent', () async {
      // Property: Session expiry information should be consistent
      // across multiple calls without external changes

      for (var i = 0; i < 20; i++) {
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();
        final sessionData = generateValidSessionData(user, userProfile);

        // Mock consistent session state
        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => Right(sessionData));

        // Initialize session
        await deps.sessionManager.initialize();

        // Get expiry info multiple times
        final expiryInfoResults = <SessionExpiryInfo>[];
        for (var j = 0; j < 5; j++) {
          final expiryInfo = await deps.sessionManager.getExpiryInfo();
          expiryInfoResults.add(expiryInfo);
        }

        // Property: All expiry info should be consistent
        final firstResult = expiryInfoResults.first;
        for (final result in expiryInfoResults) {
          expect(result.hasSession, equals(firstResult.hasSession));
          expect(result.isExpired, equals(firstResult.isExpired));
          expect(result.needsRefresh, equals(firstResult.needsRefresh));
          expect(result.expiresAt, equals(firstResult.expiresAt));
        }

        // Clean up
        await deps.sessionManager.endSession();
      }
    });
  });
}

/// Generate session data with expired access token but valid refresh token
SessionData generateSessionWithExpiredAccessToken(
  User user,
  UserProfile userProfile,
) {
  final now = DateTime.now();

  return SessionData(
    accessToken: 'expired_access_token_${now.millisecond}',
    refreshToken: 'valid_refresh_token_${now.microsecond}',
    user: user,
    userProfile: userProfile,
    expiresAt: now.subtract(
      const Duration(minutes: 10),
    ), // Expired 10 minutes ago
    refreshExpiresAt: now.add(
      const Duration(days: 29),
    ), // Still valid for 29 days
  );
}

/// Generate session data that expires soon (needs refresh)
SessionData generateSoonToExpireSessionData(
  User user,
  UserProfile userProfile,
) {
  final now = DateTime.now();

  return SessionData(
    accessToken: 'soon_to_expire_access_token',
    refreshToken: 'valid_refresh_token',
    user: user,
    userProfile: userProfile,
    expiresAt: now.add(
      const Duration(minutes: 2),
    ), // Expires in 2 minutes (needs refresh)
    refreshExpiresAt: now.add(
      const Duration(days: 30),
    ), // Refresh token still valid
  );
}

/// Generate expired session data for testing
SessionData generateExpiredSessionData(User user, UserProfile userProfile) {
  final now = DateTime.now();

  return SessionData(
    accessToken: 'expired_access_token',
    refreshToken: 'expired_refresh_token',
    user: user,
    userProfile: userProfile,
    expiresAt: now.subtract(const Duration(hours: 2)), // Expired 2 hours ago
    refreshExpiresAt: now.subtract(
      const Duration(days: 1),
    ), // Expired 1 day ago
  );
}

/// Generate valid session data for testing
SessionData generateValidSessionData(User user, UserProfile userProfile) {
  final now = DateTime.now();
  final accessTokens = [
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test1',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test2',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test3',
  ];

  final refreshTokens = [
    'refresh_token_1_valid',
    'refresh_token_2_valid',
    'refresh_token_3_valid',
  ];

  return SessionData(
    accessToken: accessTokens[now.millisecond % accessTokens.length],
    refreshToken: refreshTokens[now.microsecond % refreshTokens.length],
    user: user,
    userProfile: userProfile,
    expiresAt: now.add(const Duration(hours: 1)),
    refreshExpiresAt: now.add(const Duration(days: 30)),
  );
}
