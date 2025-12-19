import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Service for logging errors with different severity levels and contexts.
///
/// This service provides structured error logging for debugging and monitoring
/// purposes with appropriate filtering based on build mode.
class ErrorLoggingService {
  static const String _tag = 'Grex';

  /// Logs an error with context information.
  ///
  /// [error] - The error object or message
  /// [stackTrace] - Optional stack trace
  /// [context] - Additional context information
  /// [severity] - Error severity level
  static void logError(
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    if (!kDebugMode && severity == ErrorSeverity.debug) {
      return; // Don't log debug errors in release mode
    }

    final message = _formatErrorMessage(error, context, severity);

    switch (severity) {
      case ErrorSeverity.debug:
        developer.log(
          message,
          name: _tag,
          level: 500, // Debug level
          error: error,
          stackTrace: stackTrace,
        );
      case ErrorSeverity.info:
        developer.log(
          message,
          name: _tag,
          level: 800, // Info level
        );
      case ErrorSeverity.warning:
        developer.log(
          message,
          name: _tag,
          level: 900, // Warning level
          error: error,
        );
      case ErrorSeverity.error:
        developer.log(
          message,
          name: _tag,
          level: 1000, // Error level
          error: error,
          stackTrace: stackTrace,
        );
      case ErrorSeverity.critical:
        developer.log(
          message,
          name: _tag,
          level: 1200, // Severe level
          error: error,
          stackTrace: stackTrace,
        );
        // In production, you might want to send critical errors to a
        // monitoring service
        if (kReleaseMode) {
          _sendToCrashlytics(error, stackTrace, context);
        }
    }
  }

  /// Logs authentication-related errors.
  static void logAuthError(
    dynamic error, {
    StackTrace? stackTrace,
    String? userId,
    String? operation,
  }) {
    logError(
      error,
      stackTrace: stackTrace,
      context: {
        'category': 'authentication',
        'userId': userId,
        'operation': operation,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Logs network-related errors.
  static void logNetworkError(
    dynamic error, {
    StackTrace? stackTrace,
    String? endpoint,
    int? statusCode,
    String? method,
  }) {
    logError(
      error,
      stackTrace: stackTrace,
      context: {
        'category': 'network',
        'endpoint': endpoint,
        'statusCode': statusCode,
        'method': method,
        'timestamp': DateTime.now().toIso8601String(),
      },
      severity: ErrorSeverity.warning,
    );
  }

  /// Logs validation errors.
  static void logValidationError(
    String field,
    String value,
    String reason, {
    Map<String, dynamic>? additionalContext,
  }) {
    logError(
      'Validation failed for field: $field',
      context: {
        'category': 'validation',
        'field': field,
        'value': value.length > 50 ? '${value.substring(0, 50)}...' : value,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalContext,
      },
      severity: ErrorSeverity.warning,
    );
  }

  /// Logs user action errors.
  static void logUserActionError(
    String action,
    dynamic error, {
    StackTrace? stackTrace,
    String? userId,
    Map<String, dynamic>? actionData,
  }) {
    logError(
      error,
      stackTrace: stackTrace,
      context: {
        'category': 'user_action',
        'action': action,
        'userId': userId,
        'actionData': actionData,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Logs performance-related issues.
  static void logPerformanceIssue(
    String operation,
    Duration duration, {
    Map<String, dynamic>? context,
  }) {
    logError(
      'Performance issue detected',
      context: {
        'category': 'performance',
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
        ...?context,
      },
      severity: ErrorSeverity.warning,
    );
  }

  /// Formats error message with context information.
  static String _formatErrorMessage(
    dynamic error,
    Map<String, dynamic>? context,
    ErrorSeverity severity,
  ) {
    final buffer = StringBuffer()
      // Add severity prefix
      ..write('[${severity.name.toUpperCase()}] ');

    // Add category if available
    if (context?['category'] != null) {
      buffer.write('[${context!['category']}] ');
    }

    // Add main error message
    buffer.write(error.toString());

    // Add context information
    if (context != null && context.isNotEmpty) {
      final contextEntries = context.entries
          .where((entry) => entry.key != 'category')
          .map((entry) => '${entry.key}=${entry.value}')
          .join(', ');
      buffer
        ..write(' | Context: ')
        ..write(contextEntries);
    }

    return buffer.toString();
  }

  /// Sends critical errors to crash reporting service (placeholder).
  static void _sendToCrashlytics(
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  ) {
    // In a real app, you would integrate with Firebase Crashlytics or similar
    // For now, we just log it as a critical error
    developer.log(
      'CRITICAL ERROR - Would send to crashlytics',
      name: _tag,
      level: 1200,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs app lifecycle events for debugging.
  static void logAppEvent(String event, {Map<String, dynamic>? data}) {
    logError(
      'App event: $event',
      context: {
        'category': 'app_lifecycle',
        'event': event,
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
      severity: ErrorSeverity.info,
    );
  }
}

/// Error severity levels for logging
enum ErrorSeverity {
  /// Debug level - detailed information for debugging
  debug,

  /// Info level - general informational messages
  info,

  /// Warning level - warning messages that may indicate issues
  warning,

  /// Error level - error messages that need attention
  error,

  /// Critical level - critical errors that require immediate action
  critical,
}
