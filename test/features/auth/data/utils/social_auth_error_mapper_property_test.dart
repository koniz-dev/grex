import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/data/utils/social_auth_error_mapper.dart';
import 'package:grex/features/auth/domain/entities/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Property-Based Test: OAuth Errors Map to User-Friendly Messages
///
/// Validates: Requirements 8.1
///
/// This property test verifies that all OAuth provider errors are correctly
/// mapped to user-friendly, localized messages that don't expose technical
/// details or sensitive information to users.
void main() {
  group('Property 26: OAuth Errors Map to User-Friendly Messages', () {
    test(
      'should map all error types to user-friendly messages with 100 '
      'iterations',
      () {
        // Property: For any OAuth error, the mapped failure should have a
        // user-friendly message
        // that doesn't contain technical details or sensitive information

        for (var i = 0; i < 100; i++) {
          // Generate various types of errors
          final testErrors = _generateTestErrors(i);

          for (final error in testErrors) {
            // Act: Map the error to a domain failure
            final failure = SocialAuthErrorMapper.mapError(error);

            // Assert: Verify the failure is mapped correctly
            expect(failure, isA<AuthFailure>());
            expect(failure.message, isNotEmpty);

            // Verify message is user-friendly (no technical details)
            _verifyUserFriendlyMessage(failure.message);

            // Verify correct failure type based on error
            _verifyCorrectFailureType(error, failure);
          }
        }
      },
    );

    test('should handle Supabase AuthException with 100+ iterations', () {
      // Property: All Supabase AuthExceptions should be mapped to appropriate
      // domain failures

      for (var i = 0; i < 100; i++) {
        final authException = _generateSupabaseAuthException(i);

        // Act
        final failure = SocialAuthErrorMapper.mapError(authException);

        // Assert
        expect(failure, isA<AuthFailure>());
        expect(failure.message, isNotEmpty);

        // Verify message doesn't contain sensitive information
        _verifyNoSensitiveInformation(failure.message);

        // Verify correct mapping based on exception message
        _verifySupabaseExceptionMapping(authException, failure);
      }
    });

    test('should sanitize error messages with 100+ iterations', () {
      // Property: All error messages should be sanitized to remove technical
      // details

      for (var i = 0; i < 100; i++) {
        final rawError = _generateRawError(i);

        // Act
        final failure = SocialAuthErrorMapper.mapError(rawError);

        // Assert
        expect(failure.message, isNotEmpty);

        // Verify sanitization
        _verifySanitizedMessage(failure.message);
      }
    });

    test('should handle network errors consistently with 100+ iterations', () {
      // Property: All network-related errors should map to
      // SocialAuthNetworkFailure

      for (var i = 0; i < 100; i++) {
        final networkError = _generateNetworkError(i);

        // Act
        final failure = SocialAuthErrorMapper.mapError(networkError);

        // Assert
        expect(failure, isA<SocialAuthNetworkFailure>());
        expect(failure.message, contains('Network'));
      }
    });

    test('should handle timeout errors consistently with 100+ iterations', () {
      // Property: All timeout-related errors should map to
      // SocialAuthTimeoutFailure

      for (var i = 0; i < 100; i++) {
        final timeoutError = _generateTimeoutError(i);

        // Act
        final failure = SocialAuthErrorMapper.mapError(timeoutError);

        // Assert
        expect(failure, isA<SocialAuthTimeoutFailure>());
        expect(
          failure.message.contains('timeout') ||
              failure.message.contains('timed out'),
          isTrue,
        );
      }
    });

    test('should handle cancellation errors silently with 100+ iterations', () {
      // Property: All cancellation errors should map to
      // SocialAuthCancelledFailure

      for (var i = 0; i < 100; i++) {
        final cancellationError = _generateCancellationError(i);

        // Act
        final failure = SocialAuthErrorMapper.mapError(cancellationError);

        // Assert
        expect(failure, isA<SocialAuthCancelledFailure>());
        expect(
          failure.message.contains('cancelled') ||
              failure.message.contains('canceled'),
          isTrue,
        );
      }
    });
  });
}

