import 'package:equatable/equatable.dart';

/// Base class for all authentication events.
///
/// All authentication events extend this class to ensure
/// consistent event handling and equality comparison.
abstract class AuthEvent extends Equatable {
  /// Creates an [AuthEvent].
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when user attempts to log in.
///
/// Contains the email and password credentials provided by the user.
/// This event will trigger the authentication flow in the BLoC.
class AuthLoginRequested extends AuthEvent {
  /// Creates an [AuthLoginRequested] event with the provided credentials.
  ///
  /// The [email] and [password] are required for authentication.
  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  /// The email address for login
  final String email;

  /// The password for login
  final String password;

  @override
  List<Object?> get props => [email, password];

  @override
  String toString() => 'AuthLoginRequested(email: $email)';
}

/// Event triggered when user attempts to register a new account.
///
/// Contains the registration information including email, password,
/// and display name for creating a new user account and profile.
class AuthRegisterRequested extends AuthEvent {
  /// Creates an [AuthRegisterRequested] event with the provided
  /// registration data.
  ///
  /// The [email], [password], and [displayName] are required.
  /// The [preferredCurrency] and [languageCode] are optional.
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
    this.preferredCurrency,
    this.languageCode,
  });

  /// The email address for registration
  final String email;

  /// The password for registration
  final String password;

  /// The display name for the user profile
  final String displayName;

  /// The preferred currency for the user (optional, defaults to VND)
  final String? preferredCurrency;

  /// The language code for the user (optional, defaults to vi)
  final String? languageCode;

  @override
  List<Object?> get props => [
    email,
    password,
    displayName,
    preferredCurrency,
    languageCode,
  ];

  @override
  String toString() =>
      'AuthRegisterRequested(email: $email, displayName: $displayName)';
}

/// Event triggered when user attempts to log out.
///
/// This event will clear the user session and authentication state.
class AuthLogoutRequested extends AuthEvent {
  /// Creates an [AuthLogoutRequested] event.
  const AuthLogoutRequested();

  @override
  String toString() => 'AuthLogoutRequested()';
}

/// Event triggered to check the current authentication session.
///
/// This is typically called when the app starts to determine
/// if the user is already authenticated from a previous session.
class AuthSessionChecked extends AuthEvent {
  /// Creates an [AuthSessionChecked] event.
  const AuthSessionChecked();

  @override
  String toString() => 'AuthSessionChecked()';
}

/// Event triggered when user requests a password reset.
///
/// Contains the email address to send the password reset link to.
class AuthPasswordResetRequested extends AuthEvent {
  /// Creates an [AuthPasswordResetRequested] event with the provided email.
  ///
  /// The [email] is required to send the password reset link.
  const AuthPasswordResetRequested({
    required this.email,
  });

  /// The email address to send password reset to
  final String email;

  @override
  List<Object?> get props => [email];

  @override
  String toString() => 'AuthPasswordResetRequested(email: $email)';
}

/// Event triggered when authentication state changes externally.
///
/// This can happen when the user's session expires, is revoked,
/// or when they sign in/out from another device.
class AuthStateChanged extends AuthEvent {
  /// Creates an [AuthStateChanged] event with the new authentication state.
  ///
  /// The [user] parameter represents the new authentication state
  /// (null if signed out, non-null if authenticated).
  const AuthStateChanged({
    this.user,
  });

  /// The new authentication state (null if signed out)
  final dynamic user;

  @override
  List<Object?> get props => [user];

  @override
  String toString() {
    final status = user != null ? 'authenticated' : 'unauthenticated';
    return 'AuthStateChanged(user: $status)';
  }
}

/// Event triggered to initialize session management.
///
/// This event should be called when the app starts to restore
/// any existing session and start automatic session management.
class AuthSessionInitialized extends AuthEvent {
  /// Creates an [AuthSessionInitialized] event.
  const AuthSessionInitialized();

  @override
  String toString() => 'AuthSessionInitialized()';
}

/// Event triggered when user requests to resend verification email.
///
/// This event will send a new verification email to the current user's
/// email address if they haven't verified their email yet.
class AuthVerificationEmailRequested extends AuthEvent {
  /// Creates an [AuthVerificationEmailRequested] event.
  const AuthVerificationEmailRequested();

  @override
  String toString() => 'AuthVerificationEmailRequested()';
}

/// Event triggered when user attempts to verify their email.
///
/// Contains the verification token and email address from the
/// verification link received via email.
class AuthEmailVerificationRequested extends AuthEvent {
  /// Creates an [AuthEmailVerificationRequested] event with verification data.
  ///
  /// The [token] and [email] are required for email verification.
  const AuthEmailVerificationRequested({
    required this.token,
    required this.email,
  });

