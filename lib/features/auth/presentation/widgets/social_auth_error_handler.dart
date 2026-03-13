import 'package:flutter/material.dart';
import 'package:grex/features/auth/domain/entities/failures.dart';
import 'package:grex/shared/extensions/context_extensions.dart';

/// Utility class for handling social authentication errors.
///
/// Maps different failure types to user-friendly localized messages
/// and determines which action buttons should be shown.
class SocialAuthErrorHandler {
  /// Maps authentication failures to localized error messages.
  ///
  /// Returns appropriate user-friendly messages based on the failure type.
  String getErrorMessage(BuildContext context, AuthFailure failure) {
    switch (failure) {
      case SocialAuthCancelledFailure _:
        // Cancellation should not show error message
        return '';

      case SocialAuthNetworkFailure _:
        return 'Network error during sign in. Please check your connection '
            'and try again.';

      case SocialAuthTimeoutFailure _:
        return 'Sign in timed out. Please try again.';

      case AccountLinkingFailure _:
        return 'Failed to link your account. Please try again or contact '
            'support.';

      case ProfileSetupRequiredFailure _:
        return 'Profile setup is required to continue.';

      case SocialAuthFailure _:
        return 'Sign in failed. Please try again or use email sign in.';

      default:
        return context.l10n.unexpectedError;
    }
  }

  /// Determines if the retry button should be shown for the given failure.
  ///
  /// Returns true for network errors, timeout errors, and generic failures
  /// that might succeed on retry.
  bool shouldShowRetry(AuthFailure failure) {
    switch (failure) {
      case SocialAuthNetworkFailure _:
      case SocialAuthTimeoutFailure _:
      case SocialAuthFailure _:
        return true;

      case SocialAuthCancelledFailure _:
      case AccountLinkingFailure _:
      case ProfileSetupRequiredFailure _:
      default:
        return false;
    }
  }

  /// Determines if the fallback "Sign in with email" button should be shown.
  ///
  /// Returns true for generic failures where email sign-in might work
  /// as an alternative.
  bool shouldShowFallback(AuthFailure failure) {
    switch (failure) {
      case SocialAuthFailure _:
      case AccountLinkingFailure _:
        return true;

      case SocialAuthCancelledFailure _:
      case SocialAuthNetworkFailure _:
      case SocialAuthTimeoutFailure _:
      case ProfileSetupRequiredFailure _:
      default:
        return false;
    }
  }

  /// Gets a user-friendly title for the error based on failure type.
  ///
  /// Used for error dialogs or more detailed error displays.
  String getErrorTitle(BuildContext context, AuthFailure failure) {
    switch (failure) {
      case SocialAuthNetworkFailure _:
        return 'Connection Error';

      case SocialAuthTimeoutFailure _:
        return 'Timeout Error';

      case AccountLinkingFailure _:
        return 'Account Linking Failed';

      case ProfileSetupRequiredFailure _:
        return 'Profile Setup Required';

      case SocialAuthFailure _:
        return 'Sign In Failed';

      case SocialAuthCancelledFailure _:
      default:
        return context.l10n.error;
    }
  }

  /// Gets an appropriate icon for the error type.
  ///
  /// Returns IconData that visually represents the error category.
  IconData getErrorIcon(AuthFailure failure) {
    switch (failure) {
      case SocialAuthNetworkFailure _:
        return Icons.wifi_off;

      case SocialAuthTimeoutFailure _:
        return Icons.access_time;

      case AccountLinkingFailure _:
        return Icons.link_off;

      case ProfileSetupRequiredFailure _:
        return Icons.person_add;

      case SocialAuthFailure _:
        return Icons.login;

      case SocialAuthCancelledFailure _:
      default:
        return Icons.error_outline;
    }
  }

  /// Determines if the error should be logged for debugging purposes.
  ///
  /// Returns false for user-initiated cancellations, true for actual errors.
  bool shouldLogError(AuthFailure failure) {
    return failure is! SocialAuthCancelledFailure;
  }

  /// Gets a detailed error description for logging or support purposes.
  ///
  /// Includes technical details that might be useful for debugging.
  String getDetailedErrorDescription(AuthFailure failure) {
    switch (failure) {
      case SocialAuthNetworkFailure _:
        return 'Network connectivity issue during OAuth flow. '
            'Check internet connection and firewall settings.';

      case SocialAuthTimeoutFailure _:
        return 'OAuth callback timed out after 10 seconds. '
            'User may have closed browser or callback was blocked.';

      case AccountLinkingFailure _:
        return 'Failed to link social provider to existing account. '
            'Provider may already be linked to another account.';

      case ProfileSetupRequiredFailure _:
        return 'New social login user needs to complete profile setup.';

      case SocialAuthFailure _:
        return 'Generic social authentication failure. '
            'Check OAuth provider configuration and credentials.';

      case SocialAuthCancelledFailure _:
        return 'User cancelled the OAuth flow.';

      default:
        return 'Unknown authentication error: ${failure.message}';
    }
  }
}
