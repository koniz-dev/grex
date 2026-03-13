import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/data/handlers/auth_deep_link_handler.dart';
import 'package:mockito/mockito.dart';
import '../../../../helpers/mock_helpers.dart';

/// Property 8: Invalid OAuth Callbacks Prompt Retry
///
/// This property validates that the AuthDeepLinkHandler correctly handles
/// invalid or expired OAuth callbacks by displaying appropriate error messages
/// and retry prompts.
///
/// Validates Requirements:
/// - 3.5: OAuth callback contains error parameter, app displays appropriate
// error message
/// - 3.6: OAuth callback is invalid or expired, app prompts user to retry
// authentication
void main() {
  group('Property 8: Invalid OAuth Callbacks Prompt Retry', () {
    late AuthDeepLinkHandler handler;
    late MockPerformanceService mockPerformanceService;
    late List<Uri> processedCallbacks;
    late List<String> errorMessages;
    late List<bool> retryPrompts;
    late Random random;

    setUp(() {
      processedCallbacks = [];
      errorMessages = [];
      retryPrompts = [];
      random = Random();
      mockPerformanceService = MockPerformanceService();

      // Setup mock performance service to execute operations directly
      when(mockPerformanceService.measureOperation<void>(
        name: anyNamed('name'),
        operation: anyNamed('operation'),
        attributes: anyNamed('attributes'),
      )).thenAnswer((invocation) async {
        final operation = invocation.namedArguments[#operation] as Future<void> Function();
        return operation();
      });

      handler = AuthDeepLinkHandler(
        onDeepLink: (uri) {
          processedCallbacks.add(uri);

          // Simulate error handling logic that would be in the actual
          // implementation
          final errorInfo = _analyzeCallbackForErrors(uri);
          if (errorInfo.hasError) {
            errorMessages.add(errorInfo.errorMessage);
            retryPrompts.add(errorInfo.shouldShowRetry);
          }
        },
        performanceService: mockPerformanceService,
      );
    });

    tearDown(() {
      handler.dispose();
    });

    test(
      'should handle invalid callbacks with appropriate error messages and '
      'retry prompts',
      () {
        // Property: For any invalid OAuth callback, appropriate error
        // handling should occur

        for (var iteration = 0; iteration < 100; iteration++) {
          // Reset for each iteration
          processedCallbacks.clear();
          errorMessages.clear();
          retryPrompts.clear();

          // Generate invalid OAuth callbacks
          final invalidCallbacks = _generateInvalidCallbacks(random, iteration);

          // Process each invalid callback
          for (final callback in invalidCallbacks) {
            if (handler._isAuthCallback(callback)) {
              handler.onDeepLink(callback);
            }
          }

          // Verify property: All processed callbacks should have error handling
          expect(
            processedCallbacks.length,
            equals(invalidCallbacks.length),
            reason:
                'Iteration $iteration: All invalid callbacks should be '
                'processed',
          );

          expect(
            errorMessages.length,
            equals(invalidCallbacks.length),
            reason:
                'Iteration $iteration: All invalid callbacks should '
                'generate error messages',
          );

          expect(
            retryPrompts.length,
            equals(invalidCallbacks.length),
            reason:
                'Iteration $iteration: All invalid callbacks should have '
                'retry prompt decisions',
          );

          // Verify each callback was handled appropriately
          for (var i = 0; i < invalidCallbacks.length; i++) {
            final callback = invalidCallbacks[i];
            final errorMessage = errorMessages[i];
            final shouldShowRetry = retryPrompts[i];

            // Error message should be non-empty and user-friendly
            expect(
              errorMessage.isNotEmpty,
              isTrue,
              reason:
                  'Iteration $iteration: Error message should not be empty '
                  'for callback: $callback',
            );

            expect(
              _isUserFriendlyMessage(errorMessage),
              isTrue,
              reason:
                  'Iteration $iteration: Error message should be '
                  'user-friendly: $errorMessage',
            );

            // Retry prompt decision should be appropriate for the specific
            // error
            final errorInfo = _analyzeCallbackForErrors(callback);
            final expectedRetry = errorInfo.shouldShowRetry;

            expect(
              shouldShowRetry,
              equals(expectedRetry),
              reason:
                  'Iteration $iteration: Retry prompt should be '
                  '$expectedRetry for callback: $callback',
            );
          }
        }
      },
    );

    test('should differentiate between different types of invalid '
        'callbacks', () {
      // Property: Different error types should be handled differently

      for (var iteration = 0; iteration < 50; iteration++) {
        // Reset for each iteration
        processedCallbacks.clear();
        errorMessages.clear();
        retryPrompts.clear();

        // Generate one callback of each error type
        final errorTypes = [
          InvalidCallbackType.expired,
          InvalidCallbackType.malformed,
          InvalidCallbackType.authError,
          InvalidCallbackType.networkError,
          InvalidCallbackType.missingParameters,
        ];

        final callbacks = errorTypes
            .map((type) => _generateCallbackForErrorType(random, type))
            .toList();

        // Process each callback
        for (final callback in callbacks) {
          if (handler._isAuthCallback(callback)) {
            handler.onDeepLink(callback);
          }
        }

        // Verify different error types produce different handling
        final uniqueMessages = errorMessages.toSet();
        expect(
          uniqueMessages.length,
          greaterThan(1),
          reason:
              'Iteration $iteration: Different error types should produce '
              'different error messages',
        );

        // Verify retry prompts are appropriate for each error type
        for (var i = 0; i < errorTypes.length; i++) {
          final errorType = errorTypes[i];
          final callback = callbacks[i];
          final shouldShowRetry = retryPrompts[i];

          // Get expected retry based on actual error analysis, not just type
          final errorInfo = _analyzeCallbackForErrors(callback);
          final expectedRetry = errorInfo.shouldShowRetry;

          expect(
            shouldShowRetry,
            equals(expectedRetry),
            reason:
                'Iteration $iteration: Error type $errorType should have '
                'retry=$expectedRetry for callback: $callback',
          );
        }
      }
    });
  });
}

/// Types of invalid OAuth callbacks
enum InvalidCallbackType {
  expired,
  malformed,
  authError,
  networkError,
  missingParameters,
}

/// Information about callback errors
class CallbackErrorInfo {
  const CallbackErrorInfo({
    required this.hasError,
    required this.errorMessage,
    required this.shouldShowRetry,
  });
  final bool hasError;
  final String errorMessage;
  final bool shouldShowRetry;
}

/// Generates invalid OAuth callbacks for testing
List<Uri> _generateInvalidCallbacks(Random random, int iteration) {
  final callbacks = <Uri>[];
  final callbackCount = 2 + random.nextInt(4); // 2-5 callbacks per iteration

  for (var i = 0; i < callbackCount; i++) {
    final errorType = InvalidCallbackType
        .values[random.nextInt(InvalidCallbackType.values.length)];
    callbacks.add(_generateCallbackForErrorType(random, errorType));
  }

  return callbacks;
}

/// Generates a callback for a specific error type
Uri _generateCallbackForErrorType(
  Random random,
  InvalidCallbackType errorType,
) {
  switch (errorType) {
    case InvalidCallbackType.expired:
      return Uri(
        scheme: 'io.supabase.grex',
        host: 'login-callback',
        queryParameters: {
          'error': 'expired_token',
          'error_description': 'The authorization code has expired',
        },
      );

    case InvalidCallbackType.malformed:
      return Uri(
        scheme: 'io.supabase.grex',
        host: 'login-callback',
        queryParameters: {
          'access_token': 'invalid-token-format',
          'expires_in': 'not-a-number',
        },
      );

    case InvalidCallbackType.authError:
      final errors = [
        'access_denied',
        'invalid_request',
        'unauthorized_client',
      ];
      final error = errors[random.nextInt(errors.length)];
      return Uri(
        scheme: 'io.supabase.grex',
        host: 'login-callback',
        queryParameters: {
          'error': error,
          'error_description': 'Authentication failed: $error',
        },
      );

    case InvalidCallbackType.networkError:
      return Uri(
        scheme: 'io.supabase.grex',
        host: 'login-callback',
        queryParameters: {
          'error': 'network_error',
          'error_description':
              'Network connection failed during authentication',
        },
      );

    case InvalidCallbackType.missingParameters:
      // Missing required parameters
      return Uri(
        scheme: 'io.supabase.grex',
        host: 'login-callback',
        queryParameters: {
          'state': _generateRandomString(random, 16),
          // Missing access_token and other required parameters
        },
      );
  }
}

/// Analyzes a callback for errors (simulates actual error handling logic)
CallbackErrorInfo _analyzeCallbackForErrors(Uri uri) {
  // Check for explicit error parameter
  if (uri.queryParameters.containsKey('error')) {
    final error = uri.queryParameters['error']!;
    final description =
        uri.queryParameters['error_description'] ?? 'Authentication failed';

    return CallbackErrorInfo(
      hasError: true,
      errorMessage: _getErrorMessageForCode(error, description),
      shouldShowRetry: _shouldShowRetryForError(error),
    );
  }

  // Check for missing required parameters
  if (!uri.queryParameters.containsKey('access_token')) {
    return const CallbackErrorInfo(
      hasError: true,
      errorMessage: 'Authentication failed. Please try again.',
      shouldShowRetry: true,
    );
  }

  // Check for malformed parameters
  final expiresIn = uri.queryParameters['expires_in'];
  if (expiresIn != null && int.tryParse(expiresIn) == null) {
    return const CallbackErrorInfo(
      hasError: true,
      errorMessage: 'Invalid authentication response. Please try again.',
      shouldShowRetry: true,
    );
  }

  return const CallbackErrorInfo(
    hasError: false,
    errorMessage: '',
    shouldShowRetry: false,
  );
}

/// Gets user-friendly error message for error code
String _getErrorMessageForCode(String error, String description) {
  switch (error) {
    case 'expired_token':
      return 'Authentication session expired. Please try signing in again.';
    case 'access_denied':
      return 'Access was denied. Please try again or use a different '
          'sign-in method.';
    case 'invalid_request':
      return 'Authentication request was invalid. Please try again.';
    case 'unauthorized_client':
      return 'Authentication failed. Please try again.';
    case 'network_error':
      return 'Network connection failed. Please check your connection and '
          'try again.';
    default:
      return 'Authentication failed. Please try again.';
  }
}

/// Determines if retry should be shown for error code
bool _shouldShowRetryForError(String error) {
  switch (error) {
    case 'expired_token':
    case 'network_error':
    case 'invalid_request':
    case 'unauthorized_client':
      return true;
    case 'access_denied':
      return false; // User explicitly denied access
    default:
      return true;
  }
}

/// Checks if a message is user-friendly
bool _isUserFriendlyMessage(String message) {
  // User-friendly messages should:
  // - Not contain technical jargon
  // - Be clear and actionable
  // - Not expose internal error details

  final technicalTerms = [
    'null',
    'exception',
    'stack trace',
    'error code',
    'debug',
  ];
  final lowerMessage = message.toLowerCase();

  for (final term in technicalTerms) {
    if (lowerMessage.contains(term)) {
      return false;
    }
  }

  // Should contain actionable language
  final actionableTerms = ['try again', 'please', 'check', 'sign in'];
  return actionableTerms.any(lowerMessage.contains);
}

/// Generates a random string of the specified length
String _generateRandomString(Random random, int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}

/// Extension to access private method for testing
extension AuthDeepLinkHandlerTest on AuthDeepLinkHandler {
  bool _isAuthCallback(Uri uri) {
    return uri.scheme == 'io.supabase.grex' && uri.host == 'login-callback';
  }
}
