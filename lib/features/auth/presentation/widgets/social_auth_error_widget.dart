import 'package:flutter/material.dart';
import 'package:grex/features/auth/domain/entities/failures.dart';
import 'package:grex/features/auth/presentation/utils/social_auth_error_handler.dart';

/// Widget for displaying social authentication errors with recovery options
///
/// This widget displays user-friendly error messages and provides appropriate
/// recovery actions based on the type of authentication failure.
///
/// Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6
class SocialAuthErrorWidget extends StatelessWidget {
  /// Creates a [SocialAuthErrorWidget].
  ///
  /// The [failure] parameter is required.
  const SocialAuthErrorWidget({
    required this.failure,
    super.key,
    this.onRetry,
    this.onFallback,
    this.onDismiss,
    this.attemptCount = 1,
  });

  /// The authentication failure to display
  final AuthFailure failure;

  /// Callback for retry action
  final VoidCallback? onRetry;

  /// Callback for fallback action (e.g., sign in with email)
  final VoidCallback? onFallback;

  /// Callback for dismiss action
  final VoidCallback? onDismiss;

  /// Number of attempts made (for repeated failure handling)
  final int attemptCount;

  @override
  Widget build(BuildContext context) {
    // Don't display anything for cancellation failures
    if (!SocialAuthErrorHandler.shouldDisplayError(failure)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    final errorMessage = attemptCount >= 3
        ? SocialAuthErrorHandler.getRepeatedFailureMessage(
            context,
            failure,
            attemptCount,
          )
        : SocialAuthErrorHandler.getErrorMessage(context, failure);

    final errorIcon = SocialAuthErrorHandler.getErrorIcon(failure);
    final errorColor = SocialAuthErrorHandler.getErrorColor(context, failure);
    final recoveryActions = SocialAuthErrorHandler.getRecoveryActions(
      context,
      failure,
      attemptCount,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.1),
        border: Border.all(color: errorColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error icon and message
          Row(
            children: [
              Icon(
                errorIcon,
                color: errorColor,
                size: 24,
                semanticLabel: _getIconSemanticLabel(failure),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: errorColor,
                  ),
                  semanticsLabel: errorMessage,
                ),
              ),
            ],
          ),

          // Recovery actions
          if (recoveryActions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recoveryActions
                  .map(
                    (action) => _buildActionButton(
                      context,
                      action,
                      theme,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    RecoveryAction action,
    ThemeData theme,
  ) {
    VoidCallback? callback;
    ButtonStyle? style;

    switch (action.type) {
      case RecoveryActionType.retry:
        callback = onRetry;
        style = ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        );
      case RecoveryActionType.fallback:
        callback = onFallback;
        style = OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
        );
      case RecoveryActionType.dismiss:
        callback = onDismiss;
        style = TextButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
        );
    }

    Widget button;

    switch (action.type) {
      case RecoveryActionType.retry:
        button = ElevatedButton(
          onPressed: callback,
          style: style,
          child: Text(action.label),
        );
      case RecoveryActionType.fallback:
        button = OutlinedButton(
          onPressed: callback,
          style: style,
          child: Text(action.label),
        );
      case RecoveryActionType.dismiss:
        button = TextButton(
          onPressed: callback,
          style: style,
          child: Text(action.label),
        );
    }

    return Semantics(
      label: _getButtonSemanticLabel(action),
      button: true,
      child: button,
    );
  }

  String _getIconSemanticLabel(AuthFailure failure) {
    if (failure is SocialAuthNetworkFailure || failure is NetworkFailure) {
      return 'Network error';
    } else if (failure is SocialAuthTimeoutFailure) {
      return 'Timeout error';
    } else if (failure is AccountLinkingFailure) {
      return 'Account linking error';
    } else {
      return 'Authentication error';
    }
  }

  String _getButtonSemanticLabel(RecoveryAction action) {
    switch (action.type) {
      case RecoveryActionType.retry:
        return 'Retry authentication';
      case RecoveryActionType.fallback:
        return 'Use alternative sign in method';
      case RecoveryActionType.dismiss:
        return 'Dismiss error';
    }
  }
}
