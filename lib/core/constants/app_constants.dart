import 'package:grex/core/config/app_config.dart';

/// Application-wide constants
///
/// Contains only application constants that are not configuration.
/// For configuration values (timeouts, URLs, etc.), use [AppConfig].
/// For app version, use [AppConfig.appVersion].
class AppConstants {
  AppConstants._();

  /// Application name displayed to users
  static const String appName = 'Grex';

  /// Default number of items per page for pagination
  static const int defaultPageSize = 20;

  /// Maximum number of items per page for pagination
  static const int maxPageSize = 100;

  /// Storage key for authentication access token
  static const String tokenKey = 'auth_token';

  /// Storage key for authentication refresh token
  static const String refreshTokenKey = 'refresh_token';

  /// Storage key for cached user data
  static const String userDataKey = 'user_data';

  /// Storage key for user's theme preference (light/dark/system)
  static const String themeKey = 'theme_mode';

  /// Storage key for user's language preference
  static const String languageKey = 'language';

  /// Deep link base URL for email confirmation redirect.
  /// Used as `emailRedirectTo` in Supabase signUp so confirmation emails
  /// open the app. Must be added to Supabase Dashboard → Auth → URL
  /// Configuration → Redirect URLs. Path must contain /auth/confirm for
  /// SupabaseEmailVerificationService to parse token, email, type.
  static const String authEmailConfirmRedirectUrl = 'grex://app/auth/confirm';

  /// Public URL of the Terms of Service page shown during profile setup.
  /// Placeholder until the legal pages are hosted — replace before
  /// production launch.
  static const String termsOfServiceUrl = 'https://grex.app/terms';

  /// Public URL of the Privacy Policy page shown during profile setup.
  /// Placeholder until the legal pages are hosted — replace before
  /// production launch.
  static const String privacyPolicyUrl = 'https://grex.app/privacy';
}
