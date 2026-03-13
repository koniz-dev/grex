import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF0E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Color(0xFFDC2626),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
