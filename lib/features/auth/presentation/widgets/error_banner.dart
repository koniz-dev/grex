import 'package:flutter/material.dart';
import 'package:grex/shared/theme/app_fonts.dart';

/// Error banner widget
///
/// Displays an error message with an alert icon in a colored container.
class ErrorBanner extends StatelessWidget {
  /// Creates an [ErrorBanner].
  ///
  /// The [message] parameter is required.
  const ErrorBanner({
    required this.message,
    super.key,
  });

  /// The error message to display.
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: colorScheme.onErrorContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
