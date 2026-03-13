/// Social authentication provider types for OAuth integration.
///
/// This enum defines the supported OAuth providers for social login
/// functionality. Each provider has specific configuration requirements
/// and UI styling guidelines.
///
/// ## Supported Providers
///
/// - **Google**: Uses Google OAuth 2.0 with external browser launch
/// - **Apple**: Uses Apple Sign In with privacy features
///
/// ## Usage Example
///
/// ```dart
/// // Create provider-specific UI
/// final provider = SocialAuthProvider.google;
/// final buttonText = provider.displayName; // "Google"
/// final iconPath = provider.iconAsset; // "assets/icons/google_logo.svg"
///
/// // Parse from string
/// final provider = SocialAuthProvider.fromString('google');
/// ```
///
/// ## OAuth Configuration
///
/// Each provider requires specific configuration in Supabase Dashboard:
/// - **Google**: Client ID, Client Secret, redirect URL
/// - **Apple**: Services ID, Team ID, Key ID, Private Key (.p8)
///
/// **Requirements:** 1.1, 2.1, 6.1, 6.2
enum SocialAuthProvider {
  /// Google OAuth provider.
  ///
  /// Uses Google OAuth 2.0 with the following configuration:
  /// - Scopes: email, profile
  /// - Button styling: White background, black text
  /// - Icon: Google logo SVG
  /// - Launch mode: External browser
  google,

  /// Apple OAuth provider.
  ///
  /// Uses Apple Sign In with the following configuration:
  /// - Scopes: email, name (optional)
  /// - Button styling: Black background, white text
  /// - Icon: Apple logo SVG
  /// - Launch mode: External browser
  /// - Privacy: Supports email hiding
  apple;

  /// Human-readable display name for the provider.
  ///
  /// Used in UI elements like button text and error messages.
  /// Returns localized provider names for user display.
  String get displayName {
    switch (this) {
      case SocialAuthProvider.google:
        return 'Google';
      case SocialAuthProvider.apple:
        return 'Apple';
    }
  }

  /// Asset path for the provider's icon.
  ///
  /// Returns the SVG asset path for the provider's official logo.
  /// Icons follow official branding guidelines and are optimized
  /// for 20x20 pixel display in buttons.
  String get iconAsset {
    switch (this) {
      case SocialAuthProvider.google:
        return 'assets/icons/google_logo.svg';
      case SocialAuthProvider.apple:
        return 'assets/icons/apple_logo.svg';
    }
  }

  /// Creates a provider from string name.
  ///
  /// Parses provider names from various sources like analytics events,
  /// configuration files, or API responses. Case-insensitive matching.
  ///
  /// **Parameters:**
  /// - [provider]: Provider name string ('google', 'apple', etc.)
  ///
  /// **Returns:**
  /// - Matching [SocialAuthProvider] or `null` if not found
  ///
  /// **Example:**
  /// ```dart
  /// final google = SocialAuthProvider.fromString('GOOGLE'); // google
  /// final apple = SocialAuthProvider.fromString('apple');   // apple
  /// final invalid = SocialAuthProvider.fromString('facebook'); // null
  /// ```
  static SocialAuthProvider? fromString(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return SocialAuthProvider.google;
      case 'apple':
        return SocialAuthProvider.apple;
      default:
        return null;
    }
  }
}
