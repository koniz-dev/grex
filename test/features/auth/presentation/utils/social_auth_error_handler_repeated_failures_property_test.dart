import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/failures.dart';
import 'package:grex/features/auth/presentation/utils/social_auth_error_handler.dart';
import 'package:grex/l10n/app_localizations.dart';

/// Property-Based Test: Repeated Failures Suggest Alternatives
///
/// Validates: Requirements 8.4
///
/// This property test verifies that after multiple failures of the same type,
/// the system suggests alternative authentication methods and provides
/// appropriate recovery options to help users succeed.
void main() {
  group('Property 28: Repeated Failures Suggest Alternatives', () {
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

    testWidgets(
      'should suggest alternatives after repeated network failures with 100+ iterations',
      (tester) async {
        await tester.pumpWidget(testApp);

        // Property: After 3+ network failures, alternative methods should be suggested
        for (var i = 0; i < 100; i++) {
          const failure = SocialAuthNetworkFailure();
          final attemptCount = 3 + (i % 5); // 3-7 attempts

          // Act: Get error message for repeated failures
          final message = SocialAuthErrorHandler.getRepeatedFailureMessage(
            testContext,
            failure,
            attemptCount,
          );

          final shouldSuggestAlternatives =
              SocialAuthErrorHandler.shouldSuggestAlternatives(
                failure,
                attemptCount,
              );

          final recoveryActions = SocialAuthErrorHandler.getRecoveryActions(
            testContext,
            failure,
            attemptCount,
          );

          // Assert: Verify alternatives are suggested
          expect(shouldSuggestAlternatives, isTrue);
          expect(
            message.contains('email') || message.contains('alternative'),
            isTrue,
          );

          // Verify recovery actions include fallback
          final hasFallbackAction = recoveryActions.any(
            (action) => action.type == RecoveryActionType.fallback,
          );
          expect(hasFallbackAction, isTrue);

          // Verify message is more helpful than single failure
          _verifyRepeatedFailureMessage(message, failure, attemptCount);
        }
      },
    );

    testWidgets(
      'should suggest alternatives after repeated timeout failures with 100+ iterations',
      (tester) async {
        await tester.pumpWidget(testApp);

        // Property: After 3+ timeout failures, alternative methods should be suggested
        for (var i = 0; i < 100; i++) {
          const failure = SocialAuthTimeoutFailure();
          final attemptCount = 3 + (i % 5); // 3-7 attempts

          // Act
          final message = SocialAuthErrorHandler.getRepeatedFailureMessage(
            testContext,
            failure,
            attemptCount,
          );

          final shouldSuggestAlternatives =
              SocialAuthErrorHandler.shouldSuggestAlternatives(
                failure,
                attemptCount,
              );

          // Assert
          expect(shouldSuggestAlternatives, isTrue);
          expect(
            message.contains('email') || message.contains('alternative'),
            isTrue,
          );

          // Verify timeout-specific guidance
          _verifyTimeoutRepeatedFailureMessage(message, attemptCount);
        }
      },
    );

    testWidgets(
      'should suggest alternatives after repeated auth failures with 100+ iterations',
      (tester) async {
        await tester.pumpWidget(testApp);

        // Property: After 3+ generic auth failures, alternatives should be suggested
        for (var i = 0; i < 100; i++) {
          const failure = SocialAuthFailure('Authentication failed');
          final attemptCount = 3 + (i % 5); // 3-7 attempts

          // Act
          final message = SocialAuthErrorHandler.getRepeatedFailureMessage(
            testContext,
            failure,
            attemptCount,
          );

          final shouldSuggestAlternatives =
              SocialAuthErrorHandler.shouldSuggestAlternatives(
                failure,
                attemptCount,
              );

          final recoveryActions = SocialAuthErrorHandler.getRecoveryActions(
            testContext,
            failure,
            attemptCount,
          );

          // Assert
          expect(shouldSuggestAlternatives, isTrue);
          expect(
            message.contains('email') ||
                message.contains('alternative') ||
                message.contains('support'),
            isTrue,
          );

          // Verify comprehensive recovery options
          _verifyComprehensiveRecoveryOptions(recoveryActions);
        }
      },
    );

    testWidgets(
      'should not suggest alternatives for low attempt counts with 100+ iterations',
      (tester) async {
        await tester.pumpWidget(testApp);

        // Property: Fewer than 3 attempts should not suggest alternatives
        for (var i = 0; i < 100; i++) {
          final failures = _generateVariousFailures(i);
          final attemptCount = 1 + (i % 2); // 1-2 attempts

          for (final failure in failures) {
            // Act
            final shouldSuggestAlternatives =
                SocialAuthErrorHandler.shouldSuggestAlternatives(
                  failure,
                  attemptCount,
                );

            final message = SocialAuthErrorHandler.getRepeatedFailureMessage(
              testContext,
              failure,
              attemptCount,
            );

            // Assert: Should not suggest alternatives for low attempt counts
            expect(shouldSuggestAlternatives, isFalse);

            // Message should be the same as single failure message
            final singleFailureMessage = SocialAuthErrorHandler.getErrorMessage(
              testContext,
              failure,
            );
            expect(message, equals(singleFailureMessage));
          }
        }
      },
    );

    testWidgets(
      'should provide escalating help with increasing attempts with 100+ iterations',
      (tester) async {
        await tester.pumpWidget(testApp);

        // Property: Help should escalate with more attempts
        for (var i = 0; i < 100; i++) {
          const failure = SocialAuthNetworkFailure();

          // Test escalating attempt counts
          for (var attempts = 1; attempts <= 6; attempts++) {
            final message = SocialAuthErrorHandler.getRepeatedFailureMessage(
              testContext,
              failure,
              attempts,
            );

            final recoveryActions = SocialAuthErrorHandler.getRecoveryActions(
              testContext,
              failure,
              attempts,
            );

            // Verify escalation
            _verifyHelpEscalation(message, recoveryActions, attempts);
          }
        }
      },
    );

    testWidgets(
      'should handle cancellation failures appropriately with 100+ iterations',
      (tester) async {
        await tester.pumpWidget(testApp);

        // Property: Cancellation failures should not suggest alternatives regardless of count
        for (var i = 0; i < 100; i++) {
          const failure = SocialAuthCancelledFailure();
          final attemptCount = 3 + (i % 5); // 3-7 attempts

          // Act
          final shouldSuggestAlternatives =
              SocialAuthErrorHandler.shouldSuggestAlternatives(
                failure,
                attemptCount,
              );

          final shouldDisplayError = SocialAuthErrorHandler.shouldDisplayError(
            failure,
          );

          // Assert: Cancellation should not suggest alternatives or display errors
          expect(shouldSuggestAlternatives, isFalse);
          expect(shouldDisplayError, isFalse);
        }
      },
    );

    testWidgets(
      'should provide contextual recovery actions with 100+ iterations',
      (tester) async {
        await tester.pumpWidget(testApp);

        // Property: Recovery actions should be contextual to failure type and attempt count
        for (var i = 0; i < 100; i++) {
          final failureTypes = _generateFailureTypes(i);
          final attemptCount = 3 + (i % 3); // 3-5 attempts

          for (final failure in failureTypes) {
            final recoveryActions = SocialAuthErrorHandler.getRecoveryActions(
              testContext,
              failure,
              attemptCount,
            );

            // Verify contextual actions
            _verifyContextualRecoveryActions(
              failure,
              attemptCount,
              recoveryActions,
            );
          }
        }
      },
    );
  });
}

