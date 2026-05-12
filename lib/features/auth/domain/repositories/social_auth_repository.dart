import 'package:dartz/dartz.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/entities/profile_setup_data.dart';

/// Repository interface for social authentication operations.
///
/// Defines the contract for OAuth-based authentication via Google and Apple,
/// including profile existence checks, account linking, and profile creation
/// for new social-login users.
///
/// ## OAuth Flow
///
/// 1. User taps a social login button
/// 2. App calls `signInWithGoogle()` or `signInWithApple()`
/// 3. External browser (or native Apple system sheet on iOS) opens
/// 4. User authorises on the provider
/// 5. Provider redirects to `io.supabase.grex://login-callback/`
/// 6. Supabase establishes the session; BLoC checks for an existing user
///    profile and routes to either the main app or profile setup
///
/// ## Error Handling
///
/// All methods return `Either<AuthFailure, T>` for explicit error handling:
/// - `SocialAuthCancelledFailure` — user cancelled
/// - `SocialAuthNetworkFailure` — network connection issue
/// - `SocialAuthTimeoutFailure` — OAuth callback timed out (10s)
/// - `NonceMismatchFailure` — server-side nonce validation failed
/// - `AccountLinkingFailure` — could not link providers
/// - `SocialAuthFailure` — generic OAuth error
abstract class SocialAuthRepository {
  /// Initiates Google OAuth with nonce-based replay protection.
  ///
  /// Launches the external browser with Google's consent screen, waits for
  /// the OAuth callback (deep link), and returns the authenticated user.
  /// Only the minimal scopes (email, profile) are requested.
  Future<Either<AuthFailure, User>> signInWithGoogle();

  /// Initiates Apple Sign In with nonce-based replay protection.
  ///
  /// On iOS/macOS, when [useNativeFlow] is true, uses the Apple
  /// Authentication Services system sheet with Face ID/Touch ID. Falls back
  /// to web OAuth on other platforms or when [useNativeFlow] is false.
  Future<Either<AuthFailure, User>> signInWithApple({
    bool useNativeFlow = true,
  });

  /// Checks whether a profile row exists for [userId] in the `users` table.
  ///
  /// Used after successful OAuth to decide whether the user can proceed to
  /// the main app or needs to complete profile setup first.
  Future<bool> hasUserProfile(String userId);

  /// Links an OAuth provider to an existing user account.
  ///
  /// Called when the social-login email matches an existing user and the
  /// user has confirmed they want to link the social provider.
  Future<Either<AuthFailure, void>> linkSocialProvider({
    required String userId,
    required SocialAuthProvider provider,
  });

  /// Creates a profile for a new social-login user using the data collected
  /// from the profile setup form.
  Future<Either<AuthFailure, UserProfile>> createUserProfile(
    String userId,
    ProfileSetupData profileData,
  );
}
