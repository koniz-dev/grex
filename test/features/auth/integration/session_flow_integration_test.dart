import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/services/session_manager.dart';
import 'package:grex/features/auth/domain/services/session_service.dart';
import 'package:grex/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:grex/features/auth/presentation/bloc/auth_event.dart';
import 'package:grex/features/auth/presentation/bloc/auth_state.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/test_helpers.mocks.dart';

/// Integration tests for session management flows
///
/// Tests session persistence, expiration, and refresh across app lifecycle
/// Validates: Requirements 6.1, 6.2, 6.3, 6.4
void main() {
  group('Session Management Flow Integration Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late MockSessionService mockSessionService;
    late MockSessionManager mockSessionManager;
    late SessionManager sessionManager;
    late AuthBloc authBloc;
    late User testUser;
    late UserProfile testProfile;
    late SessionData testSession;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
      mockSessionService = MockSessionService();

      testUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        lastSignInAt: DateTime.now(),
      );

      testProfile = UserProfile(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        preferredCurrency: 'VND',
        languageCode: 'vi',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testSession = SessionData(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
        user: testUser,
        userProfile: testProfile,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        refreshExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      sessionManager = SessionManager(
        sessionService: mockSessionService,
      );

      mockSessionManager = MockSessionManager();
      authBloc = AuthBloc(
        authRepository: mockAuthRepository,
        userRepository: mockUserRepository,
        sessionManager: mockSessionManager,
      );
    });

    tearDown(() async {
      sessionManager.dispose();
      await authBloc.close();
    });

    test('Session persistence flow - app restart with valid session', () async {
      // Arrange - Mock existing session on startup
      when(
        mockSessionService.getStoredSession(),
      ).thenAnswer((_) async => Right(testSession));

      when(
        mockSessionService.validateSession(),
      ).thenAnswer((_) async => const Right(true));

      // Act - Initialize session manager (simulating app restart)
      final result = await sessionManager.initialize();

      // Assert - Verify session was loaded and validated
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (sessionData) {
          expect(sessionData, isNotNull);
          expect(sessionData!.user.id, equals(testUser.id));
        },
      );

      verify(mockSessionService.getStoredSession()).called(1);
      verify(mockSessionService.validateSession()).called(1);
    });

    test('Session expiration flow - handle expired session', () async {
      // Arrange - Mock expired session
      final expiredSession = SessionData(
        accessToken: 'expired-token',
        refreshToken: 'expired-refresh-token',
        user: testUser,
        userProfile: testProfile,
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        refreshExpiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      when(
        mockSessionService.getStoredSession(),
      ).thenAnswer((_) async => Right(expiredSession));

      when(
        mockSessionService.validateSession(),
      ).thenAnswer((_) async => const Right(false));

      // Act - Initialize with expired session
      final result = await sessionManager.initialize();

      // Assert - Verify expired session was handled
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (sessionData) => expect(sessionData, isNull),
      );

      verify(mockSessionService.getStoredSession()).called(1);
      verify(mockSessionService.validateSession()).called(1);
    });

    test('Session refresh flow - automatic token refresh', () async {
      // Arrange - Mock session that needs refresh
      final nearExpirySession = SessionData(
        accessToken: 'near-expiry-token',
        refreshToken: 'refresh-token',
        user: testUser,
        userProfile: testProfile,
        expiresAt: DateTime.now().add(
          const Duration(minutes: 3),
        ), // Needs refresh
        refreshExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final refreshedSession = SessionData(
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
        user: testUser,
        userProfile: testProfile,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        refreshExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      when(
        mockSessionService.getStoredSession(),
      ).thenAnswer((_) async => Right(nearExpirySession));

      when(
        mockSessionService.validateSession(),
      ).thenAnswer((_) async => const Right(true));

      when(
        mockSessionService.refreshSession(),
      ).thenAnswer((_) async => Right(refreshedSession));

      // Act - Initialize and manually trigger refresh
      await sessionManager.initialize();
      final refreshResult = await sessionManager.refreshSession();

      // Assert - Verify session was refreshed
      expect(refreshResult.isRight(), isTrue);
      refreshResult.fold(
        (failure) => fail('Should not return failure'),
        (newSession) {
          expect(newSession.accessToken, equals('new-access-token'));
          expect(newSession.refreshToken, equals('new-refresh-token'));
        },
      );

      verify(mockSessionService.refreshSession()).called(1);
    });

    test('Session cleanup flow - logout clears session', () async {
      // Arrange - Mock valid session
      when(
        mockSessionService.getStoredSession(),
      ).thenAnswer((_) async => Right(testSession));

      when(
        mockSessionService.validateSession(),
      ).thenAnswer((_) async => const Right(true));

      when(
        mockSessionService.clearSession(),
      ).thenAnswer((_) async => const Right(null));

      // Act - Initialize then end session
      await sessionManager.initialize();
      final result = await sessionManager.endSession();

      // Assert - Verify session was cleared
      expect(result.isRight(), isTrue);

      verify(mockSessionService.clearSession()).called(1);
    });

    test('Session integrity flow - handle corrupted session data', () async {
      // Arrange - Mock corrupted session
      when(
        mockSessionService.getStoredSession(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      // Act - Initialize with corrupted session
      final result = await sessionManager.initialize();

      // Assert - Verify corrupted session was handled gracefully
      expect(result.isLeft(), isTrue);

      verify(mockSessionService.getStoredSession()).called(1);
    });

    test('Session validation flow - periodic validation', () async {
      // Arrange - Mock valid session
      when(
        mockSessionService.getStoredSession(),
      ).thenAnswer((_) async => Right(testSession));

      when(
        mockSessionService.validateSession(),
      ).thenAnswer((_) async => const Right(true));

      // Act - Initialize and check validation
      await sessionManager.initialize();
      final validationResult = await sessionManager.isSessionValid();

      // Assert - Verify session validation
      expect(validationResult.isRight(), isTrue);
      validationResult.fold(
        (failure) => fail('Should not return failure'),
        (isValid) => expect(isValid, isTrue),
      );

      verify(mockSessionService.validateSession()).called(greaterThan(0));
    });

    test('Session start flow - new authentication session', () async {
      // Arrange
      when(
        mockSessionService.storeSession(
          accessToken: anyNamed('accessToken'),
          refreshToken: anyNamed('refreshToken'),
          user: anyNamed('user'),
          userProfile: anyNamed('userProfile'),
        ),
      ).thenAnswer((_) async => const Right(null));

      // Act - Start new session
      final result = await sessionManager.startSession(
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
        user: testUser,
        userProfile: testProfile,
      );

      // Assert - Verify session was stored
      expect(result.isRight(), isTrue);

      verify(
        mockSessionService.storeSession(
          accessToken: 'new-access-token',
          refreshToken: 'new-refresh-token',
          user: testUser,
          userProfile: testProfile,
        ),
      ).called(1);
    });

    test('Session manager integration with AuthBloc', () async {
      // Arrange - Mock authenticated user
      when(mockAuthRepository.currentUser).thenReturn(testUser);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(testUser));

      // Act - Check session through AuthBloc
      authBloc.add(const AuthSessionChecked());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Assert - Verify AuthBloc reflects session state
      expect(authBloc.state, isA<AuthAuthenticated>());
      final authenticatedState = authBloc.state as AuthAuthenticated;
      expect(authenticatedState.user.id, equals(testUser.id));
    });

    test('Session expiry information flow', () async {
      // Arrange - Mock session with known expiry
      when(
        mockSessionService.getStoredSession(),
      ).thenAnswer((_) async => Right(testSession));

      // Act - Get expiry information
      final expiryInfo = await sessionManager.getExpiryInfo();

      // Assert - Verify expiry information is correct
      expect(expiryInfo.hasSession, isTrue);
      expect(expiryInfo.isExpired, isFalse);
      expect(expiryInfo.expiresAt, isNotNull);
      expect(expiryInfo.timeUntilExpiry, isNotNull);
      expect(expiryInfo.timeUntilExpiry!.inMinutes, greaterThan(50));
    });

    test('Session refresh failure flow - handle refresh errors', () async {
      // Arrange - Mock refresh failure
      when(
        mockSessionService.refreshSession(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      // Act - Attempt to refresh session
      final result = await sessionManager.refreshSession();

      // Assert - Verify refresh failure is handled
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (session) => fail('Should not return success'),
      );

      verify(mockSessionService.refreshSession()).called(1);
    });

    test('Session current data flow - get active session', () async {
      // Arrange - Mock current session
      when(
        mockSessionService.getStoredSession(),
      ).thenAnswer((_) async => Right(testSession));

      // Act - Get current session
      final result = await sessionManager.getCurrentSession();

      // Assert - Verify current session data
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (sessionData) {
          expect(sessionData, isNotNull);
          expect(sessionData!.user.id, equals(testUser.id));
          expect(sessionData.accessToken, equals('test-access-token'));
        },
      );

      verify(mockSessionService.getStoredSession()).called(1);
    });
  });
}
