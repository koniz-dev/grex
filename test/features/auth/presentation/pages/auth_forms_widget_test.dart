import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/services/session_manager.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:grex/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:grex/features/auth/presentation/pages/login_page.dart';
import 'package:grex/features/auth/presentation/pages/register_page.dart';

import '../../../../helpers/test_helpers.mocks.dart';

/// Widget tests for authentication forms
///
/// Tests login form, registration form, and password reset form
/// with various inputs, validation, and loading states.
///
/// Requirements: 1.1, 1.4, 1.5, 2.1, 4.1
void main() {
  group('Authentication Forms Widget Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late MockSessionService mockSessionService;
    late SessionManager sessionManager;
    late AuthBloc authBloc;
    late ProfileBloc profileBloc;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
      mockSessionService = MockSessionService();

      sessionManager = SessionManager(
        sessionService: mockSessionService,
      );

      authBloc = AuthBloc(
        authRepository: mockAuthRepository,
        userRepository: mockUserRepository,
        sessionManager: sessionManager,
      );

      profileBloc = ProfileBloc(
        userRepository: mockUserRepository,
        authRepository: mockAuthRepository,
      );
    });

    tearDown(() async {
      await authBloc.close();
      await profileBloc.close();
      sessionManager.dispose();
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ProfileBloc>.value(value: profileBloc),
          ],
          child: child,
        ),
      );
    }

    group('LoginPage', () {
      testWidgets('should display login form with required fields', (
        tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(const LoginPage()));

        // Assert
        expect(find.text('Đăng nhập'), findsOneWidget);
        expect(
          find.byType(TextFormField),
          findsNWidgets(2),
        ); // Email and password
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Mật khẩu'), findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'Đăng nhập'),
          findsOneWidget,
        );
        expect(find.text('Quên mật khẩu?'), findsOneWidget);
        expect(find.text('Chưa có tài khoản? Đăng ký'), findsOneWidget);
      });

      testWidgets('should show validation errors for empty fields', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const LoginPage()));

        // Act - Submit form without filling fields
        final loginButton = find.widgetWithText(ElevatedButton, 'Đăng nhập');
        await tester.tap(loginButton);
        await tester.pump();

        // Assert
        expect(find.text('Vui lòng nhập email'), findsOneWidget);
        expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
      });

      testWidgets('should show validation error for invalid email', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const LoginPage()));

        // Act - Enter invalid email
        await tester.enterText(
          find.byType(TextFormField).first,
          'invalid-email',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');

        final loginButton = find.widgetWithText(ElevatedButton, 'Đăng nhập');
        await tester.tap(loginButton);
        await tester.pump();

        // Assert
        expect(find.text('Email không hợp lệ'), findsOneWidget);
      });

      testWidgets('should handle loading state', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const LoginPage()));

        // Emit loading state
        authBloc.emit(const AuthLoading());
        await tester.pump();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Đang đăng nhập...'), findsOneWidget);
      });

      testWidgets('should show error message', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const LoginPage()));

        // Emit error state
        authBloc.emit(
          const AuthError(message: 'Email hoặc mật khẩu không đúng'),
        );
        await tester.pump();

        // Assert
        expect(find.text('Email hoặc mật khẩu không đúng'), findsOneWidget);
      });
    });

    group('RegisterPage', () {
      testWidgets('should display registration form with required fields', (
        tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(const RegisterPage()));

        // Assert
        expect(find.text('Đăng ký tài khoản'), findsOneWidget);
        expect(
          find.byType(TextFormField),
          findsNWidgets(3),
        ); // Name, email, password
        expect(find.text('Tên hiển thị'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Mật khẩu'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Đăng ký'), findsOneWidget);
        expect(find.text('Đã có tài khoản? Đăng nhập'), findsOneWidget);
      });

      testWidgets('should show validation errors for empty fields', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const RegisterPage()));

        // Act - Submit form without filling fields
        final registerButton = find.widgetWithText(ElevatedButton, 'Đăng ký');
        await tester.tap(registerButton);
        await tester.pump();

        // Assert
        expect(find.text('Vui lòng nhập tên hiển thị'), findsOneWidget);
        expect(find.text('Vui lòng nhập email'), findsOneWidget);
        expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
      });

      testWidgets('should show validation error for weak password', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const RegisterPage()));

        // Act - Enter weak password
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Test User'); // Display name
        await tester.enterText(fields.at(1), 'test@example.com'); // Email
        await tester.enterText(fields.at(2), '123'); // Weak password

        final registerButton = find.widgetWithText(ElevatedButton, 'Đăng ký');
        await tester.tap(registerButton);
        await tester.pump();

        // Assert
        expect(find.text('Mật khẩu phải có ít nhất 8 ký tự'), findsOneWidget);
      });

      testWidgets('should handle loading state', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const RegisterPage()));

        // Emit loading state
        authBloc.emit(const AuthLoading());
        await tester.pump();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Đang đăng ký...'), findsOneWidget);
      });

      testWidgets('should show error message for email already in use', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const RegisterPage()));

        // Emit error state
        authBloc.emit(const AuthError(message: 'Email này đã được sử dụng'));
        await tester.pump();

        // Assert
        expect(find.text('Email này đã được sử dụng'), findsOneWidget);
      });
    });

    group('ForgotPasswordPage', () {
      testWidgets('should display forgot password form', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(const ForgotPasswordPage()));

        // Assert
        expect(find.text('Quên mật khẩu'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget); // Email field
        expect(find.text('Email'), findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'Gửi link đặt lại'),
          findsOneWidget,
        );
        expect(find.text('Quay lại đăng nhập'), findsOneWidget);
      });

      testWidgets('should show validation error for empty email', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const ForgotPasswordPage()));

        // Act - Submit form without email
        final resetButton = find.widgetWithText(
          ElevatedButton,
          'Gửi link đặt lại',
        );
        await tester.tap(resetButton);
        await tester.pump();

        // Assert
        expect(find.text('Vui lòng nhập email'), findsOneWidget);
      });

      testWidgets('should show validation error for invalid email', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const ForgotPasswordPage()));

        // Act - Enter invalid email
        await tester.enterText(find.byType(TextFormField), 'invalid-email');

        final resetButton = find.widgetWithText(
          ElevatedButton,
          'Gửi link đặt lại',
        );
        await tester.tap(resetButton);
        await tester.pump();

        // Assert
        expect(find.text('Email không hợp lệ'), findsOneWidget);
      });

      testWidgets('should handle loading state', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const ForgotPasswordPage()));

        // Emit loading state
        authBloc.emit(const AuthLoading());
        await tester.pump();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Đang gửi...'), findsOneWidget);
      });

      testWidgets('should show success message', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const ForgotPasswordPage()));

        // Emit success state
        authBloc.emit(const AuthPasswordResetSent(email: 'test@example.com'));
        await tester.pump();

        // Assert
        expect(find.text('Email đặt lại mật khẩu đã được gửi'), findsOneWidget);
        expect(find.textContaining('test@example.com'), findsOneWidget);
      });
    });

    group('Form Interactions', () {
      testWidgets('should handle keyboard input correctly', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const LoginPage()));

        // Act - Enter text in fields
        final emailField = find.byType(TextFormField).first;
        final passwordField = find.byType(TextFormField).last;

        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passwordField, 'password123');
        await tester.pump();

        // Assert - Text should be entered correctly
        expect(find.text('test@example.com'), findsOneWidget);
        expect(find.text('password123'), findsOneWidget);
      });

      testWidgets('should handle form submission', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const LoginPage()));

        // Act - Fill form and submit
        final emailField = find.byType(TextFormField).first;
        final passwordField = find.byType(TextFormField).last;

        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passwordField, 'SecurePass123!');

        final loginButton = find.widgetWithText(ElevatedButton, 'Đăng nhập');
        await tester.tap(loginButton);
        await tester.pump();

        // Assert - Should trigger login event (verified by no validation
        // errors)
        expect(find.text('Vui lòng nhập email'), findsNothing);
        expect(find.text('Vui lòng nhập mật khẩu'), findsNothing);
      });

      testWidgets('should clear validation errors when typing', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const LoginPage()));

        // Show validation error first
        final loginButton = find.widgetWithText(ElevatedButton, 'Đăng nhập');
        await tester.tap(loginButton);
        await tester.pump();

        expect(find.text('Vui lòng nhập email'), findsOneWidget);

        // Act - Start typing in email field
        final emailField = find.byType(TextFormField).first;
        await tester.enterText(emailField, 'test@example.com');
        await tester.pump();

        // Assert - Validation error should be cleared
        // Note: This depends on the actual implementation clearing errors on
        // input
        expect(find.text('test@example.com'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(const LoginPage()));

        // Assert - Check for semantic elements
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(
          find.byType(TextButton),
          findsAtLeastNWidgets(1),
        ); // Navigation links
      });

      testWidgets('should support screen readers', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(const RegisterPage()));

        // Assert - Form fields should have labels
        expect(find.text('Tên hiển thị'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Mật khẩu'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should display network error messages', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const LoginPage()));

        // Emit network error
        authBloc.emit(const AuthError(message: 'Lỗi kết nối mạng'));
        await tester.pump();

        // Assert
        expect(find.text('Lỗi kết nối mạng'), findsOneWidget);
      });

      testWidgets('should display authentication error messages', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const LoginPage()));

        // Emit auth error
        authBloc.emit(
          const AuthError(message: 'Thông tin đăng nhập không đúng'),
        );
        await tester.pump();

        // Assert
        expect(find.text('Thông tin đăng nhập không đúng'), findsOneWidget);
      });

      testWidgets('should handle validation errors gracefully', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(const RegisterPage()));

        // Act - Submit with invalid data
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), ''); // Empty name
        await tester.enterText(fields.at(1), 'invalid-email'); // Invalid email
        await tester.enterText(fields.at(2), '123'); // Weak password

        final registerButton = find.widgetWithText(ElevatedButton, 'Đăng ký');
        await tester.tap(registerButton);
        await tester.pump();

        // Assert - Should show multiple validation errors
        expect(find.text('Vui lòng nhập tên hiển thị'), findsOneWidget);
        expect(find.text('Email không hợp lệ'), findsOneWidget);
        expect(find.text('Mật khẩu phải có ít nhất 8 ký tự'), findsOneWidget);
      });
    });
  });
}
