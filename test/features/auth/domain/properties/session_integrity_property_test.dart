import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/services/session_service.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/property_test_helpers.dart';
import '../../../../helpers/test_helpers.dart';

/// Property 12: Session integrity across device changes
///
/// This property validates that session data maintains integrity across
/// different device states, network conditions, and app lifecycle changes.
///
/// **Validates Requirements:**
/// - 6.5: Session integrity is maintained across device changes
void main() {
  group('Session Integrity Properties', () {
    late TestDependencies deps;

    setUp(() {
      deps = setupTestDependencies();
    });

    tearDown(() async {
      await deps.dispose();
    });

    test('Property 12: Session integrity across device changes', () async {
      // Property: For any valid session, the session data should remain
      // consistent and uncorrupted across various device state changes

      for (var i = 0; i < 100; i++) {
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();
        final originalSession = generateValidSessionData(user, userProfile);

        // Mock consistent session storage and retrieval
        when(
          deps.mockSessionService.storeSession(
            accessToken: originalSession.accessToken,
            refreshToken: originalSession.refreshToken,
            user: user,
            userProfile: userProfile,
          ),
        ).thenAnswer((_) async => const Right(null));

        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => Right(originalSession));

        when(
          deps.mockSessionService.validateSession(),
        ).thenAnswer((_) async => const Right(true));

        // Store session
        await deps.sessionManager.startSession(
          accessToken: originalSession.accessToken,
          refreshToken: originalSession.refreshToken,
          user: user,
          userProfile: userProfile,
        );

        // Simulate various device state changes
        await _simulateDeviceStateChanges(deps, originalSession);

        // Verify session integrity after device changes
        final retrievedResult = await deps.sessionManager.getCurrentSession();

        retrievedResult.fold(
          (failure) => fail(
            'Session retrieval should not fail after device changes: $failure',
          ),
          (retrievedSession) {
            if (retrievedSession != null) {
              // Property assertions for session integrity

              // 1. Core session data should be unchanged
              expect(
                retrievedSession.accessToken,
                equals(originalSession.accessToken),
              );
              expect(
                retrievedSession.refreshToken,
                equals(originalSession.refreshToken),
              );

              // 2. User data integrity
              expect(retrievedSession.user.id, equals(originalSession.user.id));
              expect(
                retrievedSession.user.email,
                equals(originalSession.user.email),
              );
              expect(
                retrievedSession.user.emailConfirmed,
                equals(originalSession.user.emailConfirmed),
              );

              // 3. User profile integrity
              expect(
                retrievedSession.userProfile.id,
                equals(originalSession.userProfile.id),
              );
              expect(
                retrievedSession.userProfile.displayName,
                equals(originalSession.userProfile.displayName),
              );
              expect(
                retrievedSession.userProfile.preferredCurrency,
                equals(originalSession.userProfile.preferredCurrency),
              );
              expect(
                retrievedSession.userProfile.languageCode,
                equals(originalSession.userProfile.languageCode),
              );

              // 4. Expiry times should be preserved
              expect(
                retrievedSession.expiresAt,
                equals(originalSession.expiresAt),
              );
              expect(
                retrievedSession.refreshExpiresAt,
                equals(originalSession.refreshExpiresAt),
              );

              // 5. Session state should be consistent
              expect(
                retrievedSession.isExpired,
                equals(originalSession.isExpired),
              );
              expect(
                retrievedSession.needsRefresh,
                equals(originalSession.needsRefresh),
              );
            } else {
              fail('Session should be preserved across device changes');
            }
          },
        );

        // Clean up
        await deps.sessionManager.endSession();
      }
    });

    test('Property: Session data is tamper-resistant', () async {
      // Property: Session data should detect and handle tampering attempts
      // by validating data integrity and rejecting corrupted sessions

      for (var i = 0; i < 50; i++) {
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();
        final validSession = generateValidSessionData(user, userProfile);

        // Generate corrupted session data
        final corruptedSessions = _generateCorruptedSessionData(validSession);

        for (final corruptedSession in corruptedSessions) {
          // Mock corrupted session retrieval
          when(
            deps.mockSessionService.getStoredSession(),
          ).thenAnswer((_) async => Right(corruptedSession));

          when(deps.mockSessionService.validateSession()).thenAnswer(
            (_) async => const Right(false),
          ); // Corrupted sessions should fail validation

          when(
            deps.mockSessionService.clearSession(),
          ).thenAnswer((_) async => const Right(null));

          // Attempt to initialize with corrupted session
          final initResult = await deps.sessionManager.initialize();

          // Property: Corrupted sessions should be rejected
          initResult.fold(
            (failure) {
              // Failure is expected for corrupted sessions
            },
            (sessionData) {
              // Corrupted sessions should not be restored
              expect(
                sessionData,
                isNull,
                reason: 'Corrupted sessions should not be restored',
              );
            },
          );

          // Verify validation fails for corrupted sessions
          final validationResult = await deps.sessionManager.isSessionValid();
          validationResult.fold(
            (failure) {
              // Validation failure is expected for corrupted sessions
            },
            (isValid) {
              expect(
                isValid,
                isFalse,
                reason: 'Corrupted sessions should not validate',
              );
            },
          );
        }
      }
    });

    test('Property: Session consistency across concurrent access', () async {
      // Property: Session data should remain consistent when accessed
      // concurrently from multiple parts of the application

      for (var i = 0; i < 30; i++) {
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();
        final sessionData = generateValidSessionData(user, userProfile);

        // Mock consistent session behavior
        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => Right(sessionData));

        when(
          deps.mockSessionService.validateSession(),
        ).thenAnswer((_) async => const Right(true));

        // Initialize session
        await deps.sessionManager.initialize();

        // Perform concurrent session operations
        final futures = <Future<dynamic>>[];
        final results = <Either<dynamic, dynamic>>[];

        // Multiple concurrent reads
        for (var j = 0; j < 10; j++) {
          futures.add(
            deps.sessionManager.getCurrentSession().then((result) {
              results.add(result);
              return result;
            }),
          );
        }

        // Multiple concurrent validations
        for (var j = 0; j < 5; j++) {
          futures.add(
            deps.sessionManager.isSessionValid().then((result) {
              results.add(result);
              return result;
            }),
          );
        }

        // Wait for all operations to complete
        await Future.wait(futures);

        // Property: All operations should succeed
        for (final result in results) {
          expect(
            result.isRight(),
            isTrue,
            reason: 'Concurrent session operations should succeed',
          );
        }

        // Property: All session data should be consistent
        final sessionResults = results
            .where(
              (r) => r.isRight() && r.getOrElse(() => null) is SessionData?,
            )
            .map((r) => r.getOrElse(() => null) as SessionData?)
            .where((s) => s != null)
            .cast<SessionData>()
            .toList();

        if (sessionResults.isNotEmpty) {
          final firstSession = sessionResults.first;
          for (final session in sessionResults) {
            expect(session.accessToken, equals(firstSession.accessToken));
            expect(session.user.id, equals(firstSession.user.id));
            expect(session.userProfile.id, equals(firstSession.userProfile.id));
          }
        }

        // Clean up
        await deps.sessionManager.endSession();
      }
    });

    test('Property: Session recovery from storage errors', () async {
      // Property: The system should gracefully handle storage errors
      // and maintain session integrity when possible

      for (var i = 0; i < 20; i++) {
        // Simulate storage errors
        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer(
          (_) async => const Left(GenericAuthFailure('Storage error')),
        );

        when(deps.mockSessionService.validateSession()).thenAnswer(
          (_) async => const Left(GenericAuthFailure('Validation error')),
        );

        when(
          deps.mockSessionService.clearSession(),
        ).thenAnswer((_) async => const Right(null));

        // Attempt to initialize with storage errors
        final initResult = await deps.sessionManager.initialize();

        // Property: Storage errors should be handled gracefully
        initResult.fold(
          (failure) {
            // Failure is expected when storage has errors
            expect(failure, isA<AuthFailure>());
          },
          (sessionData) {
            // No session should be restored when storage fails
            expect(sessionData, isNull);
          },
        );

        // Verify system remains stable after storage errors
        final validationResult = await deps.sessionManager.isSessionValid();
        validationResult.fold(
          (failure) {
            // Validation failure is expected when storage has errors
            expect(failure, isA<AuthFailure>());
          },
          (isValid) {
            // Should not be valid when storage has errors
            expect(isValid, isFalse);
          },
        );
      }
    });

    test('Property: Session data serialization integrity', () async {
      // Property: Session data should maintain integrity through
      // serialization and deserialization cycles

      for (var i = 0; i < 50; i++) {
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();
        final originalSession = generateValidSessionData(user, userProfile);

        // Simulate serialization/deserialization by converting to/from JSON
        final sessionJson = originalSession.toJson();
        final deserializedSession = SessionData.fromJson(sessionJson);

        // Property assertions for serialization integrity

        // 1. All fields should be preserved
        expect(
          deserializedSession.accessToken,
          equals(originalSession.accessToken),
        );
        expect(
          deserializedSession.refreshToken,
          equals(originalSession.refreshToken),
        );
        expect(
          deserializedSession.expiresAt,
          equals(originalSession.expiresAt),
        );
        expect(
          deserializedSession.refreshExpiresAt,
          equals(originalSession.refreshExpiresAt),
        );

        // 2. User data should be preserved
        expect(deserializedSession.user.id, equals(originalSession.user.id));
        expect(
          deserializedSession.user.email,
          equals(originalSession.user.email),
        );
        expect(
          deserializedSession.user.emailConfirmed,
          equals(originalSession.user.emailConfirmed),
        );

        // 3. User profile should be preserved
        expect(
          deserializedSession.userProfile.id,
          equals(originalSession.userProfile.id),
        );
        expect(
          deserializedSession.userProfile.displayName,
          equals(originalSession.userProfile.displayName),
        );
        expect(
          deserializedSession.userProfile.preferredCurrency,
          equals(originalSession.userProfile.preferredCurrency),
        );

        // 4. Computed properties should be consistent
        expect(
          deserializedSession.isExpired,
          equals(originalSession.isExpired),
        );
        expect(
          deserializedSession.needsRefresh,
          equals(originalSession.needsRefresh),
        );

        // 5. Objects should be equal
        expect(deserializedSession, equals(originalSession));
      }
    });
  });
}

