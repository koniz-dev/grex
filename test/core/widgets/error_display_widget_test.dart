import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/core/widgets/error_display_widget.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';

/// Unit tests for ErrorDisplayWidget
///
/// Tests error display components, retry mechanisms, error message formatting,
/// and error recovery flows.
///
/// Requirements: 1.3, 2.2, 2.4, 3.5, 4.4, 5.4
void main() {
  group('ErrorDisplayWidget', () {
    testWidgets('should display authentication error correctly', (
      tester,
    ) async {
      // Arrange
      const error = InvalidCredentialsFailure();
      var retryPressed = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplayWidget(
              error: error,
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Thông tin đăng nhập không đúng'), findsOneWidget);
      expect(
        find.text(
          'Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      // Test retry button
      await tester.tap(find.text('Thử lại'));
      expect(retryPressed, isTrue);
    });

    testWidgets('should display network error correctly', (tester) async {
      // Arrange
      const error = NetworkFailure();

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDisplayWidget(
              error: error,
              showRetry: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Lỗi kết nối'), findsOneWidget);
      expect(
        find.text(
          'Không thể kết nối đến máy chủ. '
          'Vui lòng kiểm tra kết nối mạng và thử lại.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('Thử lại'), findsNothing);
    });

    testWidgets('should display user error correctly', (tester) async {
      // Arrange
      const error = UserNotFoundFailure();

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDisplayWidget(
              error: error,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Không tìm thấy người dùng'), findsOneWidget);
      expect(
        find.text(
          'Thông tin người dùng không tồn tại. Vui lòng liên hệ hỗ trợ.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.person_off_outlined), findsOneWidget);
    });

    testWidgets('should display custom message when provided', (tester) async {
      // Arrange
      const error = GenericAuthFailure('Some error');
      const customMessage = 'Custom error message';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDisplayWidget(
              error: error,
              customMessage: customMessage,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(customMessage), findsOneWidget);
    });

    testWidgets('should show dismiss button when enabled', (tester) async {
      // Arrange
      const error = GenericAuthFailure('Some error');
      var dismissPressed = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplayWidget(
              error: error,
              showDismiss: true,
              onDismiss: () => dismissPressed = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Test dismiss button
      await tester.tap(find.byIcon(Icons.close));
      expect(dismissPressed, isTrue);
    });

    testWidgets('should handle different auth failure types', (tester) async {
      final testCases = [
        (
          error: const EmailAlreadyInUseFailure(),
          expectedTitle: 'Email đã được sử dụng',
          expectedIcon: Icons.email_outlined,
        ),
        (
          error: const WeakPasswordFailure(),
          expectedTitle: 'Mật khẩu không đủ mạnh',
          expectedIcon: Icons.security,
        ),
        (
          error: const UnverifiedEmailFailure(),
          expectedTitle: 'Email chưa được xác thực',
          expectedIcon: Icons.mark_email_unread,
        ),
      ];

      for (final testCase in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorDisplayWidget(error: testCase.error),
            ),
          ),
        );

        expect(find.text(testCase.expectedTitle), findsOneWidget);
        expect(find.byIcon(testCase.expectedIcon), findsOneWidget);

        // Clean up for next test
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('should handle generic errors', (tester) async {
      // Arrange
      const error = 'Some generic error message';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDisplayWidget(error: error),
          ),
        ),
      );

      // Assert
      expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
      expect(find.text(error), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should handle null errors gracefully', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDisplayWidget(error: null),
          ),
        ),
      );

      // Assert
      expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should apply correct styling for different error types', (
      tester,
    ) async {
      // Arrange
      const error = InvalidCredentialsFailure();

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDisplayWidget(error: error),
          ),
        ),
      );

      // Assert - Check that container has correct styling
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ErrorDisplayWidget),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, isNotNull);
      expect(decoration.border, isNotNull);
      expect(decoration.borderRadius, isNotNull);
    });
  });
}
