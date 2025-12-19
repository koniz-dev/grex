import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/property_test_helpers.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../helpers/widget_test_helpers.dart';

/// Widget tests for authentication navigation flows
///
/// Tests route transitions, route guards, and deep link handling
/// for the authentication system.
void main() {
  group('Authentication Navigation Widget Tests', () {
    late TestDependencies deps;
    late GoRouter router;

    setUp(() {
      deps = setupTestDependencies();
      router = createTestRouter(deps);
    });

    tearDown(() async {
      await deps.dispose();
    });

    testWidgets('should navigate from login to register', (tester) async {
      // Arrange
      when(deps.mockAuthRepository.currentUser).thenReturn(null);

      // Build app with login page
      await tester.pumpWidget(
        createTestApp(
          router: router,
          initialLocation: '/login',
        ),
      );
      await tester.pumpAndSettle();

      // Verify we're on login page
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Chưa có tài khoản?'), findsOneWidget);

      // Act - tap register link
      await tester.tap(find.text('Đăng ký ngay'));
      await tester.pumpAndSettle();

      // Assert - should navigate to register page
      expect(find.text('Tạo tài khoản'), findsOneWidget);
      expect(find.text('Đã có tài khoản?'), findsOneWidget);
    });

    testWidgets('should navigate from register to login', (tester) async {
      // Arrange
      when(deps.mockAuthRepository.currentUser).thenReturn(null);

      // Build app with register page
      await tester.pumpWidget(
        createTestApp(
          router: router,
          initialLocation: '/register',
        ),
      );
      await tester.pumpAndSettle();

      // Verify we're on register page
      expect(find.text('Tạo tài khoản'), findsOneWidget);
      expect(find.text('Đã có tài khoản?'), findsOneWidget);

      // Act - tap login link
      await tester.tap(find.text('Đăng nhập ngay'));
      await tester.pumpAndSettle();

      // Assert - should navigate to login page
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Chưa có tài khoản?'), findsOneWidget);
    });

    testWidgets('should navigate from login to forgot password', (
      tester,
    ) async {
      // Arrange
      when(deps.mockAuthRepository.currentUser).thenReturn(null);

      // Build app with login page
      await tester.pumpWidget(
        createTestApp(
          router: router,
          initialLocation: '/login',
        ),
      );
      await tester.pumpAndSettle();

      // Verify we're on login page
      expect(find.text('Đăng nhập'), findsOneWidget);

      // Act - tap forgot password link
      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pumpAndSettle();

      // Assert - should navigate to forgot password page
      expect(find.text('Đặt lại mật khẩu'), findsOneWidget);
      expect(
        find.text('Nhập email để nhận liên kết đặt lại mật khẩu'),
        findsOneWidget,
      );
    });

    testWidgets('should redirect unauthenticated user to login', (
      tester,
    ) async {
      // Arrange - user is not authenticated
      when(deps.mockAuthRepository.currentUser).thenReturn(null);

      // Act - try to access protected route (profile)
      await tester.pumpWidget(
        createTestApp(
          router: router,
          initialLocation: '/profile',
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should be redirected to login
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
    });

    testWidgets('should redirect authenticated user from auth pages to home', (
      tester,
    ) async {
      // Arrange - user is authenticated
      final user = generateValidUser();
      final userProfile = generateValidUserProfile();

      when(deps.mockAuthRepository.currentUser).thenReturn(user);
      when(
        deps.mockUserRepository.getUserProfile(user.id),
      ).thenAnswer((_) async => Right(userProfile));

      // Act - try to access login page while authenticated
      await tester.pumpWidget(
        createTestApp(
          router: router,
          initialLocation: '/login',
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should be redirected to home
      // Note: This depends on your home page implementation
      expect(find.text('Đăng nhập'), findsNothing);
    });

    testWidgets('should navigate to email verification after registration', (
      tester,
    ) async {
      // Arrange
      when(deps.mockAuthRepository.currentUser).thenReturn(null);

      final user = generateValidUser();
      when(
        deps.mockAuthRepository.signUpWithEmail(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => Right(user));

      // Build app with register page
      await tester.pumpWidget(
        createTestApp(
          router: router,
          initialLocation: '/register',
        ),
      );
      await tester.pumpAndSettle();

      // Fill registration form
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'SecurePass123!',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'SecurePass123!',
      );
      await tester.enterText(
        find.byKey(const Key('display_name_field')),
        'Test User',
      );

      // Submit form
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      // Should navigate to email verification
      expect(find.text('Xác thực email'), findsOneWidget);
      expect(find.text('Chúng tôi đã gửi email xác thực'), findsOneWidget);
    });

    testWidgets('should navigate to profile edit page', (tester) async {
      // Arrange - user is authenticated
      final user = generateValidUser();
      final userProfile = generateValidUserProfile();

      when(deps.mockAuthRepository.currentUser).thenReturn(user);
      when(
        deps.mockUserRepository.getUserProfile(user.id),
      ).thenAnswer((_) async => Right(userProfile));

      // Build app with profile page
      await tester.pumpWidget(
        createTestApp(
          router: router,
          initialLocation: '/profile',
        ),
      );
      await tester.pumpAndSettle();

      // Verify we're on profile page
      expect(find.text('Hồ sơ cá nhân'), findsOneWidget);

      // Act - tap edit profile button
      await tester.tap(find.byKey(const Key('edit_profile_button')));
      await tester.pumpAndSettle();

      // Assert - should navigate to edit profile page
      expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
      expect(find.text('Tên hiển thị'), findsOneWidget);
    });

    testWidgets('should handle deep link to password reset', (tester) async {
      // Arrange
      when(deps.mockAuthRepository.currentUser).thenReturn(null);

      // Act - navigate directly to forgot password page (simulating deep link)
      await tester.pumpWidget(
        createTestApp(
          router: router,
          initialLocation: '/forgot-password',
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should show forgot password page
      expect(find.text('Đặt lại mật khẩu'), findsOneWidget);
      expect(
        find.text('Nhập email để nhận liên kết đặt lại mật khẩu'),
        findsOneWidget,
      );
    });

    testWidgets('should handle deep link to email verification', (
      tester,
    ) async {
      // Arrange
      when(deps.mockAuthRepository.currentUser).thenReturn(null);

      // Act - navigate directly to email verification page
      await tester.pumpWidget(
        createTestApp(
          router: router,
          initialLocation: '/email-verification',
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should show email verification page
      expect(find.text('Xác thực email'), findsOneWidget);
      expect(find.text('Gửi lại email xác thực'), findsOneWidget);
    });

    testWidgets('should navigate back from forgot password to login', (
      tester,
    ) async {
      // Arrange
      when(deps.mockAuthRepository.currentUser).thenReturn(null);

      // Start at forgot password page
      await tester.pumpWidget(
        createTestApp(
          router: router,
          initialLocation: '/forgot-password',
        ),
      );
      await tester.pumpAndSettle();

      // Verify we're on forgot password page
      expect(find.text('Đặt lại mật khẩu'), findsOneWidget);

      // Act - tap back to login
      await tester.tap(find.byKey(const Key('back_to_login_button')));
      await tester.pumpAndSettle();

      // Assert - should navigate back to login
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });
  });
}
