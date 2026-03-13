import 'package:flutter/material.dart';

/// Success screen widget for showing success states.
///
/// Displays a checkmark icon with success message and optional action button.
class SuccessScreen extends StatelessWidget {
  /// Creates a [SuccessScreen].
  ///
  /// The [title] and [message] parameters are required.
  const SuccessScreen({
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.autoNavigateAfter,
    super.key,
  });

  /// The title text to display.
  final String title;

  /// The message text to display below the title.
  final String message;

  /// The optional button text.
  final String? buttonText;

  /// The callback when the button is pressed.
  final VoidCallback? onButtonPressed;

  /// Optional duration after which to auto-navigate.
  final Duration? autoNavigateAfter;

  @override
  Widget build(BuildContext context) {
    if (autoNavigateAfter != null && onButtonPressed != null) {
      Future.delayed(autoNavigateAfter!, () {
        if (context.mounted) {
          onButtonPressed!();
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF71717A),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Action button (if provided)
              if (buttonText != null && onButtonPressed != null)
                ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: Text(
                    buttonText!,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
