import 'package:equatable/equatable.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';

/// Base class for all authentication states.
///
/// All authentication states extend this class to ensure
/// consistent state handling and equality comparison.
abstract class AuthState extends Equatable {
  /// Creates an [AuthState].
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the authentication BLoC is first created.
///
/// This is the default state before any authentication operations
/// have been performed or session checks have been completed.
class AuthInitial extends AuthState {
  /// Creates an [AuthInitial] state.
  const AuthInitial();

  @override
  String toString() => 'AuthInitial()';
}

/// State indicating that an authentication operation is in progress.
///
/// This state is emitted during login, registration, logout, or
/// session check operations to show loading indicators in the UI.
class AuthLoading extends AuthState {
  /// Creates an [AuthLoading] state.
  const AuthLoading();

  @override
  String toString() => 'AuthLoading()';
}

/// State indicating that the user is successfully authenticated.
///
/// Contains the authenticated user data and their profile information.
/// This state allows the app to show authenticated content and user info.
class AuthAuthenticated extends AuthState {
  /// Creates an [AuthAuthenticated] state with the provided user data.
  ///
  /// The [user] is required. The [profile] is optional and may be loaded
  /// separately after authentication.
  const AuthAuthenticated({
    required this.user,
    this.profile,
  });

  /// The authenticated user from Supabase Auth
  final User user;

  /// The user's profile information from the database
  final UserProfile? profile;

  @override
  List<Object?> get props => [user, profile];

  @override
  String toString() =>
      'AuthAuthenticated(user: ${user.email}, '
      'profile: ${profile?.displayName})';

  /// Creates a copy of this state with updated profile information.
  ///
  /// This is useful when the profile is loaded separately after authentication
  /// or when the profile is updated while the user remains authenticated.
  AuthAuthenticated copyWith({
    User? user,
    UserProfile? profile,
  }) {
    return AuthAuthenticated(
      user: user ?? this.user,
      profile: profile ?? this.profile,
    );
  }
}

/// State indicating that the user is not authenticated.
///
/// This state is emitted when there is no active session,
/// after logout, or when session validation fails.
class AuthUnauthenticated extends AuthState {
  /// Creates an [AuthUnauthenticated] state.
  const AuthUnauthenticated();

  @override
  String toString() => 'AuthUnauthenticated()';
}

/// State indicating that an authentication operation failed.
///
/// Contains error information that can be displayed to the user
/// with appropriate error messages and recovery options.
class AuthError extends AuthState {
  /// Creates an [AuthError] state with the provided error information.
  ///
  /// The [message] is required. The [failure] is optional and provides
  /// detailed error information for programmatic error handling.
  const AuthError({
    required this.message,
    this.failure,
  });

  /// The error message to display to the user
  final String message;

  /// The specific failure that occurred (optional for detailed error handling)
  final AuthFailure? failure;

  @override
  List<Object?> get props => [message, failure];

  @override
  String toString() => 'AuthError(message: $message)';
}

/// State indicating that a password reset email has been sent.
///
/// This state provides feedback to the user that their password
/// reset request was processed successfully.
class AuthPasswordResetSent extends AuthState {
  /// Creates an [AuthPasswordResetSent] state with the provided email.
  ///
  /// The [email] is the address where the reset link was sent.
  const AuthPasswordResetSent({
    required this.email,
  });

  /// The email address the reset link was sent to
  final String email;

  @override
  List<Object?> get props => [email];

  @override
  String toString() => 'AuthPasswordResetSent(email: $email)';
}

/// State indicating that password update was successful.
///
/// This state provides feedback to the user that their password
/// was successfully updated and they can now log in with the new password.
class AuthPasswordUpdated extends AuthState {
  /// Creates an [AuthPasswordUpdated] state.
  const AuthPasswordUpdated();

  @override
  String toString() => 'AuthPasswordUpdated()';
}

/// State indicating that user registration was successful but email
/// verification is required.
///
/// This state is emitted after successful registration when the user
/// needs to verify their email address before they can fully access the app.
class AuthEmailVerificationRequired extends AuthState {
  /// Creates an [AuthEmailVerificationRequired] state with user data.
  ///
  /// The [user] and [email] are required to identify the user
  /// that needs email verification.
  const AuthEmailVerificationRequired({
    required this.user,
    required this.email,
  });

