import 'dart:async';
import 'dart:math';

/// Service for handling retry mechanisms with exponential backoff.
///
/// This service provides configurable retry logic for network operations
/// and other potentially failing operations with intelligent backoff
/// strategies.
class RetryService {
  /// Creates a [RetryService] with the provided configuration.
  ///
  /// All parameters are optional with sensible defaults:
  /// - [maxAttempts]: Maximum number of retry attempts (default: 3)
  /// - [baseDelayMs]: Base delay between retries in milliseconds
  ///   (default: 1000)
  /// - [maxDelayMs]: Maximum delay between retries in milliseconds
  ///   (default: 30000)
  /// - [backoffMultiplier]: Multiplier for exponential backoff
  ///   (default: 2.0)
  /// - [useJitter]: Whether to add jitter to prevent thundering herd
  ///   (default: true)
  const RetryService({
    this.maxAttempts = 3,
    this.baseDelayMs = 1000,
    this.maxDelayMs = 30000,
    this.backoffMultiplier = 2.0,
    this.useJitter = true,
  });

  /// Maximum number of retry attempts
  final int maxAttempts;

  /// Base delay between retries in milliseconds
  final int baseDelayMs;

  /// Maximum delay between retries in milliseconds
  final int maxDelayMs;

  /// Multiplier for exponential backoff
  final double backoffMultiplier;

  /// Whether to add jitter to prevent thundering herd
  final bool useJitter;

  /// Executes an operation with retry logic.
  ///
  /// The [operation] function will be called up to [maxAttempts] times
  /// if it throws an exception. Returns the result of the first successful
  /// execution or throws the last exception if all attempts fail.
  Future<T> execute<T>(
    Future<T> Function() operation, {
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }

        // Don't delay after the last attempt
        if (attempt == maxAttempts) {
          rethrow;
        }

        // Call retry callback if provided
        onRetry?.call(attempt, error);

        // Calculate delay with exponential backoff
        final delay = _calculateDelay(attempt);
        await Future<void>.delayed(Duration(milliseconds: delay));
      }
    }

    // This should never be reached, but just in case
    if (lastError != null) {
      if (lastError is Exception) {
        throw lastError;
      }
      if (lastError is Error) {
        throw lastError;
      }
      throw Exception(lastError.toString());
    }
    throw Exception('All retry attempts failed');
  }

  /// Calculates the delay for a given attempt number.
  int _calculateDelay(int attempt) {
    // Calculate exponential backoff delay
    var delay = (baseDelayMs * pow(backoffMultiplier, attempt - 1)).toDouble();

    // Cap at maximum delay
    delay = min(delay, maxDelayMs.toDouble());

    // Add jitter if enabled (±25% random variation)
    if (useJitter) {
      final jitter = delay * 0.25 * (Random().nextDouble() * 2 - 1);
      delay += jitter;
    }

    return delay.round();
  }

  /// Determines if an error should be retried based on common patterns.
  static bool shouldRetryError(dynamic error) {
    // Retry network-related errors
    if (error.toString().toLowerCase().contains('network')) {
      return true;
    }

    // Retry timeout errors
    if (error.toString().toLowerCase().contains('timeout')) {
      return true;
    }

    // Retry connection errors
    if (error.toString().toLowerCase().contains('connection')) {
      return true;
    }

    // Don't retry authentication errors
    if (error.toString().toLowerCase().contains('auth')) {
      return false;
    }

    // Don't retry validation errors
    if (error.toString().toLowerCase().contains('validation')) {
      return false;
    }

    // Default to not retrying unknown errors
    return false;
  }
}

/// Predefined retry configurations for common scenarios
class RetryConfigs {
  /// Private constructor to prevent instantiation
  RetryConfigs._();

  /// Configuration for network operations
  static const network = RetryService(
    maxDelayMs: 10000,
  );

  /// Configuration for authentication operations
  static const auth = RetryService(
    maxAttempts: 2,
    baseDelayMs: 500,
    maxDelayMs: 2000,
    backoffMultiplier: 1.5,
    useJitter: false,
  );

  /// Configuration for database operations
  static const database = RetryService(
    baseDelayMs: 2000,
    maxDelayMs: 15000,
    backoffMultiplier: 2.5,
  );

  /// Configuration for quick operations
  static const quick = RetryService(
    maxAttempts: 2,
    baseDelayMs: 200,
    maxDelayMs: 1000,
    useJitter: false,
  );
}
