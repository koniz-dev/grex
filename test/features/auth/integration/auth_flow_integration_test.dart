import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:grex/features/auth/presentation/bloc/auth_event.dart';
import 'package:grex/features/auth/presentation/bloc/auth_state.dart';
import 'package:grex/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:grex/features/auth/presentation/bloc/profile_event.dart';
import 'package:grex/features/auth/presentation/bloc/profile_state.dart';
import 'package:grex/features/auth/presentation/pages/login_page.dart';
import 'package:grex/features/auth/presentation/pages/profile_page.dart';
import 'package:grex/features/auth/presentation/pages/register_page.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/test_helpers.mocks.dart';

/// Integration tests for end-to-end authentication flows
///
/// Tests complete user journeys from UI interactions through BLoC to
/// repositories
/// Validates: Requirements 1.1, 1.2, 2.1, 4.1, 7.1
void main() {
  group('Authentication Flow Integration Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late MockSessionManager mockSessionManager;
    late AuthBloc authBloc;
    late ProfileBloc profileBloc;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
      mockSessionManager = MockSessionManager();
      authBloc = AuthBloc(
        authRepository: mockAuthRepository,
        userRepository: mockUserRepository,
        sessionManager: mockSessionManager,
      );
      profileBloc = ProfileBloc(
        userRepository: mockUserRepository,
        authRepository: mockAuthRepository,
      );
    });

    tearDown(() async {
      await authBloc.close();
      await profileBloc.close();
    });

    testWidgets('Complete registration flow from UI to repository', (
      tester,
    ) async {
      // Arrange
      const testEmail = 'test@example.com';
      const testPassword = 'TestPassword123';
      const testDisplayName = 'Test User';

      final testUser = User(
        id: 'test-user-id',
        email: testEmail,
        emailConfirmed: false,
        createdAt: DateTime.now(),
        lastSignInAt: DateTime.now(),
      );

      final testProfile = UserProfile(
        id: 'test-user-id',
        email: testEmail,
        displayName: testDisplayName,
        preferredCurrency: 'VND',
        languageCode: 'vi',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock successful registration
      when(
        mockAuthRepository.signUpWithEmail(
          email: testEmail,
          password: testPassword,
        ),
      ).thenAnswer((_) async => Right(testUser));

      // Mock successful profile creation
      when(
        mockUserRepository.createUserProfile(any),
      ).thenAnswer((_) async => Right(testProfile));

      // Mock auth state stream
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(testUser));

      // Act - Build registration page with BLoC
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<ProfileBloc>.value(value: profileBloc),
            ],
            child: const RegisterPage(),
          ),
        ),
      );

      // Fill registration form
      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        testEmail,
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        testPassword,
      );
      await tester.enterText(
        find.byKey(const Key('register_display_name_field')),
        testDisplayName,
      );

      // Submit registration
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      // Assert - Verify registration was called
      verify(
        mockAuthRepository.signUpWithEmail(
          email: testEmail,
          password: testPassword,
        ),
      ).called(1);

      // Verify profile creation was called
      verify(mockUserRepository.createUserProfile(any)).called(1);
    });

    testWidgets('Complete login flow with session establishment', (
      tester,
    ) async {
      // Arrange
      const testEmail = 'test@example.com';
      const testPassword = 'TestPassword123';

      final testUser = User(
        id: 'test-user-id',
        email: testEmail,
        createdAt: DateTime.now(),
        lastSignInAt: DateTime.now(),
      );

      // Mock successful login
      when(
        mockAuthRepository.signInWithEmail(
          email: testEmail,
          password: testPassword,
        ),
      ).thenAnswer((_) async => Right(testUser));

      // Mock auth state stream
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(testUser));

      // Mock current user
      when(mockAuthRepository.currentUser).thenReturn(testUser);

      // Act - Build login page with BLoC
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<ProfileBloc>.value(value: profileBloc),
            ],
            child: const LoginPage(),
          ),
        ),
      );

      // Fill login form
      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        testEmail,
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        testPassword,
      );

      // Submit login
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      // Assert - Verify login was called
      verify(
        mockAuthRepository.signInWithEmail(
          email: testEmail,
          password: testPassword,
        ),
      ).called(1);

      // Verify BLoC state changed to authenticated
      expect(authBloc.state, isA<AuthAuthenticated>());
    });

    testWidgets('Login with authentication failure shows error', (
      tester,
    ) async {
      // Arrange
      const testEmail = 'test@example.com';
      const testPassword = 'WrongPassword';

      // Mock authentication failure
      when(
        mockAuthRepository.signInWithEmail(
          email: testEmail,
          password: testPassword,
        ),
      ).thenAnswer((_) async => const Left(InvalidCredentialsFailure()));

      // Mock no current user
      when(mockAuthRepository.currentUser).thenReturn(null);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(null));

      // Act - Build login page with BLoC
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<ProfileBloc>.value(value: profileBloc),
            ],
            child: const LoginPage(),
          ),
        ),
      );

      // Fill login form
      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        testEmail,
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        testPassword,
      );

      // Submit login
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      // Assert - Verify error message is shown
      expect(find.text('Email hoặc mật khẩu không đúng'), findsOneWidget);

      // Verify BLoC state is error
      expect(authBloc.state, isA<AuthError>());
    });

    testWidgets('Registration with validation errors', (tester) async {
      // Arrange
      const invalidEmail = 'invalid-email';
      const weakPassword = '123';

      // Mock no current user
      when(mockAuthRepository.currentUser).thenReturn(null);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(null));

      // Act - Build registration page with BLoC
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<ProfileBloc>.value(value: profileBloc),
            ],
            child: const RegisterPage(),
          ),
        ),
      );

      // Fill form with invalid data
      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        invalidEmail,
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        weakPassword,
      );

      // Try to submit
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      // Assert - Verify validation errors are shown
      expect(find.text('Email không hợp lệ'), findsOneWidget);
      expect(find.text('Mật khẩu phải có ít nhất 8 ký tự'), findsOneWidget);

      // Verify repository was not called due to validation
      verifyNever(
        mockAuthRepository.signUpWithEmail(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      );
    });
  });

  group('Profile Management Integration Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late MockSessionManager mockSessionManager;
    late AuthBloc authBloc;
    late ProfileBloc profileBloc;
    late User testUser;
    late UserProfile testProfile;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
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

      authBloc = AuthBloc(
        authRepository: mockAuthRepository,
        userRepository: mockUserRepository,
        sessionManager: mockSessionManager,
      );

      profileBloc = ProfileBloc(
        userRepository: mockUserRepository,
        authRepository: mockAuthRepository,
      );

      // Setup authenticated user
      when(mockAuthRepository.currentUser).thenReturn(testUser);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(testUser));
    });

    tearDown(() async {
      await authBloc.close();
      await profileBloc.close();
    });

    testWidgets('Profile loading from repository', (tester) async {
      // Arrange
      when(
        mockUserRepository.getUserProfile(testUser.id),
      ).thenAnswer((_) async => Right(testProfile));

      // Act - Build profile page with BLoC
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<ProfileBloc>.value(value: profileBloc),
            ],
            child: const ProfilePage(),
          ),
        ),
      );

      // Trigger profile load
      profileBloc.add(const ProfileLoadRequested());
      await tester.pumpAndSettle();

      // Assert - Verify profile data is loaded and displayed
      verify(mockUserRepository.getUserProfile(testUser.id)).called(1);

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('VND'), findsOneWidget);
    });

    testWidgets('Profile update with repository persistence', (tester) async {
      // Arrange
      const updatedDisplayName = 'Updated User Name';
      const updatedCurrency = 'USD';

      final updatedProfile = testProfile.copyWith(
        displayName: updatedDisplayName,
        preferredCurrency: updatedCurrency,
        updatedAt: DateTime.now(),
      );

      // Mock initial profile load
      when(
        mockUserRepository.getUserProfile(testUser.id),
      ).thenAnswer((_) async => Right(testProfile));

      // Mock successful profile update
      when(
        mockUserRepository.updateUserProfile(any),
      ).thenAnswer((_) async => Right(updatedProfile));

      // Act - Load profile first
      profileBloc.add(const ProfileLoadRequested());
      await tester.pumpAndSettle();

      // Update profile
      profileBloc.add(
        const ProfileUpdateRequested(
          displayName: updatedDisplayName,
          preferredCurrency: updatedCurrency,
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Verify update was called with correct data
      final captured =
          verify(
                mockUserRepository.updateUserProfile(captureAny),
              ).captured.single
              as UserProfile;

      expect(captured.displayName, equals(updatedDisplayName));
      expect(captured.preferredCurrency, equals(updatedCurrency));

      // Verify BLoC state shows updated profile
      expect(profileBloc.state, isA<ProfileLoaded>());
      final loadedState = profileBloc.state as ProfileLoaded;
      expect(loadedState.profile.displayName, equals(updatedDisplayName));
    });

    testWidgets('Profile error scenarios', (tester) async {
      // Arrange - Mock profile loading failure
      when(
        mockUserRepository.getUserProfile(testUser.id),
      ).thenAnswer((_) async => const Left(UserNotFoundFailure()));

      // Act - Build profile page with BLoC
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<ProfileBloc>.value(value: profileBloc),
            ],
            child: const ProfilePage(),
          ),
        ),
      );

      // Trigger profile load
      profileBloc.add(const ProfileLoadRequested());
      await tester.pumpAndSettle();

      // Assert - Verify error state
      expect(profileBloc.state, isA<ProfileError>());
      final errorState = profileBloc.state as ProfileError;
      expect(
        errorState.message,
        contains('Không tìm thấy thông tin người dùng'),
      );
    });
  });

  group('Session Management Integration Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late MockSessionManager mockSessionManager;
    late AuthBloc authBloc;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
      mockSessionManager = MockSessionManager();
      authBloc = AuthBloc(
        authRepository: mockAuthRepository,
        userRepository: mockUserRepository,
        sessionManager: mockSessionManager,
      );
    });

    tearDown(() async {
      await authBloc.close();
    });

    testWidgets('Session initialization on app start', (tester) async {
      // Arrange
      final testUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        lastSignInAt: DateTime.now(),
      );

      // Mock existing session
      when(mockAuthRepository.currentUser).thenReturn(testUser);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(testUser));

      // Act - Initialize auth BLoC (simulates app start)
      authBloc.add(const AuthSessionChecked());
      await tester.pumpAndSettle();

      // Assert - Verify session was checked and user is authenticated
      expect(authBloc.state, isA<AuthAuthenticated>());
      final authenticatedState = authBloc.state as AuthAuthenticated;
      expect(authenticatedState.user.id, equals(testUser.id));
    });

    testWidgets('Session cleanup on logout', (tester) async {
      // Arrange
      final testUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        lastSignInAt: DateTime.now(),
      );

      // Mock authenticated user initially
      when(mockAuthRepository.currentUser).thenReturn(testUser);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(testUser));

      // Mock successful logout
      when(
        mockAuthRepository.signOut(),
      ).thenAnswer((_) async => const Right(null));

      // Act - Start with authenticated user
      authBloc.add(const AuthSessionChecked());
      await tester.pumpAndSettle();

      expect(authBloc.state, isA<AuthAuthenticated>());

      // Logout
      authBloc.add(const AuthLogoutRequested());
      await tester.pumpAndSettle();

      // Assert - Verify logout was called and state is unauthenticated
      verify(mockAuthRepository.signOut()).called(1);
      expect(authBloc.state, isA<AuthUnauthenticated>());
    });

    testWidgets('Session expiration handling', (tester) async {
      // Arrange
      final testUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        lastSignInAt: DateTime.now(),
      );

      // Mock session that becomes invalid
      var callCount = 0;
      when(
        mockAuthRepository.currentUser,
      ).thenAnswer((_) {
        callCount++;
        return callCount == 1
            ? testUser
            : null; // Session expires on second call
      });

      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.fromIterable([testUser, null]));

      // Act - Start with valid session
      authBloc.add(const AuthSessionChecked());
      await tester.pumpAndSettle();

      expect(authBloc.state, isA<AuthAuthenticated>());

      // Simulate session expiration
      await tester.pumpAndSettle();

      // Assert - Verify state changes to unauthenticated
      expect(authBloc.state, isA<AuthUnauthenticated>());
    });
  });
}
