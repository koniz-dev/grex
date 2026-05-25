import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';
import 'package:grex/shared/extensions/context_extensions.dart';

/// Social login button widget for OAuth authentication.
///
/// This widget provides a consistent, accessible button for social login
/// with provider-specific styling, loading states, and localized text.
/// It follows platform design guidelines and accessibility standards.
///
/// ## Features
///
/// - **Provider-specific styling**: Google (white) and Apple (black) themes
/// - **Loading states**: Shows progress indicator during authentication
/// - **Accessibility**: Proper semantic labels and contrast ratios
/// - **Localization**: Uses localized button text
/// - **Responsive**: Full-width design with consistent 48px height
///
/// ## Usage Example
///
/// ```dart
/// SocialLoginButton(
///   provider: SocialAuthProvider.google,
///   onPressed: () => context.read<AuthBloc>().add(
///     AuthSocialLoginRequested('google'),
///   ),
///   isLoading: state is AuthSocialLoginInProgress,
/// )
/// ```
///
/// ## Styling Guidelines
///
/// - **Google**: White background, black text, Google logo
/// - **Apple**: Black background, white text, Apple logo
/// - **Disabled**: Reduced opacity, grey border
/// - **Loading**: Progress indicator replaces icon
///
/// **Requirements:** 6.1, 6.2, 6.5, 6.6
class SocialLoginButton extends StatelessWidget {
  /// Creates a [SocialLoginButton] for the specified provider.
  ///
  /// The [provider] determines the button styling, icon, and localized text.
  /// The [onPressed] callback is invoked when the user taps the button.
  /// The [isLoading] state shows a loading indicator and disables interaction.
  ///
  /// **Parameters:**
  /// - [provider]: The social authentication provider (Google or Apple)
  /// - [onPressed]: Callback function for button press events
  /// - [isLoading]: Whether to show loading state (default: false)
  const SocialLoginButton({
    required this.provider,
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  /// The social authentication provider (Google or Apple).
  ///
  /// Determines button styling, icon, and localized text:
  /// - Google: White background, black text, Google icon
  /// - Apple: Black background, white text, Apple icon
  final SocialAuthProvider provider;

  /// Callback function called when the button is pressed.
  ///
  /// Should trigger the appropriate OAuth flow for the provider.
  /// Set to `null` to disable the button.
  final VoidCallback? onPressed;

  /// Whether the button is in loading state.
  ///
  /// When `true`:
  /// - Shows circular progress indicator instead of icon
  /// - Disables button interaction
  /// - Maintains button styling and text
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isApple = provider == SocialAuthProvider.apple;
    final isDisabled = isLoading || onPressed == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Both Apple HIG ("Sign in with Apple") and Google Branding Guidelines
    // sanction an inverted variant for dark mode: in dark theme the Apple
    // button flips to white-on-black-text, the Google button flips to
    // black-on-white-text. Foreground (text + icon) is the opposite.
    final Color foreground;
    final Color background;
    final Color borderColor;
    if (isApple) {
      background = isDark ? Colors.white : Colors.black;
      foreground = isDark ? Colors.black : Colors.white;
      borderColor = background;
    } else {
      background = isDark ? Colors.black : Colors.white;
      foreground = isDark ? Colors.white : Colors.black87;
      borderColor = isDark ? Colors.white24 : const Color(0xFFE4E4E7);
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.6),
          disabledForegroundColor: foreground.withValues(alpha: 0.6),
          side: BorderSide(
            color: isDisabled
                ? borderColor.withValues(alpha: 0.4)
                : borderColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foreground),
                ),
              )
            else
              SvgPicture.asset(
                provider.iconAsset,
                width: 20,
                height: 20,
                // Apple logo is monochrome — tint with the foreground.
                // Google's "G" is multi-colour brand mark — leave intact.
                colorFilter: isApple
                    ? ColorFilter.mode(
                        isDisabled
                            ? foreground.withValues(alpha: 0.6)
                            : foreground,
                        BlendMode.srcIn,
                      )
                    : null,
              ),
            const SizedBox(width: 12),
            Text(
              provider == SocialAuthProvider.google
                  ? context.l10n.continueWithGoogle
                  : context.l10n.continueWithApple,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