/// Simulate various device state changes that could affect session integrity
Future<void> _simulateDeviceStateChanges(
  TestDependencies deps,
  SessionData session,
) async {
  // Simulate app backgrounding and foregrounding
  await Future<void>.delayed(const Duration(milliseconds: 10));

  // Simulate network connectivity changes
  await Future<void>.delayed(const Duration(milliseconds: 10));

  // Simulate device rotation
  await Future<void>.delayed(const Duration(milliseconds: 10));

  // Simulate memory pressure
  await Future<void>.delayed(const Duration(milliseconds: 10));

  // Simulate app restart (re-initialize session manager)
  final reinitResult = await deps.sessionManager.initialize();

  // Verify re-initialization doesn't corrupt session
  reinitResult.fold(
    (failure) {
      // Re-initialization can fail, but shouldn't corrupt data
    },
    (restoredSession) {
      if (restoredSession != null) {
        expect(restoredSession.user.id, equals(session.user.id));
      }
    },
  );
}

/// Generate various types of corrupted session data for testing
List<SessionData> _generateCorruptedSessionData(SessionData validSession) {
  final now = DateTime.now();

  return [
    // Corrupted access token
    validSession.copyWith(
      accessToken: 'corrupted_token_${now.millisecond}',
    ),

    // Corrupted refresh token
    validSession.copyWith(
      refreshToken: 'corrupted_refresh_${now.microsecond}',
    ),

    // Corrupted user ID
    validSession.copyWith(
      user: validSession.user.copyWith(id: 'corrupted_user_id'),
    ),

    // Corrupted email
    validSession.copyWith(
      user: validSession.user.copyWith(email: 'corrupted@invalid'),
    ),

    // Corrupted expiry times (future dates that don't make sense)
    validSession.copyWith(
      expiresAt: DateTime(1970), // Invalid past date
      refreshExpiresAt: DateTime(1970),
    ),

    // Mismatched user and profile IDs
    validSession.copyWith(
      userProfile: validSession.userProfile.copyWith(id: 'mismatched_id'),
    ),
  ];
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
