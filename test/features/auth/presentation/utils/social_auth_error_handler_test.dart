import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/failures.dart';
import 'package:grex/features/auth/presentation/utils/social_auth_error_handler.dart';
import 'package:grex/l10n/app_localizations.dart';

/// Unit tests for SocialAuthErrorHandler
///
/// Tests error display components, retry mechanisms, fallback options,
/// and error recovery flows for social authentication.
///
/// Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6
void main() {
  group('SocialAuthErrorHandler', () {
    late Widget testApp;
    late BuildContext testContext;

    setUp(() {
      testApp = MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            testContext = context;
            return const Scaffold(body: Text('Test'));
          },
        ),
      );
    });

    group('getErrorMessage', () {
      testWidgets('should return empty string for SocialAuthCancelledFailure', (
        tester,
      ) async {
        await tester.pumpWidget(testApp);

        // Arrange
        const failure = SocialAuthCancelledFailure();

        // Act
        final message = SocialAuthErrorHandler.getErrorMessage(
          testContext,
          failure,
        );

        // Assert
        expect(message, isEmpty);
      });

      testWidgets(
        'should return network error message for SocialAuthNetworkFailure',
        (tester) async {
          await tester.pumpWidget(testApp);

          // Arrange
          const failure = SocialAuthNetworkFailure();

          // Act
          final message = SocialAuthErrorHandler.getErrorMessage(
            testContext,
            failure,
          );

          // Assert
          expect(message, isNotEmpty);
          expect(message.toLowerCase().contains('network'), isTrue);
        },
      );

      testWidgets(
        'should return timeout error message for SocialAuthTimeoutFailure',
        (tester) async {
          await tester.pumpWidget(testApp);

          // Arrange
          const failure = SocialAuthTimeoutFailure();

          // Act
          final message = SocialAuthErrorHandler.getErrorMessage(
            testContext,
            failure,
          );

          // Assert
          expect(message, isNotEmpty);
          expect(
            message.toLowerCase().contains('timeout') ||
                message.toLowerCase().contains('timed out'),
            isTrue,
          );
        },
      );

      testWidgets(
        'should return linking error message for AccountLinkingFailure',
        (tester) async {
          await tester.pumpWidget(testApp);

          // Arrange
          const failure = AccountLinkingFailure('Linking failed');

          // Act
          final message = SocialAuthErrorHandler.getErrorMessage(
            testContext,
            failure,
          );

          // Assert
          expect(message, isNotEmpty);
          expect(message.toLowerCase().contains('link'), isTrue);
        },
      );

      testWidgets('should return generic error message for SocialAuthFailure', (
        tester,
      ) async {
        await tester.pumpWidget(testApp);

        // Arrange
        const failure = SocialAuthFailure('Generic error');

        // Act
        final message = SocialAuthErrorHandler.getErrorMessage(
          testContext,
          failure,
        );

        // Assert
        expect(message, isNotEmpty);
        expect(
          message.toLowerCase().contains('authentication') ||
              message.toLowerCase().contains('failed'),
          isTrue,
        );
      });

      testWidgets('should return network error message for NetworkFailure', (
        tester,
      ) async {
        await tester.pumpWidget(testApp);

        // Arrange
        const failure = NetworkFailure();

        // Act
        final message = SocialAuthErrorHandler.getErrorMessage(
          testContext,
          failure,
        );

        // Assert
        expect(message, isNotEmpty);
        expect(message.toLowerCase().contains('network'), isTrue);
      });

      testWidgets(
        'should return generic error message for unknown failure types',
        (tester) async {
          await tester.pumpWidget(testApp);

          // Arrange
          const failure = GenericAuthFailure('Unknown error');

          // Act
          final message = SocialAuthErrorHandler.getErrorMessage(
            testContext,
            failure,
          );

          // Assert
          expect(message, isNotEmpty);
          expect(
            message.toLowerCase().contains('authentication') ||
                message.toLowerCase().contains('failed'),
            isTrue,
          );
        },
      );
    });

    group('shouldShowRetry', () {
      test('should return true for network failures', () {
        // Arrange
        const failure = SocialAuthNetworkFailure();

        // Act
        final shouldRetry = SocialAuthErrorHandler.shouldShowRetry(failure);

        // Assert
        expect(shouldRetry, isTrue);
      });

      test('should return true for timeout failures', () {
        // Arrange
        const failure = SocialAuthTimeoutFailure();

        // Act
        final shouldRetry = SocialAuthErrorHandler.shouldShowRetry(failure);

        // Assert
        expect(shouldRetry, isTrue);
      });

      test('should return true for generic network failures', () {
        // Arrange
        const failure = NetworkFailure();

        // Act
        final shouldRetry = SocialAuthErrorHandler.shouldShowRetry(failure);

        // Assert
        expect(shouldRetry, isTrue);
      });

      test('should return false for cancellation failures', () {
        // Arrange
        const failure = SocialAuthCancelledFailure();

        // Act
        final shouldRetry = SocialAuthErrorHandler.shouldShowRetry(failure);

        // Assert
        expect(shouldRetry, isFalse);
      });

      test('should return false for account linking failures', () {
        // Arrange
        const failure = AccountLinkingFailure('Linking failed');

        // Act
        final shouldRetry = SocialAuthErrorHandler.shouldShowRetry(failure);

        // Assert
        expect(shouldRetry, isFalse);
      });

      test('should return false for generic social auth failures', () {
        // Arrange
        const failure = SocialAuthFailure('Generic error');

        // Act
        final shouldRetry = SocialAuthErrorHandler.shouldShowRetry(failure);

        // Assert
        expect(shouldRetry, isFalse);
      });
    });

    group('shouldShowFallback', () {
      test('should return true for generic social auth failures', () {
        // Arrange
        const failure = SocialAuthFailure('Generic error');

        // Act
        final shouldShowFallback = SocialAuthErrorHandler.shouldShowFallback(
          failure,
        );

        // Assert
        expect(shouldShowFallback, isTrue);
      });

      test('should return true for account linking failures', () {
        // Arrange
        const failure = AccountLinkingFailure('Linking failed');

        // Act
        final shouldShowFallback = SocialAuthErrorHandler.shouldShowFallback(
          failure,
        );

        // Assert
        expect(shouldShowFallback, isTrue);
      });

      test('should return false for cancellation failures', () {
        // Arrange
        const failure = SocialAuthCancelledFailure();

        // Act
        final shouldShowFallback = SocialAuthErrorHandler.shouldShowFallback(
          failure,
        );

        // Assert
        expect(shouldShowFallback, isFalse);
      });

      test('should return false for network failures', () {
        // Arrange
        const failure = SocialAuthNetworkFailure();

        // Act
        final shouldShowFallback = SocialAuthErrorHandler.shouldShowFallback(
          failure,
        );

        // Assert
        expect(shouldShowFallback, isFalse);
      });

      test('should return false for timeout failures', () {
        // Arrange
        const failure = SocialAuthTimeoutFailure();

        // Act
        final shouldShowFallback = SocialAuthErrorHandler.shouldShowFallback(
          failure,
        );

        // Assert
        expect(shouldShowFallback, isFalse);
      });
    });

    group('shouldDisplayError', () {
      test('should return false for cancellation failures', () {
        // Arrange
        const failure = SocialAuthCancelledFailure();

        // Act
        final shouldDisplay = SocialAuthErrorHandler.shouldDisplayError(
          failure,
        );

        // Assert
        expect(shouldDisplay, isFalse);
      });

      test('should return true for network failures', () {
        // Arrange
        const failure = SocialAuthNetworkFailure();

        // Act
        final shouldDisplay = SocialAuthErrorHandler.shouldDisplayError(
          failure,
        );

        // Assert
        expect(shouldDisplay, isTrue);
      });

      test('should return true for timeout failures', () {
        // Arrange
        const failure = SocialAuthTimeoutFailure();

        // Act
        final shouldDisplay = SocialAuthErrorHandler.shouldDisplayError(
          failure,
        );

        // Assert
        expect(shouldDisplay, isTrue);
      });

      test('should return true for generic social auth failures', () {
        // Arrange
        const failure = SocialAuthFailure('Generic error');

        // Act
        final shouldDisplay = SocialAuthErrorHandler.shouldDisplayError(
          failure,
        );

        // Assert
        expect(shouldDisplay, isTrue);
      });

      test('should return true for account linking failures', () {
        // Arrange
        const failure = AccountLinkingFailure('Linking failed');

        // Act
        final shouldDisplay = SocialAuthErrorHandler.shouldDisplayError(
          failure,
        );

        // Assert
        expect(shouldDisplay, isTrue);
      });
    });

    group('getErrorIcon', () {
      test('should return wifi_off icon for network failures', () {
        // Arrange
        const failure = SocialAuthNetworkFailure();

        // Act
        final icon = SocialAuthErrorHandler.getErrorIcon(failure);

        // Assert
        expect(icon, equals(Icons.wifi_off));
      });

      test('should return wifi_off icon for generic network failures', () {
        // Arrange
        const failure = NetworkFailure();

        // Act
        final icon = SocialAuthErrorHandler.getErrorIcon(failure);

        // Assert
        expect(icon, equals(Icons.wifi_off));
      });

      test('should return access_time icon for timeout failures', () {
        // Arrange
        const failure = SocialAuthTimeoutFailure();

        // Act
        final icon = SocialAuthErrorHandler.getErrorIcon(failure);

        // Assert
        expect(icon, equals(Icons.access_time));
      });

      test('should return link_off icon for account linking failures', () {
        // Arrange
        const failure = AccountLinkingFailure('Linking failed');

        // Act
        final icon = SocialAuthErrorHandler.getErrorIcon(failure);

        // Assert
        expect(icon, equals(Icons.link_off));
      });

      test('should return error_outline icon for generic failures', () {
        // Arrange
        const failure = SocialAuthFailure('Generic error');

        // Act
        final icon = SocialAuthErrorHandler.getErrorIcon(failure);

        // Assert
        expect(icon, equals(Icons.error_outline));
      });
    });

    group('getErrorColor', () {
      testWidgets('should return error color from theme', (tester) async {
        await tester.pumpWidget(testApp);

        // Arrange
        const failure = SocialAuthNetworkFailure();
        final expectedColor = Theme.of(testContext).colorScheme.error;

        // Act
        final color = SocialAuthErrorHandler.getErrorColor(
          testContext,
          failure,
        );

        // Assert
        expect(color, equals(expectedColor));
      });
    });

    group('getRepeatedFailureMessage', () {
      testWidgets('should return regular message for low attempt count', (
        tester,
      ) async {
        await tester.pumpWidget(testApp);

        // Arrange
        const failure = SocialAuthNetworkFailure();
        const attemptCount = 2;

        // Act
        final message = SocialAuthErrorHandler.getRepeatedFailureMessage(
          testContext,
          failure,
          attemptCount,
        );

        final regularMessage = SocialAuthErrorHandler.getErrorMessage(
          testContext,
          failure,
        );

        // Assert
        expect(message, equals(regularMessage));
      });

      testWidgets('should return enhanced message for high attempt count', (
        tester,
      ) async {
        await tester.pumpWidget(testApp);

        // Arrange
        const failure = SocialAuthNetworkFailure();
        const attemptCount = 4;

        // Act
        final message = SocialAuthErrorHandler.getRepeatedFailureMessage(
          testContext,
          failure,
          attemptCount,
        );

        // Assert
        expect(message, isNotEmpty);
        // Enhanced message should suggest alternatives
        expect(
          message.toLowerCase().contains('network') ||
              message.toLowerCase().contains('repeated'),
          isTrue,
        );
      });
    });

    group('shouldSuggestAlternatives', () {
      test('should return false for low attempt count', () {
        // Arrange
        const failure = SocialAuthNetworkFailure();
        const attemptCount = 2;

        // Act
        final shouldSuggest = SocialAuthErrorHandler.shouldSuggestAlternatives(
          failure,
          attemptCount,
        );

        // Assert
        expect(shouldSuggest, isFalse);
      });

      test(
        'should return true for high attempt count with fallback-eligible '
        'failure',
        () {
          // Arrange
          const failure = SocialAuthFailure('Generic error');
          const attemptCount = 4;

          // Act
          final shouldSuggest =
              SocialAuthErrorHandler.shouldSuggestAlternatives(
                failure,
                attemptCount,
              );

          // Assert
          expect(shouldSuggest, isTrue);
        },
      );

      test(
        'should return false for high attempt count with non-fallback failure',
        () {
          // Arrange
          const failure = SocialAuthCancelledFailure();
          const attemptCount = 4;

          // Act
          final shouldSuggest =
              SocialAuthErrorHandler.shouldSuggestAlternatives(
                failure,
                attemptCount,
              );

          // Assert
          expect(shouldSuggest, isFalse);
        },
      );
    });

    group('getRecoveryActions', () {
      testWidgets('should include retry action for network failures', (
        tester,
      ) async {
        await tester.pumpWidget(testApp);

        // Arrange
        const failure = SocialAuthNetworkFailure();
        const attemptCount = 1;

        // Act
        final actions = SocialAuthErrorHandler.getRecoveryActions(
          testContext,
          failure,
          attemptCount,
        );

        // Assert
        final hasRetry = actions.any(
          (action) => action.type == RecoveryActionType.retry,
        );
        expect(hasRetry, isTrue);
      });

      testWidgets('should include fallback action for generic failures', (
        tester,
      ) async {
        await tester.pumpWidget(testApp);

        // Arrange
        const failure = SocialAuthFailure('Generic error');
        const attemptCount = 1;

        // Act
        final actions = SocialAuthErrorHandler.getRecoveryActions(
          testContext,
          failure,
          attemptCount,
        );

        // Assert
        final hasFallback = actions.any(
          (action) => action.type == RecoveryActionType.fallback,
        );
        expect(hasFallback, isTrue);
      });

      testWidgets('should include fallback action for high attempt count', (
        tester,
      ) async {
        await tester.pumpWidget(testApp);

        // Arrange
        const failure = SocialAuthFailure('Generic error');
        const attemptCount = 4;

        // Act
        final actions = SocialAuthErrorHandler.getRecoveryActions(
          testContext,
          failure,
          attemptCount,
        );

        // Assert
        final hasFallback = actions.any(
          (action) => action.type == RecoveryActionType.fallback,
        );
        expect(hasFallback, isTrue);
      });

      testWidgets('should always include dismiss action', (tester) async {
        await tester.pumpWidget(testApp);

        // Arrange
        const failure = SocialAuthNetworkFailure();
        const attemptCount = 1;

        // Act
        final actions = SocialAuthErrorHandler.getRecoveryActions(
          testContext,
          failure,
          attemptCount,
        );

        // Assert
        final hasDismiss = actions.any(
          (action) => action.type == RecoveryActionType.dismiss,
        );
        expect(hasDismiss, isTrue);
      });

      testWidgets('should have non-empty labels for all actions', (
        tester,
      ) async {
        await tester.pumpWidget(testApp);

        // Arrange
        const failure = SocialAuthNetworkFailure();
        const attemptCount = 1;

        // Act
        final actions = SocialAuthErrorHandler.getRecoveryActions(
          testContext,
          failure,
          attemptCount,
        );

        // Assert
        for (final action in actions) {
          expect(action.label, isNotEmpty);
        }
      });
    });

    group('RecoveryAction', () {
      test('should create retry action correctly', () {
        // Arrange & Act
        const action = RecoveryAction.retry('Retry');

        // Assert
        expect(action.type, equals(RecoveryActionType.retry));
        expect(action.label, equals('Retry'));
      });

      test('should create fallback action correctly', () {
        // Arrange & Act
        const action = RecoveryAction.fallback('Sign in with email');

        // Assert
        expect(action.type, equals(RecoveryActionType.fallback));
        expect(action.label, equals('Sign in with email'));
      });

      test('should create dismiss action correctly', () {
        // Arrange & Act
        const action = RecoveryAction.dismiss('Dismiss');

        // Assert
        expect(action.type, equals(RecoveryActionType.dismiss));
        expect(action.label, equals('Dismiss'));
      });
    });
  });
}
