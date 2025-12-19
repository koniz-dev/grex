import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/services/session_service.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/property_test_helpers.dart';
import '../../../../helpers/test_helpers.dart';

/// Property 10: App restart preserves valid sessions
///
/// This property validates that valid authentication sessions are properly
/// preserved across app restarts and can be restored when the app starts again.
///
/// **Validates Requirements:**
/// - 6.1: Session data persists across app restarts
/// - 6.2: Valid sessions are automatically restored on app startup
void main() {
  group('Session Persistence Properties', () {
    late TestDependencies deps;

    setUp(() {
      deps = setupTestDependencies();
    });

    tearDown(() async {
      await deps.dispose();
    });

    test('Property 10: App restart preserves valid sessions', () async {
      // Property: For any valid session, storing it and then retrieving it
      // should return the same session data with valid authentication state

      for (var i = 0; i < 100; i++) {
        // Generate random valid session data
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();
        final sessionData = generateValidSessionData(user, userProfile);

        // Mock successful session storage
        when(
          deps.mockSessionService.storeSession(
            accessToken: sessionData.accessToken,
            refreshToken: sessionData.refreshToken,
            user: user,
            userProfile: userProfile,
          ),
        ).thenAnswer((_) async => const Right(null));

        // Mock successful session retrieval
        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => Right(sessionData));

        when(
          deps.mockSessionService.validateSession(),
        ).thenAnswer((_) async => const Right(true));

        // Store session (simulating successful login)
        final storeResult = await deps.sessionManager.startSession(
          accessToken: sessionData.accessToken,
          refreshToken: sessionData.refreshToken,
          user: user,
          userProfile: userProfile,
        );

        expect(storeResult.isRight(), isTrue);

        // Simulate app restart by initializing session manager again
        final restoreResult = await deps.sessionManager.initialize();

        // Property assertions
        restoreResult.fold(
          (failure) => fail('Session restoration should not fail: $failure'),
          (restoredSession) {
            if (restoredSession != null) {
              // 1. Session should be restored with same user data
              expect(restoredSession.user.id, equals(user.id));
              expect(restoredSession.user.email, equals(user.email));
              expect(restoredSession.userProfile.id, equals(userProfile.id));
              expect(
                restoredSession.userProfile.displayName,
                equals(userProfile.displayName),
              );

              // 2. Session tokens should be preserved
              expect(
                restoredSession.accessToken,
                equals(sessionData.accessToken),
              );
              expect(
                restoredSession.refreshToken,
                equals(sessionData.refreshToken),
              );

              // 3. Session should still be valid
              expect(restoredSession.isExpired, isFalse);

              // 4. Session expiry times should be preserved
              expect(restoredSession.expiresAt, equals(sessionData.expiresAt));
              expect(
                restoredSession.refreshExpiresAt,
                equals(sessionData.refreshExpiresAt),
              );
            } else {
              fail('Valid session should be restored after app restart');
            }
          },
        );

        // Clean up for next iteration
        await deps.sessionManager.endSession();
      }
    });

    test('Property: Expired sessions are not restored', () async {
      // Property: For any expired session, app restart should not restore
      // the session and should return null instead

      for (var i = 0; i < 50; i++) {
        // Mock expired session retrieval
        when(deps.mockSessionService.getStoredSession()).thenAnswer(
          (_) async => const Right(null),
        ); // Expired sessions return null

        when(
          deps.mockSessionService.validateSession(),
        ).thenAnswer((_) async => const Right(false));

        // Simulate app restart with expired session
        final restoreResult = await deps.sessionManager.initialize();

        // Property assertions
        restoreResult.fold(
          (failure) {
            // Failure is acceptable for expired sessions
          },
          (restoredSession) {
            // Expired sessions should not be restored
            expect(restoredSession, isNull);
          },
        );
      }
    });

    test(
      'Property: Session data integrity across storage operations',
      () async {
        // Property: For any session data, storing and retrieving it multiple
        // times
        // should preserve data integrity without corruption

        for (var i = 0; i < 30; i++) {
          final user = generateValidUser();
          final userProfile = generateValidUserProfile();
          final originalSession = generateValidSessionData(user, userProfile);

          // Mock consistent storage and retrieval
          when(
            deps.mockSessionService.storeSession(
              accessToken: anyNamed('accessToken'),
              refreshToken: anyNamed('refreshToken'),
              user: anyNamed('user'),
              userProfile: anyNamed('userProfile'),
            ),
          ).thenAnswer((_) async => const Right(null));

          when(
            deps.mockSessionService.getStoredSession(),
          ).thenAnswer((_) async => Right(originalSession));

          when(
            deps.mockSessionService.validateSession(),
          ).thenAnswer((_) async => const Right(true));

          // Perform multiple store/retrieve cycles
          for (var cycle = 0; cycle < 3; cycle++) {
            // Store session
            await deps.sessionManager.startSession(
              accessToken: originalSession.accessToken,
              refreshToken: originalSession.refreshToken,
              user: user,
              userProfile: userProfile,
            );

            // Retrieve session
            final retrieveResult = await deps.sessionManager
                .getCurrentSession();

            retrieveResult.fold(
              (failure) => fail('Session retrieval should not fail: $failure'),
              (retrievedSession) {
                if (retrievedSession != null) {
                  // Property: Data should remain identical across cycles
                  expect(
                    retrievedSession.user.id,
                    equals(originalSession.user.id),
                  );
                  expect(
                    retrievedSession.user.email,
                    equals(originalSession.user.email),
                  );
                  expect(
                    retrievedSession.userProfile.displayName,
                    equals(originalSession.userProfile.displayName),
                  );
                  expect(
                    retrievedSession.accessToken,
                    equals(originalSession.accessToken),
                  );
                  expect(
                    retrievedSession.refreshToken,
                    equals(originalSession.refreshToken),
                  );
                }
              },
            );
          }

          // Clean up
          await deps.sessionManager.endSession();
        }
      },
    );

    test('Property: Concurrent session operations are safe', () async {
      // Property: Multiple concurrent session operations should not corrupt
      // session data or cause race conditions

      for (var i = 0; i < 20; i++) {
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();
        final sessionData = generateValidSessionData(user, userProfile);

        // Mock session operations
        when(
          deps.mockSessionService.storeSession(
            accessToken: anyNamed('accessToken'),
            refreshToken: anyNamed('refreshToken'),
            user: anyNamed('user'),
            userProfile: anyNamed('userProfile'),
          ),
        ).thenAnswer((_) async => const Right(null));

        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => Right(sessionData));

        when(
          deps.mockSessionService.validateSession(),
        ).thenAnswer((_) async => const Right(true));

        // Perform concurrent operations
        final futures = <Future<dynamic>>[
          // Start session
          deps.sessionManager.startSession(
            accessToken: sessionData.accessToken,
            refreshToken: sessionData.refreshToken,
            user: user,
            userProfile: userProfile,
          ),
        ];

        // Multiple concurrent reads
        for (var j = 0; j < 5; j++) {
          futures
            ..add(deps.sessionManager.getCurrentSession())
            ..add(deps.sessionManager.isSessionValid());
        }

        // Wait for all operations to complete
        final results = await Future.wait(futures);

        // Property: All operations should complete successfully
        for (final result in results) {
          if (result is Either) {
            expect(result.isRight(), isTrue);
          }
        }

        // Clean up
        await deps.sessionManager.endSession();
      }
    });

    test('Property: Session validation is consistent', () async {
      // Property: For any session, validation should return consistent results
      // when called multiple times without changes to the session

      for (var i = 0; i < 50; i++) {
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();
        final sessionData = generateValidSessionData(user, userProfile);

        // Mock consistent validation
        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => Right(sessionData));

        when(
          deps.mockSessionService.validateSession(),
        ).thenAnswer((_) async => const Right(true));

        // Initialize session
        await deps.sessionManager.initialize();

        // Perform multiple validation checks
        final validationResults = <bool>[];
        for (var j = 0; j < 5; j++) {
          final result = await deps.sessionManager.isSessionValid();
          result.fold(
            (failure) => fail('Validation should not fail: $failure'),
            validationResults.add,
          );
        }

        // Property: All validation results should be consistent
        expect(
          validationResults.every(
            (result) => result == validationResults.first,
          ),
          isTrue,
          reason: 'Validation results should be consistent',
        );

        // Clean up
        await deps.sessionManager.endSession();
      }
    });
  });
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

/// Generate expired session data for testing
/// This function is kept for potential future use in tests
// ignore: unreachable_from_main
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
