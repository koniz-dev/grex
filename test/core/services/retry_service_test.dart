import 'package:flutter_test/flutter_test.dart';
import 'package:grex/core/services/retry_service.dart';

/// Unit tests for RetryService
///
/// Tests retry mechanisms, exponential backoff, error filtering,
/// and different retry configurations.
///
/// Requirements: 1.3, 2.2, 2.4, 3.5, 4.4, 5.4
void main() {
  group('RetryService', () {
    test('should execute operation successfully on first attempt', () async {
      // Arrange
      const retryService = RetryService();
      var callCount = 0;

      // Act
      final result = await retryService.execute(() async {
        callCount++;
        return 'success';
      });

      // Assert
      expect(result, equals('success'));
      expect(callCount, equals(1));
    });

    test('should retry operation on failure and succeed', () async {
      // Arrange
      const retryService = RetryService(
        baseDelayMs: 10, // Short delay for testing
      );
      var callCount = 0;

      // Act
      final result = await retryService.execute(() async {
        callCount++;
        if (callCount < 3) {
          throw Exception('Temporary failure');
        }
        return 'success';
      });

      // Assert
      expect(result, equals('success'));
      expect(callCount, equals(3));
    });

    test('should fail after max attempts', () async {
      // Arrange
      const retryService = RetryService(
        maxAttempts: 2,
        baseDelayMs: 10,
      );
      var callCount = 0;

      // Act & Assert
      expect(
        () => retryService.execute(() async {
          callCount++;
          throw Exception('Persistent failure');
        }),
        throwsA(isA<Exception>()),
      );

      expect(callCount, equals(2));
    });

    test('should respect shouldRetry callback', () async {
      // Arrange
      const retryService = RetryService();
      var callCount = 0;

      // Act & Assert
      expect(
        () => retryService.execute(
          () async {
            callCount++;
            throw Exception('auth error');
          },
          shouldRetry: (error) => !error.toString().contains('auth'),
        ),
        throwsA(isA<Exception>()),
      );

      expect(callCount, equals(1)); // Should not retry auth errors
    });

    test('should call onRetry callback', () async {
      // Arrange
      const retryService = RetryService(
        baseDelayMs: 10,
      );
      var callCount = 0;
      final retryAttempts = <int>[];
      final retryErrors = <dynamic>[];

      // Act
      try {
        await retryService.execute(
          () async {
            callCount++;
            throw Exception('Failure $callCount');
          },
          onRetry: (attempt, error) {
            retryAttempts.add(attempt);
            retryErrors.add(error);
          },
        );
      } on Exception {
        // Expected to fail
      }

      // Assert
      expect(retryAttempts, equals([1, 2])); // Called for first 2 attempts
      expect(retryErrors.length, equals(2));
      expect(callCount, equals(3));
    });

    test('should calculate exponential backoff correctly', () async {
      // Arrange
      const retryService = RetryService(
        maxAttempts: 4,
        baseDelayMs: 100,
        useJitter: false, // Disable jitter for predictable testing
      );

      final delays = <int>[];
      var callCount = 0;

      // Act
      try {
        await retryService.execute(
          () async {
            callCount++;
            final start = DateTime.now();

            if (callCount > 1) {
              // Record the delay (approximate)
              delays.add(start.millisecondsSinceEpoch);
            }

            throw Exception('Failure');
          },
        );
      } on Exception {
        // Expected to fail
      }

      // Assert
      expect(callCount, equals(4));
      expect(delays.length, equals(3)); // 3 retry delays

      // Check that delays are increasing (exponential backoff)
      if (delays.length >= 2) {
        final delay1 = delays[1] - delays[0];
        final delay2 = delays[2] - delays[1];
        expect(delay2, greaterThan(delay1));
      }
    });

    test('should cap delay at maximum', () async {
      // Arrange
      const retryService = RetryService(
        maxDelayMs: 1500,
        backoffMultiplier: 10, // Large multiplier to test capping
        useJitter: false,
      );

      // This test just ensures the service doesn't hang due to excessive delays
      var callCount = 0;
      final start = DateTime.now();

      // Act
      try {
        await retryService.execute(() async {
          callCount++;
          throw Exception('Failure');
        });
      } on Exception {
        // Expected to fail
      }

      final elapsed = DateTime.now().difference(start);

      // Assert
      expect(callCount, equals(3));
      // Should complete in reasonable time even with large multiplier
      expect(elapsed.inMilliseconds, lessThan(5000));
    });

    group('shouldRetryError', () {
      test('should retry network errors', () {
        expect(
          RetryService.shouldRetryError(Exception('Network error')),
          isTrue,
        );
        expect(
          RetryService.shouldRetryError(Exception('network timeout')),
          isTrue,
        );
        expect(
          RetryService.shouldRetryError(
            Exception('Internet connection failed'),
          ),
          isTrue,
        );
      });

      test('should retry timeout errors', () {
        expect(
          RetryService.shouldRetryError(Exception('Request timeout')),
          isTrue,
        );
        expect(
          RetryService.shouldRetryError(Exception('Connection timeout')),
          isTrue,
        );
      });

      test('should retry connection errors', () {
        expect(
          RetryService.shouldRetryError(Exception('Connection refused')),
          isTrue,
        );
        expect(
          RetryService.shouldRetryError(Exception('connection failed')),
          isTrue,
        );
      });

      test('should not retry auth errors', () {
        expect(
          RetryService.shouldRetryError(Exception('Authentication failed')),
          isFalse,
        );
        expect(RetryService.shouldRetryError(Exception('auth error')), isFalse);
      });

      test('should not retry validation errors', () {
        expect(
          RetryService.shouldRetryError(Exception('Validation failed')),
          isFalse,
        );
        expect(
          RetryService.shouldRetryError(Exception('validation error')),
          isFalse,
        );
      });

      test('should not retry unknown errors by default', () {
        expect(
          RetryService.shouldRetryError(Exception('Unknown error')),
          isFalse,
        );
        expect(
          RetryService.shouldRetryError(Exception('Some random error')),
          isFalse,
        );
      });
    });

    group('RetryConfigs', () {
      test('should have predefined network config', () {
        expect(RetryConfigs.network.maxAttempts, equals(3));
        expect(RetryConfigs.network.baseDelayMs, equals(1000));
        expect(RetryConfigs.network.useJitter, isTrue);
      });

      test('should have predefined auth config', () {
        expect(RetryConfigs.auth.maxAttempts, equals(2));
        expect(RetryConfigs.auth.baseDelayMs, equals(500));
        expect(RetryConfigs.auth.useJitter, isFalse);
      });

      test('should have predefined database config', () {
        expect(RetryConfigs.database.maxAttempts, equals(3));
        expect(RetryConfigs.database.baseDelayMs, equals(2000));
        expect(RetryConfigs.database.useJitter, isTrue);
      });

      test('should have predefined quick config', () {
        expect(RetryConfigs.quick.maxAttempts, equals(2));
        expect(RetryConfigs.quick.baseDelayMs, equals(200));
        expect(RetryConfigs.quick.useJitter, isFalse);
      });
    });

    test('should handle async operations correctly', () async {
      // Arrange
      const retryService = RetryService(
        maxAttempts: 2,
        baseDelayMs: 10,
      );
      var callCount = 0;

      // Act
      final result = await retryService.execute(() async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        if (callCount == 1) {
          throw Exception('First attempt fails');
        }
        return 'async success';
      });

      // Assert
      expect(result, equals('async success'));
      expect(callCount, equals(2));
    });

    test('should handle different return types', () async {
      // Arrange
      const retryService = RetryService(maxAttempts: 1);

      // Test int return type
      final intResult = await retryService.execute(() async => 42);
      expect(intResult, equals(42));

      // Test bool return type
      final boolResult = await retryService.execute(() async => true);
      expect(boolResult, isTrue);

      // Test list return type
      final listResult = await retryService.execute(() async => [1, 2, 3]);
      expect(listResult, equals([1, 2, 3]));
    });
  });
}
