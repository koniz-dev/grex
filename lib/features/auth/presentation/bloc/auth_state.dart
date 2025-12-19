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
