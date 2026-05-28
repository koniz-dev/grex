import 'package:flutter/material.dart';
import 'package:grex/shared/theme/app_fonts.dart';

/// Primary button widget
///
/// Black button with white text, 56px height, 16px border radius.
/// When [isLoading] is true a spinner is shown alongside [loadingText]
/// (if provided), so screens can announce in-flight states like
/// "Signing in...".
class PrimaryButton extends StatelessWidget {
  /// Creates a [PrimaryButton].
  ///
  /// The [text] parameter is required.
  const PrimaryButton({
    required this.text,
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.loadingText,
  });

  /// The text to display on the button.
  final String text;

  /// The callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether the button is in a loading state.
  final bool isLoading;

  /// Optional text shown next to the spinner when loading. When null only
  /// the spinner is rendered (preserving the original behavior).
  final String? loadingText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.onSurface,
          foregroundColor: colorScheme.surface,
          disabledBackgroundColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          disabledForegroundColor: colorScheme.surface.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.surface,
                      ),
                    ),
                  ),
                  if (loadingText != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      loadingText!,
                      style: const TextStyle(
                        fontFamily: AppFonts.heading,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              )
            : Text(
                text,
                style: const TextStyle(
                  fontFamily: AppFonts.heading,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
