import 'package:flutter/material.dart';
import 'package:grex/features/auth/domain/entities/failures.dart';
import 'package:grex/shared/extensions/context_extensions.dart';

/// Utility class for handling social authentication errors in the UI
///
/// This class provides methods to map failures to localized messages,
/// determine when to show retry buttons, and handle error recovery flows.
///
/// Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6
class SocialAuthErrorHandler {
  /// Gets a localized error message for the given failure
  ///
  /// Maps different types of authentication failures to user-friendly,
  /// localized error messages that can be displayed in the UI.
  ///
  /// Requirements: 8.1
  static String getErrorMessage(BuildContext context, AuthFailure failure) {
    final l10n = context.l10n;

    return switch (failure) {
      SocialAuthCancelledFailure() => '',
      SocialAuthNetworkFailure() => l10n.socialAuthNetworkError,
      SocialAuthTimeoutFailure() => l10n.socialAuthTimeout,
      AccountLinkingFailure() => l10n.accountLinkingError,
      SocialAuthFailure() => l10n.socialAuthFailed,
      NetworkFailure() => l10n.socialAuthNetworkError,
      _ => l10n.socialAuthFailed,
    };
  }

  /// Determines whether to show a retry button for the given failure
  ///
  /// Network and timeout errors should show retry buttons, while
  /// cancellation and some other errors should not.
  ///
  /// Requirements: 8.2
  static bool shouldShowRetry(AuthFailure failure) {
    return switch (failure) {
      SocialAuthNetworkFailure() => true,
      SocialAuthTimeoutFailure() => true,
      NetworkFailure() => true,
      _ => false,
    };
  }

  /// Determines whether to show a fallback "Sign in with email" button
  ///
  /// Generic failures and repeated failures should show fallback options,
  /// while specific recoverable errors should not.
  ///
  /// Requirements: 8.4, 8.6
  static bool shouldShowFallback(AuthFailure failure) {
    return switch (failure) {
      SocialAuthFailure() => true,
      AccountLinkingFailure() => true,
      _ => false,
    };
  }

  /// Determines if the error should be displayed to the user
  ///
  /// Cancellation errors should be handled silently without showing
  /// any error message to the user.
  ///
  /// Requirements: 8.5
  static bool shouldDisplayError(AuthFailure failure) {
    return failure is! SocialAuthCancelledFailure;
  }

  /// Gets the appropriate icon for the error type
  ///
  /// Returns an icon that visually represents the type of error
  /// to help users understand the issue.
  static IconData getErrorIcon(AuthFailure failure) {
    return switch (failure) {
      SocialAuthNetworkFailure() => Icons.wifi_off,
      NetworkFailure() => Icons.wifi_off,
      SocialAuthTimeoutFailure() => Icons.access_time,
      AccountLinkingFailure() => Icons.link_off,
      _ => Icons.error_outline,
    };
  }

  /// Gets the color for the error message and icon
  ///
  /// Returns appropriate colors based on the error severity
  static Color getErrorColor(BuildContext context, AuthFailure failure) {
    final theme = Theme.of(context);

    return switch (failure) {
      SocialAuthNetworkFailure() => theme.colorScheme.error,
      SocialAuthTimeoutFailure() => theme.colorScheme.error,
      NetworkFailure() => theme.colorScheme.error,
      AccountLinkingFailure() => theme.colorScheme.error,
      _ => theme.colorScheme.error,
    };
  }

  /// Handles repeated failures by suggesting alternatives
  ///
  /// After multiple failures of the same type, suggests alternative
  /// authentication methods to the user.
  ///
  /// Requirements: 8.4
  static String getRepeatedFailureMessage(
    BuildContext context,
    AuthFailure failure,
    int attemptCount,
  ) {
    final l10n = context.l10n;

    if (attemptCount >= 3) {
      return switch (failure) {
        SocialAuthNetworkFailure() => l10n.repeatedNetworkFailureMessage,
        NetworkFailure() => l10n.repeatedNetworkFailureMessage,
        SocialAuthTimeoutFailure() => l10n.repeatedTimeoutFailureMessage,
        _ => l10n.repeatedAuthFailureMessage,
      };
    }

    return getErrorMessage(context, failure);
  }

  /// Determines if alternative methods should be suggested
  ///
  /// After multiple failures, suggests using email/password login
  /// as an alternative authentication method.
  ///
  /// Requirements: 8.4
  static bool shouldSuggestAlternatives(AuthFailure failure, int attemptCount) {
    // After 3+ attempts, suggest alternatives for any failure type except
    // cancellation
    if (attemptCount >= 3) {
      return switch (failure) {
        SocialAuthCancelledFailure() => false,
        _ => true,
      };
    }
    return false;
  }

  /// Gets recovery actions for the given failure
  ///
  /// Returns a list of actions the user can take to recover from
  /// the error, such as retry, use alternative method, etc.
  ///
  /// Requirements: 8.6
  static List<RecoveryAction> getRecoveryActions(
    BuildContext context,
    AuthFailure failure,
    int attemptCount,
  ) {
    final actions = <RecoveryAction>[];

    // Add retry action for recoverable errors
    if (shouldShowRetry(failure)) {
      actions.add(RecoveryAction.retry(context.l10n.retry));
    }

    // Add fallback action for appropriate errors
    if (shouldShowFallback(failure) ||
        shouldSuggestAlternatives(failure, attemptCount)) {
      actions.add(RecoveryAction.fallback(context.l10n.signInWithEmail));
    }

    // Add dismiss action for all errors
    actions.add(RecoveryAction.dismiss(context.l10n.dismiss));

    return actions;
  }
}

/// Represents a recovery action that the user can take after an error
class RecoveryAction {
  /// Creates a [RecoveryAction].
  ///
  /// The [type] and [label] parameters are required.
  const RecoveryAction({
    required this.type,
    required this.label,
  });

  /// Creates a retry action
  const RecoveryAction.retry(this.label) : type = RecoveryActionType.retry;

  /// Creates a fallback action (e.g., sign in with email)
  const RecoveryAction.fallback(this.label)
    : type = RecoveryActionType.fallback;

  /// Creates a dismiss action
  const RecoveryAction.dismiss(this.label) : type = RecoveryActionType.dismiss;

  /// The type of recovery action
  final RecoveryActionType type;

  /// The label to display for this action
  final String label;
}

/// Types of recovery actions available to users
enum RecoveryActionType {
  /// Retry the failed operation
  retry,

  /// Use an alternative authentication method
  fallback,

  /// Dismiss the error and return to previous screen
  dismiss,
}
