import 'package:flutter_test/flutter_test.dart';
import 'package:grex/core/utils/error_messages.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';

/// Unit tests for ErrorMessages utility
///
/// Tests error message formatting, localization, and user-friendly
/// message generation for different error types.
///
/// Requirements: 1.3, 2.2, 2.4, 3.5, 4.4, 5.4
void main() {
  group('ErrorMessages', () {
    group('getErrorMessage', () {
      test(
        'should return user-friendly message for InvalidCredentialsFailure',
        () {
          // Arrange
          const error = InvalidCredentialsFailure();

          // Act
          final message = ErrorMessages.getErrorMessage(error);

          // Assert
          expect(
            message,
            equals(
              'Email hoặc mật khẩu không chính xác. '
              'Vui lòng kiểm tra lại thông tin đăng nhập.',
            ),
          );
        },
      );

      test(
        'should return user-friendly message for EmailAlreadyInUseFailure',
        () {
          // Arrange
          const error = EmailAlreadyInUseFailure();

          // Act
          final message = ErrorMessages.getErrorMessage(error);

          // Assert
          expect(
            message,
            equals(
              'Email này đã được đăng ký. '
              'Vui lòng sử dụng email khác hoặc đăng nhập với tài khoản '
              'hiện có.',
            ),
          );
        },
      );

      test('should return user-friendly message for WeakPasswordFailure', () {
        // Arrange
        const error = WeakPasswordFailure();

        // Act
        final message = ErrorMessages.getErrorMessage(error);

        // Assert
        expect(
          message,
          equals(
            'Mật khẩu không đủ mạnh. '
            'Vui lòng sử dụng mật khẩu có ít nhất 8 ký tự, '
            'bao gồm chữ hoa, chữ thường và số.',
          ),
        );
      });

      test(
        'should return user-friendly message for UnverifiedEmailFailure',
        () {
          // Arrange
          const error = UnverifiedEmailFailure();

          // Act
          final message = ErrorMessages.getErrorMessage(error);

          // Assert
          expect(
            message,
            equals(
              'Email chưa được xác thực. '
              'Vui lòng kiểm tra hộp thư và nhấp vào link xác thực.',
            ),
          );
        },
      );

      test('should return user-friendly message for NetworkFailure', () {
        // Arrange
        const error = NetworkFailure();

        // Act
        final message = ErrorMessages.getErrorMessage(error);

        // Assert
        expect(
          message,
          equals(
            'Không thể kết nối đến máy chủ. '
            'Vui lòng kiểm tra kết nối mạng và thử lại.',
          ),
        );
      });

      test('should return user-friendly message for UserNotFoundFailure', () {
        // Arrange
        const error = UserNotFoundFailure();

        // Act
        final message = ErrorMessages.getErrorMessage(error);

        // Assert
        expect(
          message,
          equals(
            'Không tìm thấy thông tin người dùng. '
            'Vui lòng đăng nhập lại hoặc liên hệ hỗ trợ.',
          ),
        );
      });

      test('should return user-friendly message for ValidationFailure', () {
        // Arrange
        const error = GenericValidationFailure('field', 'Invalid data');

        // Act
        final message = ErrorMessages.getErrorMessage(error);

        // Assert
        expect(
          message,
          equals(
            'Thông tin nhập vào không hợp lệ. Vui lòng kiểm tra và nhập lại.',
          ),
        );
      });

      test('should handle string errors', () {
        // Arrange
        const error = 'Network connection failed';

        // Act
        final message = ErrorMessages.getErrorMessage(error);

        // Assert
        expect(
          message,
          equals('Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.'),
        );
      });

      test('should handle generic errors', () {
        // Arrange
        final error = Exception('Some unknown error');

        // Act
        final message = ErrorMessages.getErrorMessage(error);

        // Assert
        expect(message, contains('Exception: Some unknown error'));
      });

      test('should handle null errors', () {
        // Act
        final message = ErrorMessages.getErrorMessage(null);

        // Assert
        expect(message, equals('Đã xảy ra lỗi không xác định.'));
      });
    });

    group('getValidationMessage', () {
      test('should return email validation messages', () {
        expect(
          ErrorMessages.getValidationMessage('email', 'invalid format'),
          equals('Định dạng email không hợp lệ.'),
        );

        expect(
          ErrorMessages.getValidationMessage('email', 'required field'),
          equals('Email là bắt buộc.'),
        );

        expect(
          ErrorMessages.getValidationMessage('email', 'email already exists'),
          equals('Email này đã được sử dụng.'),
        );
      });

      test('should return password validation messages', () {
        expect(
          ErrorMessages.getValidationMessage('password', 'too short'),
          equals('Mật khẩu phải có ít nhất 8 ký tự.'),
        );

        expect(
          ErrorMessages.getValidationMessage('password', 'weak password'),
          equals('Mật khẩu phải bao gồm chữ hoa, chữ thường và số.'),
        );

        expect(
          ErrorMessages.getValidationMessage('password', 'required field'),
          equals('Mật khẩu là bắt buộc.'),
        );
      });

      test('should return display name validation messages', () {
        expect(
          ErrorMessages.getValidationMessage('displayName', 'required field'),
          equals('Tên hiển thị là bắt buộc.'),
        );

        expect(
          ErrorMessages.getValidationMessage('display_name', 'too long'),
          equals('Tên hiển thị quá dài.'),
        );
      });

      test('should return currency validation messages', () {
        expect(
          ErrorMessages.getValidationMessage('currency', 'invalid code'),
          equals('Mã tiền tệ không hợp lệ.'),
        );
      });

      test('should return language validation messages', () {
        expect(
          ErrorMessages.getValidationMessage('language', 'invalid code'),
          equals('Mã ngôn ngữ không hợp lệ.'),
        );
      });

      test('should return empty string for null or empty error', () {
        expect(ErrorMessages.getValidationMessage('email', null), equals(''));
        expect(ErrorMessages.getValidationMessage('email', ''), equals(''));
      });
    });

    group('getOperationErrorMessage', () {
      test('should return operation-specific error messages', () {
        const error = InvalidCredentialsFailure();

        expect(
          ErrorMessages.getOperationErrorMessage('login', error),
          contains('Đăng nhập thất bại:'),
        );

        expect(
          ErrorMessages.getOperationErrorMessage('register', error),
          contains('Đăng ký thất bại:'),
        );

        expect(
          ErrorMessages.getOperationErrorMessage('logout', error),
          contains('Đăng xuất thất bại:'),
        );

        expect(
          ErrorMessages.getOperationErrorMessage('reset_password', error),
          contains('Đặt lại mật khẩu thất bại:'),
        );

        expect(
          ErrorMessages.getOperationErrorMessage('verify_email', error),
          contains('Xác thực email thất bại:'),
        );

        expect(
          ErrorMessages.getOperationErrorMessage('update_profile', error),
          contains('Cập nhật thông tin thất bại:'),
        );

        expect(
          ErrorMessages.getOperationErrorMessage('load_profile', error),
          contains('Tải thông tin thất bại:'),
        );
      });

      test('should return base message for unknown operations', () {
        const error = NetworkFailure();
        final baseMessage = ErrorMessages.getErrorMessage(error);

        final operationMessage = ErrorMessages.getOperationErrorMessage(
          'unknown_operation',
          error,
        );

        expect(operationMessage, equals(baseMessage));
      });
    });

    group('humanizeErrorMessage', () {
      test('should remove technical prefixes', () {
        final testCases = [
          ('Exception: Some error', 'Some error.'),
          ('Error: Another error', 'Another error.'),
          ('Failure: Failed operation', 'Failed operation.'),
          ('AuthException: Auth failed', 'Auth failed.'),
        ];

        for (final testCase in testCases) {
          final result = ErrorMessages.getErrorMessage(testCase.$1);
          expect(
            result,
            contains(testCase.$2.substring(0, testCase.$2.length - 1)),
          ); // Remove period for contains check
        }
      });

      test('should capitalize first letter', () {
        final message = ErrorMessages.getErrorMessage(
          'lowercase error message',
        );
        expect(message[0], equals(message[0].toUpperCase()));
      });

      test('should add period if missing', () {
        final message = ErrorMessages.getErrorMessage('error without period');
        expect(message.endsWith('.'), isTrue);
      });

      test('should handle very long technical messages', () {
        final longTechnicalMessage =
            'A' * 250 + ' with stack trace and null pointer exception';
        final message = ErrorMessages.getErrorMessage(longTechnicalMessage);

        expect(
          message,
          equals('Đã xảy ra lỗi. Vui lòng thử lại sau hoặc liên hệ hỗ trợ.'),
        );
      });

      test('should handle technical terms', () {
        final technicalMessages = [
          'null pointer exception occurred',
          'stack trace shows error',
          'assertion failed in code',
          'index out of bounds error',
        ];

        for (final techMessage in technicalMessages) {
          final message = ErrorMessages.getErrorMessage(techMessage);
          expect(
            message,
            equals('Đã xảy ra lỗi. Vui lòng thử lại sau hoặc liên hệ hỗ trợ.'),
          );
        }
      });
    });

    group('network error patterns', () {
      test('should identify timeout errors', () {
        final timeoutErrors = [
          'Connection timeout occurred',
          'Request timeout',
          'Operation timed out',
        ];

        for (final error in timeoutErrors) {
          final message = ErrorMessages.getErrorMessage(error);
          expect(
            message,
            equals('Kết nối bị timeout. Vui lòng kiểm tra mạng và thử lại.'),
          );
        }
      });

      test('should identify DNS errors', () {
        final dnsErrors = [
          'DNS resolution failed',
          'Could not resolve hostname',
          'DNS lookup error',
        ];

        for (final error in dnsErrors) {
          final message = ErrorMessages.getErrorMessage(error);
          expect(
            message,
            equals(
              'Không thể tìm thấy máy chủ. Vui lòng kiểm tra kết nối mạng.',
            ),
          );
        }
      });

      test('should identify SSL errors', () {
        final sslErrors = [
          'SSL handshake failed',
          'Certificate verification error',
          'SSL connection error',
        ];

        for (final error in sslErrors) {
          final message = ErrorMessages.getErrorMessage(error);
          expect(message, equals('Lỗi bảo mật kết nối. Vui lòng thử lại sau.'));
        }
      });
    });

    group('edge cases', () {
      test('should handle empty string errors', () {
        final message = ErrorMessages.getErrorMessage('');
        expect(message, equals('Đã xảy ra lỗi không xác định.'));
      });

      test('should handle whitespace-only errors', () {
        final message = ErrorMessages.getErrorMessage('   ');
        expect(message, isNotEmpty);
      });

      test('should handle errors with only technical prefixes', () {
        final message = ErrorMessages.getErrorMessage('Exception: ');
        expect(message, equals('Đã xảy ra lỗi không xác định.'));
      });
    });
  });
}
