import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/services/session_service.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/property_test_helpers.dart';
import '../../../../helpers/test_helpers.dart';

/// Unit tests for SessionManager
///
/// Tests session storage, retrieval, validation, refresh, and cleanup
/// operations.
void main() {
  group('SessionManager', () {
    late TestDependencies deps;

    setUp(() {
      deps = setupTestDependencies();
    });

    tearDown(() async {
      await deps.dispose();
    });

    group('initialize', () {
      test('should restore valid session on initialization', () async {
        // Arrange
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();
        final sessionData = SessionData(
          accessToken: 'test_access_token',
          refreshToken: 'test_refresh_token',
          user: user,
          userProfile: userProfile,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          refreshExpiresAt: DateTime.now().add(const Duration(days: 30)),
        );

        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => Right(sessionData));

        when(
          deps.mockSessionService.validateSession(),
        ).thenAnswer((_) async => const Right(true));

        // Act
        final result = await deps.sessionManager.initialize();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not fail'),
          (restoredSession) {
            expect(restoredSession, isNotNull);
            expect(restoredSession!.user.id, equals(user.id));
            expect(restoredSession.accessToken, equals('test_access_token'));
          },
        );

        verify(deps.mockSessionService.getStoredSession()).called(1);
        verify(deps.mockSessionService.validateSession()).called(1);
      });

      test('should return null when no session exists', () async {
        // Arrange
        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => const Right(null));

        // Act
        final result = await deps.sessionManager.initialize();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not fail'),
          (restoredSession) {
            expect(restoredSession, isNull);
          },
        );

        verify(deps.mockSessionService.getStoredSession()).called(1);
        verifyNever(deps.mockSessionService.validateSession());
      });

      test('should return null when session validation fails', () async {
        // Arrange
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();
        final sessionData = SessionData(
          accessToken: 'test_access_token',
          refreshToken: 'test_refresh_token',
          user: user,
          userProfile: userProfile,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          refreshExpiresAt: DateTime.now().add(const Duration(days: 30)),
        );

        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => Right(sessionData));

        when(
          deps.mockSessionService.validateSession(),
        ).thenAnswer((_) async => const Right(false));

        // Act
        final result = await deps.sessionManager.initialize();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not fail'),
          (restoredSession) {
            expect(restoredSession, isNull);
          },
        );

        verify(deps.mockSessionService.getStoredSession()).called(1);
        verify(deps.mockSessionService.validateSession()).called(1);
      });
    });

    group('startSession', () {
      test('should store session successfully', () async {
        // Arrange
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();

        when(
          deps.mockSessionService.storeSession(
            accessToken: anyNamed('accessToken'),
            refreshToken: anyNamed('refreshToken'),
            user: anyNamed('user'),
            userProfile: anyNamed('userProfile'),
          ),
        ).thenAnswer((_) async => const Right(null));

        // Act
        final result = await deps.sessionManager.startSession(
          accessToken: 'test_access_token',
          refreshToken: 'test_refresh_token',
          user: user,
          userProfile: userProfile,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(
          deps.mockSessionService.storeSession(
            accessToken: 'test_access_token',
            refreshToken: 'test_refresh_token',
            user: user,
            userProfile: userProfile,
          ),
        ).called(1);
      });

      test('should return failure when storage fails', () async {
        // Arrange
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();

        when(
          deps.mockSessionService.storeSession(
            accessToken: anyNamed('accessToken'),
            refreshToken: anyNamed('refreshToken'),
            user: anyNamed('user'),
            userProfile: anyNamed('userProfile'),
          ),
        ).thenAnswer(
          (_) async => const Left(GenericAuthFailure('Storage failed')),
        );

        // Act
        final result = await deps.sessionManager.startSession(
          accessToken: 'test_access_token',
          refreshToken: 'test_refresh_token',
          user: user,
          userProfile: userProfile,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<AuthFailure>());
          },
          (_) => fail('Should fail'),
        );
      });
    });

    group('endSession', () {
      test('should clear session successfully', () async {
        // Arrange
        when(
          deps.mockSessionService.clearSession(),
        ).thenAnswer((_) async => const Right(null));

        // Act
        final result = await deps.sessionManager.endSession();

        // Assert
        expect(result.isRight(), isTrue);
        verify(deps.mockSessionService.clearSession()).called(1);
      });

      test('should return failure when clear fails', () async {
        // Arrange
        when(
          deps.mockSessionService.clearSession(),
        ).thenAnswer(
          (_) async => const Left(GenericAuthFailure('Clear failed')),
        );

        // Act
        final result = await deps.sessionManager.endSession();

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<AuthFailure>());
          },
          (_) => fail('Should fail'),
        );
      });
    });

    group('getCurrentSession', () {
      test('should return current session', () async {
        // Arrange
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();
        final sessionData = SessionData(
          accessToken: 'test_access_token',
          refreshToken: 'test_refresh_token',
          user: user,
          userProfile: userProfile,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          refreshExpiresAt: DateTime.now().add(const Duration(days: 30)),
        );

        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => Right(sessionData));

        // Act
        final result = await deps.sessionManager.getCurrentSession();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not fail'),
          (session) {
            expect(session, isNotNull);
            expect(session!.accessToken, equals('test_access_token'));
          },
        );
      });

      test('should return null when no session exists', () async {
        // Arrange
        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => const Right(null));

        // Act
        final result = await deps.sessionManager.getCurrentSession();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not fail'),
          (session) {
            expect(session, isNull);
          },
        );
      });
    });

    group('isSessionValid', () {
      test('should return true for valid session', () async {
        // Arrange
        when(
          deps.mockSessionService.validateSession(),
        ).thenAnswer((_) async => const Right(true));

        // Act
        final result = await deps.sessionManager.isSessionValid();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not fail'),
          (isValid) {
            expect(isValid, isTrue);
          },
        );
      });

      test('should return false for invalid session', () async {
        // Arrange
        when(
          deps.mockSessionService.validateSession(),
        ).thenAnswer((_) async => const Right(false));

        // Act
        final result = await deps.sessionManager.isSessionValid();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not fail'),
          (isValid) {
            expect(isValid, isFalse);
          },
        );
      });
    });

    group('refreshSession', () {
      test('should refresh session successfully', () async {
        // Arrange
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();
        final newSessionData = SessionData(
          accessToken: 'new_access_token',
          refreshToken: 'new_refresh_token',
          user: user,
          userProfile: userProfile,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          refreshExpiresAt: DateTime.now().add(const Duration(days: 30)),
        );

        when(
          deps.mockSessionService.refreshSession(),
        ).thenAnswer((_) async => Right(newSessionData));

        // Act
        final result = await deps.sessionManager.refreshSession();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not fail'),
          (session) {
            expect(session.accessToken, equals('new_access_token'));
            expect(session.refreshToken, equals('new_refresh_token'));
          },
        );

        verify(deps.mockSessionService.refreshSession()).called(1);
      });

      test('should return failure when refresh fails', () async {
        // Arrange
        when(deps.mockSessionService.refreshSession()).thenAnswer(
          (_) async => const Left(GenericAuthFailure('Refresh failed')),
        );

        // Act
        final result = await deps.sessionManager.refreshSession();

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<AuthFailure>());
          },
          (_) => fail('Should fail'),
        );
      });
    });

    group('getExpiryInfo', () {
      test('should return expiry info for valid session', () async {
        // Arrange
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();
        final expiresAt = DateTime.now().add(const Duration(hours: 1));
        final sessionData = SessionData(
          accessToken: 'test_access_token',
          refreshToken: 'test_refresh_token',
          user: user,
          userProfile: userProfile,
          expiresAt: expiresAt,
          refreshExpiresAt: DateTime.now().add(const Duration(days: 30)),
        );

        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => Right(sessionData));

        // Act
        final expiryInfo = await deps.sessionManager.getExpiryInfo();

        // Assert
        expect(expiryInfo.hasSession, isTrue);
        expect(expiryInfo.isExpired, isFalse);
        expect(expiryInfo.expiresAt, equals(expiresAt));
        expect(expiryInfo.timeUntilExpiry, isNotNull);
        expect(expiryInfo.timeUntilExpiry!.inMinutes, greaterThan(0));
      });

      test('should return no session info when no session exists', () async {
        // Arrange
        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => const Right(null));

        // Act
        final expiryInfo = await deps.sessionManager.getExpiryInfo();

        // Assert
        expect(expiryInfo.hasSession, isFalse);
        expect(expiryInfo.isExpired, isTrue);
        expect(expiryInfo.expiresAt, isNull);
        expect(expiryInfo.timeUntilExpiry, isNull);
      });

      test('should return expired info for expired session', () async {
        // Arrange
        final user = generateValidUser();
        final userProfile = generateValidUserProfile();
        final expiresAt = DateTime.now().subtract(const Duration(hours: 1));
        final sessionData = SessionData(
          accessToken: 'test_access_token',
          refreshToken: 'test_refresh_token',
          user: user,
          userProfile: userProfile,
          expiresAt: expiresAt,
          refreshExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        when(
          deps.mockSessionService.getStoredSession(),
        ).thenAnswer((_) async => Right(sessionData));

        // Act
        final expiryInfo = await deps.sessionManager.getExpiryInfo();

        // Assert
        expect(expiryInfo.hasSession, isTrue);
        expect(expiryInfo.isExpired, isTrue);
        expect(expiryInfo.expiresAt, equals(expiresAt));
        expect(expiryInfo.timeUntilExpiry, equals(Duration.zero));
      });
    });
  });
}