/// Generates various types of test errors for property testing
List<dynamic> _generateTestErrors(int seed) {
  final errors = <dynamic>[];

  // Add different types of errors based on seed
  switch (seed % 10) {
    case 0:
      errors.add(const supabase.AuthException('network error occurred'));
    case 1:
      errors.add(Exception('timeout exceeded'));
    case 2:
      errors.add(const supabase.AuthException('user_cancelled'));
    case 3:
      errors.add(Exception('connection failed'));
    case 4:
      errors.add(const supabase.AuthException('invalid_grant'));
    case 5:
      errors.add(const TimeoutException('operation timed out'));
    case 6:
      errors.add(Exception('account already exists'));
    case 7:
      errors.add(const supabase.AuthException('access_denied'));
    case 8:
      errors.add(Exception('socket exception'));
    case 9:
      errors.add(const supabase.AuthException('unauthorized_client'));
  }

  return errors;
}

/// Generates Supabase AuthException for testing
supabase.AuthException _generateSupabaseAuthException(int seed) {
  final messages = [
    'network connection failed',
    'timeout occurred during authentication',
    'user cancelled the operation',
    'access denied by provider',
    'invalid grant provided',
    'unauthorized client request',
    'account linking failed',
    'provider unavailable',
    'invalid request format',
    'authentication expired',
  ];

  return supabase.AuthException(messages[seed % messages.length]);
}

/// Generates raw errors with technical details for sanitization testing
Exception _generateRawError(int seed) {
  final messages = [
    'network error [code: 500] at https://api.example.com/auth',
    'timeout after 30000ms with trace: stack_trace_here',
    'connection refused to 192.168.1.1:8080',
    'invalid_grant [error_id: abc123def456]',
    'host unreachable https://oauth.provider.com/token',
    'deadline exceeded after 10s\nstack trace follows',
    'user_cancelled [session_id: xyz789]',
    'provider error\ndetailed_error_info_here',
    'SSL handshake failed with certificate details',
    'rate limit exceeded [retry_after: 60]',
  ];

  return Exception(messages[seed % messages.length]);
}

/// Generates network-related errors
Exception _generateNetworkError(int seed) {
  final messages = [
    'network connection failed',
    'socket exception occurred',
    'host unreachable',
    'no internet connection',
    'network unavailable',
    'connection refused',
    'dns resolution failed',
    'ssl handshake failed',
    'network interface down',
    'connection error occurred',
  ];

  return Exception(messages[seed % messages.length]);
}

/// Generates timeout-related errors
Exception _generateTimeoutError(int seed) {
  final messages = [
    'operation timed out',
    'timeout exceeded',
    'deadline exceeded',
    'request timeout',
    'connection timeout',
    'read timeout',
    'write timeout',
    'authentication timeout',
    'callback timeout',
    'response timeout',
  ];

  if (seed.isEven) {
    return TimeoutException(messages[seed % messages.length]);
  } else {
    return Exception(messages[seed % messages.length]);
  }
}

/// Generates cancellation-related errors
Exception _generateCancellationError(int seed) {
  final messages = [
    'user cancelled',
    'operation cancelled',
    'authentication cancelled',
    'user_cancelled',
    'access_denied',
    'user denied access',
    'cancelled by user',
    'user cancelled operation',
    'authentication canceled',
    'access denied by user',
  ];

  if (seed.isEven) {
    return supabase.AuthException(messages[seed % messages.length]);
  } else {
    return Exception(messages[seed % messages.length]);
  }
}

