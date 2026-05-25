import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';

/// Service for native Google Sign-In on iOS and Android.
///
/// Uses the Google Identity SDK (via `google_sign_in` plugin) to show the
/// in-app account picker, obtain an `idToken` + `accessToken`, and exchange
/// them with Supabase via `signInWithIdToken`. Mirrors the
/// `NativeAppleSignInService` pattern, but for Google.
///
/// ## Platform Support
///
/// - **Android**: requires Google Play Services on the device.
/// - **iOS / macOS**: requires the reversed iOS client ID registered as a
///   URL scheme in `Info.plist`.
/// - **Other platforms**: callers should fall back to the web OAuth flow.
abstract class NativeGoogleSignInService {
  /// Returns `true` when the native Google flow can run on this platform
  /// (iOS or Android). On unsupported platforms callers should fall back to
  /// `signInWithOAuth`.
  bool isAvailable();

  /// Triggers the native Google account picker and returns the resulting
  /// tokens. Does **not** exchange them with Supabase — call
  /// [handleGoogleCredential] for that.
  ///
  /// **Possible failures:**
  /// - [SocialAuthCancelledFailure] — user dismissed the sheet.
  /// - [SocialAuthNetworkFailure] — Play Services / network error.
  /// - [SocialAuthFailure] — any other plugin-level error.
  Future<Either<AuthFailure, GoogleSignInTokens>> signIn();

  /// Exchanges Google ID/access tokens for a Supabase session and returns
  /// the resulting domain [User]. Persists any additional name/avatar
  /// metadata Google provides.
  Future<Either<AuthFailure, User>> handleGoogleCredential({
    required String idToken,
    required String accessToken,
    String? displayName,
    String? photoUrl,
  });
}

/// Tokens returned by a successful native Google sign-in.
class GoogleSignInTokens extends Equatable {
  /// Creates a [GoogleSignInTokens] container.
  const GoogleSignInTokens({
    required this.idToken,
    required this.accessToken,
    this.displayName,
    this.photoUrl,
  });

  /// JWT identity token signed by Google. Sent to Supabase for validation.
  final String idToken;

  /// OAuth access token. Supabase needs it alongside [idToken].
  final String accessToken;

  /// User's display name as reported by Google (optional).
  final String? displayName;

  /// URL of the user's Google avatar (optional).
  final String? photoUrl;

  @override
  List<Object?> get props => [idToken, accessToken, displayName, photoUrl];

  @override
  String toString() =>
      'GoogleSignInTokens(idToken: ${idToken.substring(0, 12)}..., '
      'accessToken: ${accessToken.substring(0, 12)}..., '
      'displayName: $displayName, photoUrl: $photoUrl)';
}