  /// The user that was created but needs email verification
  final User user;

  /// The email address that needs to be verified
  final String email;

  @override
  List<Object?> get props => [user, email];

  @override
  String toString() => 'AuthEmailVerificationRequired(email: $email)';
}

/// State indicating that a verification email has been sent.
///
/// This state provides feedback to the user that their verification
/// email request was processed successfully.
class AuthVerificationEmailSent extends AuthState {
  /// Creates an [AuthVerificationEmailSent] state with the provided email.
  ///
  /// The [email] is the address where the verification link was sent.
  const AuthVerificationEmailSent({
    required this.email,
  });

  /// The email address the verification link was sent to
  final String email;

  @override
  List<Object?> get props => [email];

  @override
  String toString() => 'AuthVerificationEmailSent(email: $email)';
}

/// State indicating that email verification was successful.
///
/// This state is emitted after the user successfully verifies their
/// email address and can now fully access the app.
class AuthEmailVerified extends AuthState {
  /// Creates an [AuthEmailVerified] state with the verified user.
  ///
  /// The [user] is the user whose email was successfully verified.
  const AuthEmailVerified({
    required this.user,
  });

  /// The user whose email was verified
  final User user;

  @override
  List<Object?> get props => [user];

  @override
  String toString() => 'AuthEmailVerified(user: ${user.email})';
}

/// State indicating that social login is in progress.
///
/// Contains the provider being used for authentication to show
/// provider-specific loading indicators and disable appropriate buttons.
class AuthSocialLoginInProgress extends AuthState {
  /// Creates an [AuthSocialLoginInProgress] state with the provider.
  ///
  /// The [provider] indicates which social provider is being used.
  const AuthSocialLoginInProgress(this.provider);

  /// The social authentication provider being used
  final SocialAuthProvider provider;

  @override
  List<Object?> get props => [provider];

  @override
  String toString() => 'AuthSocialLoginInProgress(provider: ${provider.name})';
}

/// State indicating that profile setup is required for a new social user.
///
/// This state is emitted when a user successfully authenticates with
/// a social provider but doesn't have a profile in the database yet.
/// Contains pre-filled data from the OAuth provider.
class AuthProfileSetupRequired extends AuthState {
  /// Creates an [AuthProfileSetupRequired] state with user and provider data.
  ///
  /// The [user], [provider], and [email] are required.
  /// The [displayName] is optional and may be pre-filled from OAuth.
  const AuthProfileSetupRequired({
    required this.user,
    required this.provider,
    required this.email,
    this.displayName,
  });

  /// The authenticated user from social login
  final User user;

  /// The social provider used for authentication
  final SocialAuthProvider provider;

  /// The display name from OAuth provider (optional)
  final String? displayName;

  /// The email address from OAuth provider
  final String email;

  @override
  List<Object?> get props => [user, provider, displayName, email];

  @override
  String toString() =>
      'AuthProfileSetupRequired('
      'user: ${user.email}, '
      'provider: ${provider.name}, '
      'displayName: $displayName, '
      'email: $email)';
}

/// State indicating that account linking is required.
///
/// This state is emitted when a social login email matches an existing
/// user account, prompting the user to confirm linking the accounts.
class AuthAccountLinkingRequired extends AuthState {
  /// Creates an [AuthAccountLinkingRequired] state with linking data.
  ///
  /// All parameters are required to display the linking confirmation dialog.
  const AuthAccountLinkingRequired({
    required this.newUser,
    required this.existingProfile,
    required this.provider,
  });

  /// The new user from social login
  final User newUser;

  /// The existing user profile with matching email
  final UserProfile existingProfile;

  /// The social provider used for authentication
  final SocialAuthProvider provider;

  @override
  List<Object?> get props => [newUser, existingProfile, provider];

  @override
  String toString() =>
      'AuthAccountLinkingRequired('
      'newUser: ${newUser.email}, '
      'existingProfile: ${existingProfile.email}, '
      'provider: ${provider.name})';
}
