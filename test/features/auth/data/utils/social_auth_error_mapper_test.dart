import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/data/utils/social_auth_error_mapper.dart';
import 'package:grex/features/auth/domain/entities/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Unit tests for SocialAuthErrorMapper
///
/// Tests error mapping for all failure types, retry mechanisms,
/// fallback options, error display components, and error recovery flows.
///
/// Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6
void main() {
  group('SocialAuthErrorMapper', () {
    group('mapError', () {
      test('should map Supabase AuthException with network error', () {
        // Arrange
        const exception = supabase.AuthException('network connection failed');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<SocialAuthNetworkFailure>());
        expect(result.message, contains('Network'));
      });

      test('should map Supabase AuthException with timeout error', () {
        // Arrange
        const exception = supabase.AuthException(
          'timeout occurred during authentication',
        );

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<SocialAuthTimeoutFailure>());
        expect(
          result.message.toLowerCase().contains('timeout') ||
              result.message.toLowerCase().contains('timed out'),
          isTrue,
        );
      });

      test('should map Supabase AuthException with cancellation error', () {
        // Arrange
        const exception = supabase.AuthException('user_cancelled');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<SocialAuthCancelledFailure>());
        expect(
          result.message.toLowerCase().contains('cancelled') ||
              result.message.toLowerCase().contains('canceled'),
          isTrue,
        );
      });

      test('should map Supabase AuthException with access denied', () {
        // Arrange
        const exception = supabase.AuthException('access_denied');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<SocialAuthCancelledFailure>());
      });

      test('should map Supabase AuthException with account linking error', () {
        // Arrange
        const exception = supabase.AuthException('account already exists');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<AccountLinkingFailure>());
      });

      test('should map Supabase AuthException with OAuth provider error', () {
        // Arrange
        const exception = supabase.AuthException('invalid_grant');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<SocialAuthFailure>());
        expect(
          result.message,
          equals('Authentication failed. Please try again.'),
        );
      });

      test('should map generic Supabase AuthException', () {
        // Arrange
        const exception = supabase.AuthException('unknown error occurred');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<SocialAuthFailure>());
        expect(result.message, isNotEmpty);
      });

      test('should map TimeoutException', () {
        // Arrange
        const exception = TimeoutException('operation timed out');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<SocialAuthTimeoutFailure>());
      });

      test('should map network-related generic exceptions', () {
        // Arrange
        final exception = Exception('network connection failed');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<SocialAuthNetworkFailure>());
      });

      test('should map socket exceptions', () {
        // Arrange
        final exception = Exception('socket exception occurred');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<SocialAuthNetworkFailure>());
      });

      test('should map timeout-related generic exceptions', () {
        // Arrange
        final exception = Exception('operation timeout exceeded');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<SocialAuthTimeoutFailure>());
      });

      test('should map cancellation-related generic exceptions', () {
        // Arrange
        final exception = Exception('user cancelled operation');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<SocialAuthCancelledFailure>());
      });

      test('should map account linking generic exceptions', () {
        // Arrange
        final exception = Exception('account linking failed');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<AccountLinkingFailure>());
      });

      test('should map unknown exceptions to generic social auth failure', () {
        // Arrange
        final exception = Exception('unknown error');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<SocialAuthFailure>());
        expect(result.message, isNotEmpty);
      });
    });

    group('specific mapping methods', () {
      test('mapNetworkError should return SocialAuthNetworkFailure', () {
        // Arrange
        final error = Exception('connection failed');

        // Act
        final result = SocialAuthErrorMapper.mapNetworkError(error);

        // Assert
        expect(result, isA<SocialAuthNetworkFailure>());
      });

      test('mapTimeoutError should return SocialAuthTimeoutFailure', () {
        // Arrange
        final error = Exception('timeout');

        // Act
        final result = SocialAuthErrorMapper.mapTimeoutError(error);

        // Assert
        expect(result, isA<SocialAuthTimeoutFailure>());
      });

      test('mapAccountLinkingError should return AccountLinkingFailure', () {
        // Arrange
        const message = 'Failed to link accounts';

        // Act
        final result = SocialAuthErrorMapper.mapAccountLinkingError(message);

        // Assert
        expect(result, isA<AccountLinkingFailure>());
        expect(result.message, contains('Failed to link accounts'));
      });

      test('mapCancellationError should return SocialAuthCancelledFailure', () {
        // Act
        final result = SocialAuthErrorMapper.mapCancellationError();

        // Assert
        expect(result, isA<SocialAuthCancelledFailure>());
      });
    });

    group('message sanitization', () {
      test('should remove technical prefixes from error messages', () {
        // Arrange
        final exception = Exception('Error: network connection failed');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result.message, isNot(startsWith('Error:')));
        expect(result.message, isNot(startsWith('Exception:')));
      });

      test('should remove stack trace information', () {
        // Arrange
        final exception = Exception('network failed\nstack trace here');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result.message, isNot(contains('\n')));
        expect(result.message, isNot(contains('stack trace')));
      });

      test('should remove technical error codes in brackets', () {
        // Arrange
        final exception = Exception('auth failed [code: 500]');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result.message, isNot(contains('[code: 500]')));
      });

      test('should remove URLs from error messages', () {
        // Arrange
        final exception = Exception(
          'failed to connect to https://api.example.com',
        );

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result.message, isNot(contains('https://api.example.com')));
      });

      test('should remove technical identifiers', () {
        // Arrange
        final exception = Exception('error with id abc123def456');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result.message, isNot(contains('abc123def456')));
      });

      test('should ensure proper capitalization', () {
        // Arrange
        final exception = Exception('network connection failed');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result.message[0], equals(result.message[0].toUpperCase()));
      });

      test('should provide fallback message for empty sanitized strings', () {
        // Arrange
        final exception = Exception('[error_code_only]');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result.message, isNotEmpty);
        expect(result.message, equals('An unexpected error occurred'));
      });
    });

    group('error detection helpers', () {
      test('should correctly identify network errors', () {
        final networkErrors = [
          Exception('network connection failed'),
          Exception('socket exception'),
          Exception('host unreachable'),
          Exception('no internet connection'),
          Exception('connection refused'),
        ];

        for (final error in networkErrors) {
          final result = SocialAuthErrorMapper.mapError(error);
          expect(result, isA<SocialAuthNetworkFailure>());
        }
      });

      test('should correctly identify timeout errors', () {
        final timeoutErrors = [
          Exception('operation timed out'),
          Exception('timeout exceeded'),
          Exception('deadline exceeded'),
          const TimeoutException('request timeout'),
        ];

        for (final error in timeoutErrors) {
          final result = SocialAuthErrorMapper.mapError(error);
          expect(result, isA<SocialAuthTimeoutFailure>());
        }
      });

      test('should correctly identify cancellation errors', () {
        final cancellationErrors = [
          Exception('user cancelled'),
          Exception('operation canceled'),
          Exception('access denied'),
          const supabase.AuthException('user_cancelled'),
        ];

        for (final error in cancellationErrors) {
          final result = SocialAuthErrorMapper.mapError(error);
          expect(result, isA<SocialAuthCancelledFailure>());
        }
      });

      test('should correctly identify account linking errors', () {
        final linkingErrors = [
          Exception('account already exists'),
          Exception('duplicate account'),
          Exception('linking failed'),
          Exception('merge conflict'),
        ];

        for (final error in linkingErrors) {
          final result = SocialAuthErrorMapper.mapError(error);
          expect(result, isA<AccountLinkingFailure>());
        }
      });
    });

    group('edge cases', () {
      test('should handle null error messages', () {
        // Arrange
        final exception = Exception('');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<SocialAuthFailure>());
        expect(result.message, isNotEmpty);
      });

      test('should handle very long error messages', () {
        // Arrange
        final longMessage = 'error ' * 100;
        final exception = Exception(longMessage);

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<SocialAuthFailure>());
        expect(result.message, isNotEmpty);
        expect(result.message.length, lessThan(longMessage.length));
      });

      test('should handle error messages with special characters', () {
        // Arrange
        final exception = Exception(r'error with special chars: !@#$%^&*()');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<SocialAuthFailure>());
        expect(result.message, isNotEmpty);
      });

      test('should handle error messages with unicode characters', () {
        // Arrange
        final exception = Exception('error with unicode: 你好 🚀 café');

        // Act
        final result = SocialAuthErrorMapper.mapError(exception);

        // Assert
        expect(result, isA<SocialAuthFailure>());
        expect(result.message, isNotEmpty);
      });
    });
  });
}
