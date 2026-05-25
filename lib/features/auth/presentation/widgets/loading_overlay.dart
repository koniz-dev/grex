import 'dart:async';
import 'package:flutter/material.dart';

/// Loading overlay widget for showing loading states.
///
/// Displays a full-screen loading indicator with optional message.
class LoadingOverlay extends StatelessWidget {
  /// Creates a [LoadingOverlay].
  const LoadingOverlay({
    this.message,
    super.key,
  });

  /// The optional message to display below the loading indicator.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                strokeWidth: 3,
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Show loading overlay as a dialog
  static void show(BuildContext context, {String? message}) {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => LoadingOverlay(message: message),
      ),
    );
  }

  /// Hide loading overlay
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}
