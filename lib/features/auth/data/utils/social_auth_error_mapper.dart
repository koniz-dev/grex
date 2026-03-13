import 'package:grex/features/auth/domain/entities/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Utility class for mapping OAuth provider errors to user-friendly messages
class SocialAuthErrorMapper {
  /// Maps OAuth provider errors to user-friendly messages
  ///
  /// This method takes various types of exceptions and maps them to
  /// appropriate domain failure types with localized, user-friendly messages.
  ///
  /// Requirements: 8.1, 8.2, 8.3, 8.5
  static AuthFailure mapError(dynamic error) {
    // Handle Supabase AuthException
    if (error is supabase.AuthException) {
      return _mapSupabaseAuthException(error);
    }

    // Handle timeout exceptions (check first)
    if (error is TimeoutException || _isTimeoutError(error)) {
      return const SocialAuthTimeoutFailure();
    }

    // Handle cancellation (check before network)
    if (_isCancellationError(error)) {
      return const SocialAuthCancelledFailure();
    }

    // Handle network-related exceptions
    if (_isNetworkError(error)) {
      return const SocialAuthNetworkFailure();
    }

    // Handle account linking specific errors
    if (_isAccountLinkingError(error)) {
      return AccountLinkingFailure(_sanitizeErrorMessage(error.toString()));
    }

    // Generic social auth failure for unknown errors
    return SocialAuthFailure(_sanitizeErrorMessage(error.toString()));
  }

  /// Checks if the error is timeout-related
  static bool _isTimeoutError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    return errorString.contains('timeout') ||
        errorString.contains('timed out') ||
        errorString.contains('deadline exceeded') ||
        errorString.contains('request timeout');
  }

  /// Maps Supabase AuthException to appropriate domain failures
  static AuthFailure _mapSupabaseAuthException(supabase.AuthException e) {
    final message = e.message.toLowerCase();

    // Timeout-related errors (check first to avoid conflicts)
    if (message.contains('timeout') ||
        message.contains('timed out') ||
        message.contains('deadline exceeded')) {
      return const SocialAuthTimeoutFailure();
    }

    // User cancellation (check before network to avoid conflicts)
    if (message.contains('cancelled') ||
        message.contains('canceled') ||
        message.contains('user_cancelled') ||
        message.contains('access_denied')) {
      return const SocialAuthCancelledFailure();
    }

    // Network-related errors
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('unreachable')) {
      return const SocialAuthNetworkFailure();
    }

    // Account linking errors
    if (message.contains('link') ||
        message.contains('already exists') ||
        message.contains('duplicate')) {
      return AccountLinkingFailure(_sanitizeErrorMessage(e.message));
    }

    // OAuth provider specific errors
    if (message.contains('invalid_grant') ||
        message.contains('invalid_request') ||
        message.contains('unauthorized_client')) {
      return const SocialAuthFailure(
        'Authentication failed. Please try again.',
      );
    }

    // Generic social auth failure
    return SocialAuthFailure(_sanitizeErrorMessage(e.message));
  }

  /// Checks if the error is network-related
  static bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Exclude timeout and cancellation errors from network errors
    if (_isTimeoutError(error) || _isCancellationError(error)) {
      return false;
    }

    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('host') ||
        errorString.contains('unreachable') ||
        errorString.contains('no internet') ||
        errorString.contains('offline') ||
        errorString.contains('dns') ||
        errorString.contains('ssl');
  }

  /// Checks if the error indicates user cancellation
  static bool _isCancellationError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    return errorString.contains('cancelled') ||
        errorString.contains('canceled') ||
        errorString.contains('user_cancelled') ||
        errorString.contains('access_denied') ||
        errorString.contains('user denied') ||
        errorString.contains('access denied');
  }

  /// Checks if the error is related to account linking
  static bool _isAccountLinkingError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    return errorString.contains('link') ||
        errorString.contains('already exists') ||
        errorString.contains('duplicate') ||
        errorString.contains('merge') ||
        errorString.contains('conflict');
  }

  /// Sanitizes error messages to be user-friendly
  ///
  /// Removes technical details and sensitive information while
  /// preserving the essential error information for the user.
  static String _sanitizeErrorMessage(String message) {
    // Remove common technical prefixes (case insensitive)
    var sanitized = message
        .replaceAll(
          RegExp(
            r'^(Error:|Exception:|AuthException:|NetworkException:|TimeoutException:)\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'^\w+Exception:\s*', caseSensitive: false), '');

    // Remove stack trace information
    if (sanitized.contains('\n')) {
      sanitized = sanitized.split('\n').first;
    }

    // Remove technical error codes in brackets
    sanitized = sanitized.replaceAll(RegExp(r'\[.*?\]'), '');

    // Remove URLs and technical identifiers
    sanitized = sanitized.replaceAll(RegExp(r'https?://[^\s]+'), '');
    sanitized = sanitized.replaceAll(RegExp(r'\b[a-f0-9]{8,}\b'), '');

    // Remove IP addresses and ports
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d+\.\d+\.\d+\.\d+(:\d+)?\b'),
      '',
    );

    // Remove technical details like "after 30000ms", "with trace:", etc.
    sanitized = sanitized.replaceAll(RegExp(r'\s+after\s+\d+\w*'), '');
    sanitized = sanitized.replaceAll(RegExp(r'\s+with\s+\w+:.*'), '');
    sanitized = sanitized.replaceAll(RegExp(r'\s+to\s+\d+\.\d+\.\d+\.\d+'), '');

    // Trim and ensure proper capitalization
    sanitized = sanitized.trim();
    if (sanitized.isNotEmpty) {
      sanitized = sanitized[0].toUpperCase() + sanitized.substring(1);
    }

    // Fallback to generic message if sanitization results in empty string
    if (sanitized.isEmpty) {
      sanitized = 'An unexpected error occurred';
    }

    return sanitized;
  }

  /// Maps network errors to connection error messages
  ///
  /// Requirements: 8.2
  static AuthFailure mapNetworkError(dynamic error) {
    return const SocialAuthNetworkFailure();
  }

  /// Maps timeout errors to timeout messages
  ///
  /// Requirements: 8.3
  static AuthFailure mapTimeoutError(dynamic error) {
    return const SocialAuthTimeoutFailure();
  }

  /// Maps account linking errors to linking failure messages
  ///
  /// Requirements: 8.1
  static AuthFailure mapAccountLinkingError(String message) {
    return AccountLinkingFailure(_sanitizeErrorMessage(message));
  }

  /// Handles cancellation silently (no error message)
  ///
  /// Requirements: 8.5
  static AuthFailure mapCancellationError() {
    return const SocialAuthCancelledFailure();
  }
}

/// Custom timeout exception for OAuth operations
class TimeoutException implements Exception {
  /// Creates a [TimeoutException] with an optional error message.
  ///
  /// The [message] parameter provides additional context about the timeout.
  const TimeoutException([this.message]);

  /// Optional error message describing the timeout details.
  ///
  /// This message provides context about what operation timed out
  /// and can be used for debugging or user feedback.
  final String? message;

  @override
  String toString() => message ?? 'Operation timed out';
}
