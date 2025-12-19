import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/repositories/auth_repository.dart';
import 'package:grex/features/auth/domain/services/session_manager.dart';
import 'package:grex/features/auth/domain/services/session_service.dart';
import 'package:grex/main.dart' as app;
import 'package:mockito/mockito.dart';

import '../../../helpers/test_helpers.mocks.dart';

/// Integration tests for session management flows
///
/// Tests session persistence, expiration, and refresh across app lifecycle
/// Validates: Requirements 6.1, 6.2, 6.3, 6.4
void main() {
  group('Session Management Integration Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockSessionService mockSessionService;
    late MockSessionManager mockSessionManager;
    late User testUser;
    late UserProfile testProfile;
    late SessionData testSession;

    setUp(() async {
      mockAuthRepository = MockAuthRepository();
      mockSessionService = MockSessionService();
      mockSessionManager = MockSessionManager();

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

      // Reset dependency injection
      await configureDependencies();

      // Override with mocks for testing
      getIt
        ..unregister<AuthRepository>()
        ..unregister<SessionService>()
        ..unregister<SessionManager>()
        ..registerSingleton<AuthRepository>(mockAuthRepository)
        ..registerSingleton<SessionService>(mockSessionService)
        ..registerSingleton<SessionManager>(mockSessionManager);
    });

    tearDown(() async {
      await getIt.reset();
    });

    testWidgets('Session persistence across app restarts', (tester) async {
      // Arrange - Mock existing session on startup
      when(
        mockSessionService.getStoredSession(),
      ).thenAnswer((_) async => Right(testSession));

      when(
        mockSessionService.validateSession(),
      ).thenAnswer((_) async => const Right(true));

      when(
        mockSessionManager.initialize(),
      ).thenAnswer((_) async => Right(testSession));

      when(mockAuthRepository.currentUser).thenReturn(testUser);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(testUser));

      // Act - Launch app (simulating app restart)
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Assert - Verify session was loaded and validated
      verify(mockSessionService.getStoredSession()).called(1);
      verify(mockSessionService.validateSession()).called(1);
      verify(mockSessionManager.initialize()).called(1);

      // Verify user is authenticated (not on login page)
      expect(find.text('Đăng nhập'), findsNothing);

      // Should be on main app screen
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Session expiration handling', (tester) async {
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

      // Mock failed refresh attempt
      when(
        mockSessionService.refreshSession(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      // Mock session cleanup
      when(
        mockSessionService.clearSession(),
      ).thenAnswer((_) async => const Right(null));

      when(
        mockSessionManager.initialize(),
      ).thenAnswer((_) async => const Right(null));

      // Mock unauthenticated state
      when(mockAuthRepository.currentUser).thenReturn(null);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(null));

      // Act - Launch app with expired session
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Assert - Verify session expiration was handled
      verify(mockSessionService.getStoredSession()).called(1);
      verify(mockSessionService.validateSession()).called(1);
      verify(mockSessionManager.initialize()).called(1);

      // Verify user is redirected to login
      expect(find.text('Đăng nhập'), findsOneWidget);
    });

    testWidgets('Automatic session refresh', (tester) async {
      // Arrange - Mock session that needs refresh
      final nearExpirySession = SessionData(
        accessToken: 'near-expiry-token',
        refreshToken: 'refresh-token',
        user: testUser,
        userProfile: testProfile,
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
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

      // Mock successful refresh
      when(
        mockSessionService.refreshSession(),
      ).thenAnswer((_) async => Right(refreshedSession));

      when(
        mockSessionManager.initialize(),
      ).thenAnswer((_) async => Right(nearExpirySession));

      when(mockAuthRepository.currentUser).thenReturn(testUser);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(testUser));

      // Act - Launch app
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Wait for automatic refresh to trigger
      await tester.pump(
        const Duration(seconds: 6),
      ); // Session manager checks every 5 seconds

      // Assert - Verify session was initialized
      verify(mockSessionService.getStoredSession()).called(1);
      verify(mockSessionService.validateSession()).called(1);
      verify(mockSessionManager.initialize()).called(1);

      // Verify user remains authenticated
      expect(find.text('Đăng nhập'), findsNothing);
    });

    testWidgets('Session cleanup on logout', (tester) async {
      // Arrange - Mock authenticated user
      when(
        mockSessionService.getStoredSession(),
      ).thenAnswer((_) async => Right(testSession));

      when(
        mockSessionService.validateSession(),
      ).thenAnswer((_) async => const Right(true));

      when(
        mockSessionManager.initialize(),
      ).thenAnswer((_) async => Right(testSession));

      when(mockAuthRepository.currentUser).thenReturn(testUser);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(testUser));

      // Mock logout operations
      when(
        mockAuthRepository.signOut(),
      ).thenAnswer((_) async => const Right(null));

      when(
        mockSessionService.clearSession(),
      ).thenAnswer((_) async => const Right(null));

      when(
        mockSessionManager.endSession(),
      ).thenAnswer((_) async => const Right(null));

      // Act - Launch app and logout
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to profile and logout
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pumpAndSettle();

      // Confirm logout
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();

      // Assert - Verify session cleanup
      verify(mockAuthRepository.signOut()).called(1);
      verify(mockSessionService.clearSession()).called(1);
      verify(mockSessionManager.endSession()).called(1);

      // Verify user is redirected to login
      expect(find.text('Đăng nhập'), findsOneWidget);
    });

    testWidgets('Session integrity validation', (tester) async {
      // Arrange - Mock corrupted session
      when(
        mockSessionService.getStoredSession(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      when(
        mockSessionManager.initialize(),
      ).thenAnswer((_) async => const Right(null));

      when(mockAuthRepository.currentUser).thenReturn(null);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(null));

      // Act - Launch app with corrupted session
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Assert - Verify corrupted session was handled
      verify(mockSessionService.getStoredSession()).called(1);
      verify(mockSessionManager.initialize()).called(1);

      // Verify user is redirected to login
      expect(find.text('Đăng nhập'), findsOneWidget);
    });

    testWidgets('Multiple session refresh attempts', (tester) async {
      // Arrange - Mock session that fails refresh multiple times
      when(
        mockSessionService.getStoredSession(),
      ).thenAnswer((_) async => Right(testSession));

      when(
        mockSessionService.validateSession(),
      ).thenAnswer((_) async => const Right(true));

      // Mock failed refresh attempts
      when(
        mockSessionService.refreshSession(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      when(
        mockSessionManager.initialize(),
      ).thenAnswer((_) async => Right(testSession));

      when(mockAuthRepository.currentUser).thenReturn(testUser);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(testUser));

      // Act - Launch app
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Wait for multiple refresh attempts
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 6));
      }

      // Assert - Verify session was initialized
      verify(mockSessionService.getStoredSession()).called(1);
      verify(mockSessionService.validateSession()).called(1);
      verify(mockSessionManager.initialize()).called(1);

      // Verify user remains authenticated (session still valid)
      expect(find.text('Đăng nhập'), findsNothing);
    });

    testWidgets('Session validation on app resume', (tester) async {
      // Arrange - Mock valid session
      when(
        mockSessionService.getStoredSession(),
      ).thenAnswer((_) async => Right(testSession));

      when(
        mockSessionService.validateSession(),
      ).thenAnswer((_) async => const Right(true));

      when(
        mockSessionManager.initialize(),
      ).thenAnswer((_) async => Right(testSession));

      when(mockAuthRepository.currentUser).thenReturn(testUser);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(testUser));

      // Act - Launch app
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Simulate app going to background and resuming
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.paused'),
        ),
        (data) {},
      );

      await tester.pump();

      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.resumed'),
        ),
        (data) {},
      );

      await tester.pumpAndSettle();

      // Assert - Verify session was validated
      verify(mockSessionService.validateSession()).called(greaterThan(0));

      // Verify user remains authenticated
      expect(find.text('Đăng nhập'), findsNothing);
    });

    testWidgets('Concurrent session operations', (tester) async {
      // Arrange - Mock session operations
      when(
        mockSessionService.getStoredSession(),
      ).thenAnswer((_) async => Right(testSession));

      when(
        mockSessionService.validateSession(),
      ).thenAnswer((_) async => const Right(true));

      final refreshedSession = SessionData(
        accessToken: 'new-token',
        refreshToken: 'new-refresh-token',
        user: testUser,
        userProfile: testProfile,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        refreshExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      when(
        mockSessionService.refreshSession(),
      ).thenAnswer((_) async => Right(refreshedSession));

      when(
        mockSessionManager.initialize(),
      ).thenAnswer((_) async => Right(testSession));

      when(mockAuthRepository.currentUser).thenReturn(testUser);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(testUser));

      // Act - Launch app and trigger multiple operations
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Simulate rapid navigation that might trigger concurrent session checks
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.person));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.byIcon(Icons.home));
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();

      // Assert - Verify operations completed without conflicts
      verify(mockSessionService.getStoredSession()).called(1);
      verify(mockSessionManager.initialize()).called(1);

      // Verify user remains authenticated
      expect(find.text('Đăng nhập'), findsNothing);
    });
  });
}
