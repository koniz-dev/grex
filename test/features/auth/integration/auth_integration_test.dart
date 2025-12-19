import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/repositories/auth_repository.dart';
import 'package:grex/features/auth/domain/repositories/user_repository.dart';
import 'package:grex/main.dart' as app;
import 'package:mockito/mockito.dart';

import '../../../helpers/test_helpers.mocks.dart';

/// Integration tests for end-to-end authentication flows
///
/// Tests complete user journeys from UI interactions to database operations
/// Validates: Requirements 1.1, 1.2, 2.1, 4.1, 7.1
void main() {
  group('End-to-End Authentication Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;

    setUp(() async {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();

      // Reset dependency injection
      await configureDependencies();

      // Override with mocks for testing
      getIt
        ..unregister<AuthRepository>()
        ..unregister<UserRepository>()
        ..registerSingleton<AuthRepository>(mockAuthRepository)
        ..registerSingleton<UserRepository>(mockUserRepository);
    });

    tearDown(() async {
      await getIt.reset();
    });

    testWidgets('Complete registration flow from UI to database', (
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

      // Act - Launch app
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to register page
      expect(find.text('Đăng ký'), findsOneWidget);
      await tester.tap(find.text('Đăng ký'));
      await tester.pumpAndSettle();

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

      // Verify navigation to email verification
      expect(find.text('Xác thực email'), findsOneWidget);
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

      // Act - Launch app
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Should be on login page initially
      expect(find.text('Đăng nhập'), findsOneWidget);

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

      // Verify session establishment (navigation away from login)
      expect(find.text('Đăng nhập'), findsNothing);
    });

    testWidgets('Password reset flow end-to-end', (tester) async {
      // Arrange
      const testEmail = 'test@example.com';

      // Mock successful password reset
      when(
        mockAuthRepository.resetPassword(email: testEmail),
      ).thenAnswer((_) async => const Right(null));

      // Mock no current user (unauthenticated)
      when(mockAuthRepository.currentUser).thenReturn(null);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(null));

      // Act - Launch app
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to forgot password page
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pumpAndSettle();

      // Fill email field
      await tester.enterText(
        find.byKey(const Key('forgot_password_email_field')),
        testEmail,
      );

      // Submit password reset
      await tester.tap(find.byKey(const Key('forgot_password_submit_button')));
      await tester.pumpAndSettle();

      // Assert - Verify password reset was called
      verify(mockAuthRepository.resetPassword(email: testEmail)).called(1);

      // Verify success message is shown
      expect(find.text('Email đặt lại mật khẩu đã được gửi'), findsOneWidget);
    });

    testWidgets('Email verification flow', (tester) async {
      // Arrange
      const testEmail = 'test@example.com';

      final unverifiedUser = User(
        id: 'test-user-id',
        email: testEmail,
        emailConfirmed: false,
        createdAt: DateTime.now(),
        lastSignInAt: DateTime.now(),
      );

      final verifiedUser = User(
        id: 'test-user-id',
        email: testEmail,
        createdAt: DateTime.now(),
        lastSignInAt: DateTime.now(),
      );

      // Mock current unverified user
      when(mockAuthRepository.currentUser).thenReturn(unverifiedUser);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(unverifiedUser));

      // Mock successful verification email resend
      when(
        mockAuthRepository.sendVerificationEmail(),
      ).thenAnswer((_) async => const Right(null));

      // Act - Launch app
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Should be on email verification page for unverified user
      expect(find.text('Xác thực email'), findsOneWidget);

      // Tap resend verification email
      await tester.tap(find.byKey(const Key('resend_verification_button')));
      await tester.pumpAndSettle();

      // Assert - Verify resend was called
      verify(mockAuthRepository.sendVerificationEmail()).called(1);

      // Simulate email verification completion
      when(mockAuthRepository.currentUser).thenReturn(verifiedUser);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(verifiedUser));

      // Trigger auth state change
      await tester.pumpAndSettle();

      // Verify navigation away from verification page
      expect(find.text('Xác thực email'), findsNothing);
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

      // Act - Launch app
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to register page
      await tester.tap(find.text('Đăng ký'));
      await tester.pumpAndSettle();

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

    testWidgets('Login with authentication failure', (tester) async {
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

      // Act - Launch app
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

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

      // Verify still on login page
      expect(find.text('Đăng nhập'), findsOneWidget);
    });
  });
}