  /// The verification token from the email link
  final String token;

  /// The email address being verified
  final String email;

  @override
  List<Object?> get props => [token, email];

  @override
  String toString() => 'AuthEmailVerificationRequested(email: $email)';
}

/// Event triggered when user attempts to verify email using OTP code.
///
/// Contains the OTP code and email address for verification.
class AuthOtpVerificationRequested extends AuthEvent {
  /// Creates an [AuthOtpVerificationRequested] event with OTP data.
  ///
  /// The [token] (OTP code) and [email] are required for verification.
  const AuthOtpVerificationRequested({
    required this.email,
    required this.token,
  });

  /// The OTP code from the email
  final String token;

  /// The email address being verified
  final String email;

  @override
  List<Object?> get props => [token, email];

  @override
  String toString() => 'AuthOtpVerificationRequested(email: $email)';
}

/// Event triggered when user updates their password with a reset token.
///
/// Contains the new password and reset token from the password reset flow.
/// This is used to complete the password reset process after the user
/// receives the reset email and clicks the reset link.
class AuthPasswordUpdateRequested extends AuthEvent {
  /// Creates an [AuthPasswordUpdateRequested] event with the new password.
  ///
  /// The [newPassword] is required for updating the user's password.
  /// The [token] is optional and used for password reset flows.
  const AuthPasswordUpdateRequested({
    required this.newPassword,
    this.token,
  });

  /// The new password to set
  final String newPassword;

  /// The reset token (optional, for password reset flows)
  final String? token;

  @override
  List<Object?> get props => [newPassword, token];

  @override
  String toString() => 'AuthPasswordUpdateRequested()';
}

/// Event triggered when user requests social login.
///
/// Contains the social provider (Google or Apple) for authentication.
/// This event will initiate the OAuth flow for the specified provider.
class AuthSocialLoginRequested extends AuthEvent {
  /// Creates an [AuthSocialLoginRequested] event with the provider.
  ///
  /// The [provider] specifies which OAuth provider to use (google or apple).
  const AuthSocialLoginRequested(this.provider);

  /// The social authentication provider (google or apple)
  final String provider;

  @override
  List<Object?> get props => [provider];

  @override
  String toString() => 'AuthSocialLoginRequested(provider: $provider)';
}

/// Event triggered when user completes profile setup after social login.
///
/// Contains the profile information provided by the user during
/// the profile completion flow for new social login users.
class AuthProfileSetupCompleted extends AuthEvent {
  /// Creates an [AuthProfileSetupCompleted] event with profile data.
  ///
  /// All parameters are required for creating the user profile.
  const AuthProfileSetupCompleted({
    required this.displayName,
    required this.preferredCurrency,
    required this.languageCode,
  });

  /// The display name for the user profile
  final String displayName;

  /// The preferred currency for the user
  final String preferredCurrency;

  /// The language code for the user
  final String languageCode;

  @override
  List<Object?> get props => [displayName, preferredCurrency, languageCode];

  @override
  String toString() =>
      'AuthProfileSetupCompleted('
      'displayName: $displayName, '
      'preferredCurrency: $preferredCurrency, '
      'languageCode: $languageCode)';
}

/// Event triggered when user cancels profile setup after social login.
///
/// This event will sign out the user and return them to the login screen
/// since profile completion is required for new social login users.
class AuthProfileSetupCancelled extends AuthEvent {
  /// Creates an [AuthProfileSetupCancelled] event.
  const AuthProfileSetupCancelled();

  @override
  String toString() => 'AuthProfileSetupCancelled()';
}

/// Event triggered when user confirms account linking.
///
/// Contains the existing user ID to link the social provider to.
/// This happens when a social login email matches an existing account.
class AuthAccountLinkingConfirmed extends AuthEvent {
  /// Creates an [AuthAccountLinkingConfirmed] event with existing user ID.
  ///
  /// The [existingUserId] is the ID of the existing user account
  /// to link the social provider to.
  const AuthAccountLinkingConfirmed(this.existingUserId);

  /// The ID of the existing user account to link to
  final String existingUserId;

  @override
  List<Object?> get props => [existingUserId];

  @override
  String toString() =>
      'AuthAccountLinkingConfirmed(existingUserId: $existingUserId)';
}

/// Event triggered when user declines account linking.
///
/// This event will treat the social login as a new account and
/// initiate the profile setup flow instead of linking accounts.
class AuthAccountLinkingDeclined extends AuthEvent {
  /// Creates an [AuthAccountLinkingDeclined] event.
  const AuthAccountLinkingDeclined();

  @override
  String toString() => 'AuthAccountLinkingDeclined()';
}