/// Verifies that a message is user-friendly
void _verifyUserFriendlyMessage(String message) {
  // Should not contain technical prefixes
  expect(message, isNot(startsWith('Error:')));
  expect(message, isNot(startsWith('Exception:')));
  expect(message, isNot(startsWith('AuthException:')));

  // Should not contain stack traces
  expect(message, isNot(contains('\n')));
  expect(message, isNot(contains('stack trace')));
  expect(message, isNot(contains('at line')));

  // Should not contain URLs
  expect(message, isNot(contains('http://')));
  expect(message, isNot(contains('https://')));

  // Should not contain technical error codes in brackets
  expect(message, isNot(contains(RegExp(r'\[.*?\]'))));

  // Should be properly capitalized
  if (message.isNotEmpty) {
    expect(message[0], equals(message[0].toUpperCase()));
  }
}

/// Verifies correct failure type mapping
void _verifyCorrectFailureType(dynamic error, AuthFailure failure) {
  final errorString = error.toString().toLowerCase();

  if (errorString.contains('network') ||
      errorString.contains('connection') ||
      errorString.contains('socket')) {
    expect(failure, isA<SocialAuthNetworkFailure>());
  } else if (errorString.contains('timeout') ||
      errorString.contains('timed out')) {
    expect(failure, isA<SocialAuthTimeoutFailure>());
  } else if (errorString.contains('cancelled') ||
      errorString.contains('canceled') ||
      errorString.contains('access_denied')) {
    expect(failure, isA<SocialAuthCancelledFailure>());
  } else if (errorString.contains('link') ||
      errorString.contains('already exists')) {
    expect(failure, isA<AccountLinkingFailure>());
  } else {
    expect(failure, isA<SocialAuthFailure>());
  }
}

/// Verifies no sensitive information is exposed
void _verifyNoSensitiveInformation(String message) {
  // Should not contain session IDs, tokens, or other sensitive data
  expect(message, isNot(contains(RegExp('[a-f0-9]{8,}'))));
  expect(message, isNot(contains('token')));
  expect(message, isNot(contains('session')));
  expect(message, isNot(contains('key')));
  expect(message, isNot(contains('secret')));
  expect(message, isNot(contains('password')));

  // Should not contain IP addresses
  expect(message, isNot(contains(RegExp(r'\d+\.\d+\.\d+\.\d+'))));

  // Should not contain internal paths or technical details
  expect(message, isNot(contains('/api/')));
  expect(message, isNot(contains('/auth/')));
  expect(message, isNot(contains('localhost')));
}

/// Verifies Supabase exception mapping
void _verifySupabaseExceptionMapping(
  supabase.AuthException exception,
  AuthFailure failure,
) {
  final message = exception.message.toLowerCase();

  if (message.contains('network') || message.contains('connection')) {
    expect(failure, isA<SocialAuthNetworkFailure>());
  } else if (message.contains('timeout') || message.contains('timed out')) {
    expect(failure, isA<SocialAuthTimeoutFailure>());
  } else if (message.contains('cancelled') ||
      message.contains('access_denied')) {
    expect(failure, isA<SocialAuthCancelledFailure>());
  } else if (message.contains('link') || message.contains('already exists')) {
    expect(failure, isA<AccountLinkingFailure>());
  } else {
    expect(failure, isA<SocialAuthFailure>());
  }
}

/// Verifies message sanitization
void _verifySanitizedMessage(String message) {
  // Should not contain technical prefixes
  expect(message, isNot(contains('Exception:')));
  expect(message, isNot(contains('Error:')));
  expect(message, isNot(contains('AuthException:')));

  // Should not contain stack traces
  expect(message, isNot(contains('\n')));

  // Should not contain error codes in brackets
  expect(message, isNot(contains(RegExp(r'\[.*?\]'))));

  // Should not contain URLs
  expect(message, isNot(contains('http')));

  // Should not contain technical identifiers
  expect(message, isNot(contains(RegExp(r'\b[a-f0-9]{8,}\b'))));

  // Should not be empty after sanitization
  expect(message, isNotEmpty);
}