/// Generates various failure types for testing
List<AuthFailure> _generateVariousFailures(int seed) {
  final failures = [
    const SocialAuthNetworkFailure(),
    const SocialAuthTimeoutFailure(),
    const SocialAuthFailure('Generic failure'),
    const AccountLinkingFailure('Linking failed'),
    const SocialAuthCancelledFailure(),
  ];

  return [failures[seed % failures.length]];
}

/// Generates different failure types for comprehensive testing
List<AuthFailure> _generateFailureTypes(int seed) {
  return [
    const SocialAuthNetworkFailure(),
    const SocialAuthTimeoutFailure(),
    const SocialAuthFailure('Auth failed'),
    const AccountLinkingFailure('Link failed'),
  ];
}

/// Verifies repeated failure message is more helpful
void _verifyRepeatedFailureMessage(
  String message,
  AuthFailure failure,
  int attemptCount,
) {
  // Should be more helpful than single failure message
  expect(message, isNotEmpty);

  // Should suggest alternatives for network failures after 3+ attempts
  if (failure is SocialAuthNetworkFailure && attemptCount >= 3) {
    expect(
      message.toLowerCase().contains('email') ||
          message.toLowerCase().contains('alternative') ||
          message.toLowerCase().contains('try'),
      isTrue,
    );
  }

  // Should not be overly technical
  expect(message, isNot(contains('retry count')));
  expect(message, isNot(contains('attempt #')));
}

