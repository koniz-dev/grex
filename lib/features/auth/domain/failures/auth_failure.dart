import 'package:equatable/equatable.dart';

/// Base class for authentication-related failures
///
/// All authentication failures extend this class to provide consistent
/// error handling throughout the authentication feature.
abstract class AuthFailure extends Equatable {
  /// Creates an [AuthFailure] with the given [message].
  const AuthFailure(this.message);

  /// Human-readable error message
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'AuthFailure(message: $message)';
}

/// Failure when user provides incorrect email or password
class InvalidCredentialsFailure extends AuthFailure {
  /// Creates an [InvalidCredentialsFailure].
  const InvalidCredentialsFailure() : super('Invalid email or password');
}

/// Failure when trying to register with an email that's already in use
class EmailAlreadyInUseFailure extends AuthFailure {
  /// Creates an [EmailAlreadyInUseFailure].
  const EmailAlreadyInUseFailure() : super('Email is already registered');
}

/// Failure when user provides a password that doesn't meet requirements
class WeakPasswordFailure extends AuthFailure {
  /// Creates a [WeakPasswordFailure].
  const WeakPasswordFailure() : super('Password is too weak');
}

/// Failure when network connection is unavailable or request times out
class NetworkFailure extends AuthFailure {
  /// Creates a [NetworkFailure] with an optional [customMessage].
  const NetworkFailure([String? customMessage])
    : super(customMessage ?? 'Network connection failed');
}

/// Failure when user tries to access features with unverified email
class UnverifiedEmailFailure extends AuthFailure {
  /// Creates an [UnverifiedEmailFailure].
  const UnverifiedEmailFailure() : super('Please verify your email address');
}

/// Failure when user account is not found in authentication system
class AuthUserNotFoundFailure extends AuthFailure {
  /// Creates an [AuthUserNotFoundFailure].
  const AuthUserNotFoundFailure() : super('User account not found');
}

/// Failure when session has expired or is invalid
class SessionExpiredFailure extends AuthFailure {
  /// Creates a [SessionExpiredFailure].
  const SessionExpiredFailure() : super('Session has expired');
}

/// Failure when too many authentication attempts are made
class TooManyAttemptsFailure extends AuthFailure {
  /// Creates a [TooManyAttemptsFailure].
  const TooManyAttemptsFailure()
    : super('Too many attempts. Please try again later');
}

/// Failure when email format is invalid
class InvalidEmailFailure extends AuthFailure {
  /// Creates an [InvalidEmailFailure].
  const InvalidEmailFailure() : super('Invalid email format');
}

/// Failure when password reset token is invalid or expired
class InvalidResetTokenFailure extends AuthFailure {
  /// Creates an [InvalidResetTokenFailure].
  const InvalidResetTokenFailure()
    : super('Password reset link is invalid or expired');
}

/// Generic authentication failure for unexpected errors
class UnknownAuthFailure extends AuthFailure {
  /// Creates an [UnknownAuthFailure] with an optional [customMessage].
  const UnknownAuthFailure([String? customMessage])
    : super(customMessage ?? 'An unexpected error occurred');
}
