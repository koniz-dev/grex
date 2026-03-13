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

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isApple ? Colors.black : Colors.white,
          foregroundColor: isApple ? Colors.white : Colors.black87,
          disabledBackgroundColor: isApple
              ? Colors.black.withValues(alpha: 0.6)
              : Colors.grey.shade100,
          disabledForegroundColor: isApple
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.grey.shade400,
          side: BorderSide(
            color: isDisabled
                ? Colors.grey.shade300
                : (isApple ? Colors.black : const Color(0xFFE4E4E7)),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isApple ? Colors.white : Colors.black87,
                  ),
                ),
              )
            else
              SvgPicture.asset(
                provider.iconAsset,
                width: 20,
                height: 20,
                colorFilter: isDisabled
                    ? ColorFilter.mode(
                        isApple
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.grey.shade400,
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
