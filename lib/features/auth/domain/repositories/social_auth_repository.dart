import 'package:dartz/dartz.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/entities/profile_setup_data.dart';

/// Repository interface for social authentication operations.
///
/// This repository provides methods for OAuth-based authentication using
/// external providers like Google and Apple. It handles the complete OAuth
/// flow including browser launch, callback processing, session establishment,
/// and user profile management.
///
/// ## OAuth Flow Sequence
///
/// 1. **Initiation**: User taps social login button
/// 2. **OAuth Request**: App calls `signInWithGoogle()` or `signInWithApple()`
/// 3. **Browser Launch**: External browser opens with provider consent screen
/// 4. **User Authorization**: User approves requested scopes (email, profile)
/// 5. **Callback**: Provider redirects to `io.supabase.grex://login-callback/`
/// 6. **Session Establishment**: Supabase creates authenticated session
/// 7. **Profile Check**: App checks if user profile exists
/// 8. **Navigation**: Route to main app or profile setup
///
/// ## Error Handling
///
/// All methods return `Either<AuthFailure, T>` for functional error handling:
/// - `SocialAuthCancelledFailure`: User cancelled OAuth flow
/// - `SocialAuthNetworkFailure`: Network connection issues
/// - `SocialAuthTimeoutFailure`: OAuth callback timeout (10 seconds)
/// - `AccountLinkingFailure`: Account linking errors
/// - `SocialAuthFailure`: Generic OAuth errors
///
/// ## Usage Example
///
/// ```dart
/// final result = await socialAuthRepository.signInWithGoogle();
/// result.fold(
///   (failure) => handleError(failure),
///   (user) => navigateToApp(user),
/// );
/// ```
abstract class SocialAuthRepository {
  /// Initiates Google OAuth authentication flow.
  ///
  /// Launches external browser with Google consent screen and waits for
  /// OAuth callback. The flow uses minimal scopes (email, profile) and
  /// external browser launch mode for optimal performance.
  ///
  /// **Performance Requirements:**
  /// - OAuth flow completion: < 5 seconds after user authorization
  /// - External browser launch: Immediate
  /// - Callback processing: < 1 second
  ///
  /// **Returns:**
  /// - `Right(User)`: Successfully authenticated user
  /// - `Left(SocialAuthCancelledFailure)`: User cancelled OAuth
  /// - `Left(SocialAuthNetworkFailure)`: Network connection failed
  /// - `Left(SocialAuthTimeoutFailure)`: Callback timeout (10 seconds)
  /// - `Left(SocialAuthFailure)`: Other OAuth errors
  ///
  /// **Requirements:** 1.1, 1.2, 1.3, 1.4, 9.5
  Future<Either<AuthFailure, User>> signInWithGoogle();

  /// Initiates Apple OAuth authentication flow.
  ///
  /// Launches external browser with Apple Sign In screen and waits for
  /// OAuth callback. Supports Apple's privacy features including email
  /// hiding and uses external browser launch mode.
  ///
  /// **Performance Requirements:**
  /// - OAuth flow completion: < 5 seconds after user authorization
  /// - External browser launch: Immediate
  /// - Callback processing: < 1 second
  ///
  /// **Returns:**
  /// - `Right(User)`: Successfully authenticated user
  /// - `Left(SocialAuthCancelledFailure)`: User cancelled OAuth
  /// - `Left(SocialAuthNetworkFailure)`: Network connection failed
  /// - `Left(SocialAuthTimeoutFailure)`: Callback timeout (10 seconds)
  /// - `Left(SocialAuthFailure)`: Other OAuth errors
  ///
  /// **Requirements:** 2.1, 2.2, 2.3, 2.4, 9.6
  Future<Either<AuthFailure, User>> signInWithApple();

  /// Checks if a user profile exists for the given user ID.
  ///
  /// This method is used after successful OAuth to determine if the user
  /// needs to complete profile setup or can proceed directly to the main app.
  ///
  /// **Parameters:**
  /// - [userId]: The authenticated user's ID from OAuth provider
  ///
  /// **Returns:**
  /// - `true`: User profile exists, proceed to main app
  /// - `false`: No profile found, show profile setup
  ///
  /// **Requirements:** 4.1
  Future<bool> hasUserProfile(String userId);

  /// Links a social provider to an existing user account.
  ///
  /// This method handles account linking when a user signs in with OAuth
  /// using an email that already exists in the system. It allows users
  /// to connect their social login to their existing account.
  ///
  /// **Account Linking Flow:**
  /// 1. User signs in with social provider
  /// 2. System detects existing account with same email
  /// 3. User confirms account linking
  /// 4. OAuth provider is linked to existing account
  /// 5. User can sign in with either method in future
  ///
  /// **Parameters:**
  /// - [userId]: The existing user's ID to link to
  /// - [provider]: The social provider to link
  ///
  /// **Returns:**
  /// - `Right(void)`: Successfully linked accounts
  /// - `Left(AccountLinkingFailure)`: Linking failed
  /// - `Left(SocialAuthCancelledFailure)`: User cancelled linking
  ///
  /// **Requirements:** 5.3, 5.5
  Future<Either<AuthFailure, void>> linkSocialProvider({
    required String userId,
    required SocialAuthProvider provider,
  });

  /// Creates a user profile for new social login users.
  ///
  /// This method creates a complete user profile when a user signs in
  /// with social login for the first time. It includes social provider
  /// metadata and user preferences from the profile setup form.
  ///
  /// **Profile Data Included:**
  /// - Display name (pre-filled from OAuth or user input)
  /// - Email (from OAuth provider)
  /// - Preferred currency (user selection)
  /// - Language code (user selection)
  /// - Social provider metadata
  ///
  /// **Parameters:**
  /// - [userId]: The authenticated user's ID
  /// - [profileData]: Profile setup data from user input
  ///
  /// **Returns:**
  /// - `Right(UserProfile)`: Successfully created profile
  /// - `Left(GenericAuthFailure)`: Profile creation failed
  ///
  /// **Requirements:** 4.4, 4.5
  Future<Either<AuthFailure, UserProfile>> createUserProfile(
    String userId,
    ProfileSetupData profileData,
  );
}