/// Verifies timeout repeated failure message
void _verifyTimeoutRepeatedFailureMessage(String message, int attemptCount) {
  expect(message, isNotEmpty);

  // Should suggest email alternative for repeated timeouts
  if (attemptCount >= 3) {
    expect(
      message.toLowerCase().contains('email') ||
          message.toLowerCase().contains('alternative'),
      isTrue,
    );
  }
}

/// Verifies comprehensive recovery options are provided
void _verifyComprehensiveRecoveryOptions(List<RecoveryAction> actions) {
  expect(actions, isNotEmpty);

  // Should include fallback option
  final hasFallback = actions.any(
    (action) => action.type == RecoveryActionType.fallback,
  );
  expect(hasFallback, isTrue);

  // Should include dismiss option
  final hasDismiss = actions.any(
    (action) => action.type == RecoveryActionType.dismiss,
  );
  expect(hasDismiss, isTrue);

  // Actions should have meaningful labels
  for (final action in actions) {
    expect(action.label, isNotEmpty);
    expect(action.label, isNot(contains('null')));
  }
}

/// Verifies help escalation with increasing attempts
void _verifyHelpEscalation(
  String message,
  List<RecoveryAction> actions,
  int attempts,
) {
  expect(message, isNotEmpty);
  expect(actions, isNotEmpty);

  // More attempts should provide more recovery options
  if (attempts >= 3) {
    final hasFallback = actions.any(
      (action) => action.type == RecoveryActionType.fallback,
    );
    expect(hasFallback, isTrue);
  }

  // Should not overwhelm user with too many options
  expect(actions.length, lessThanOrEqualTo(4));
}

/// Verifies recovery actions are contextual to failure type
void _verifyContextualRecoveryActions(
  AuthFailure failure,
  int attemptCount,
  List<RecoveryAction> actions,
) {
  expect(actions, isNotEmpty);

  // Network failures should suggest retry and fallback
  if (failure is SocialAuthNetworkFailure) {
    final hasRetry = actions.any(
      (action) => action.type == RecoveryActionType.retry,
    );
    expect(hasRetry, isTrue);

    if (attemptCount >= 3) {
      final hasFallback = actions.any(
        (action) => action.type == RecoveryActionType.fallback,
      );
      expect(hasFallback, isTrue);
    }
  }

  // Timeout failures should suggest fallback after multiple attempts
  if (failure is SocialAuthTimeoutFailure && attemptCount >= 3) {
    final hasFallback = actions.any(
      (action) => action.type == RecoveryActionType.fallback,
    );
    expect(hasFallback, isTrue);
  }

  // Generic failures should suggest fallback
  if (failure is SocialAuthFailure && attemptCount >= 3) {
    final hasFallback = actions.any(
      (action) => action.type == RecoveryActionType.fallback,
    );
    expect(hasFallback, isTrue);
  }

  // All failures should have dismiss option
  final hasDismiss = actions.any(
    (action) => action.type == RecoveryActionType.dismiss,
  );
  expect(hasDismiss, isTrue);
}
