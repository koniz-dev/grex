import 'package:equatable/equatable.dart';

/// Base class for authentication-related failures
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

/// Authentication failed due to invalid credentials
class InvalidCredentialsFailure extends AuthFailure {
  /// Creates an [InvalidCredentialsFailure].
  const InvalidCredentialsFailure() : super('Invalid email or password');
}

/// Registration failed because email is already in use
class EmailAlreadyInUseFailure extends AuthFailure {
  /// Creates an [EmailAlreadyInUseFailure].
  const EmailAlreadyInUseFailure() : super('Email is already registered');
}

/// Registration failed due to weak password
class WeakPasswordFailure extends AuthFailure {
  /// Creates a [WeakPasswordFailure].
  const WeakPasswordFailure() : super('Password is too weak');
}

/// Operation failed due to network connectivity issues
class NetworkFailure extends AuthFailure {
  /// Creates a [NetworkFailure].
  const NetworkFailure() : super('Network connection failed');
}

/// User attempted action with unverified email
class UnverifiedEmailFailure extends AuthFailure {
  /// Creates an [UnverifiedEmailFailure].
  const UnverifiedEmailFailure() : super('Please verify your email address');
}

/// Generic authentication failure with custom message
class GenericAuthFailure extends AuthFailure {
  /// Creates a [GenericAuthFailure] with the provided [message].
  const GenericAuthFailure(super.message);
}

/// Concrete authentication failure for backward compatibility
class ConcreteAuthFailure extends AuthFailure {
  /// Creates a [ConcreteAuthFailure] with the provided [message].
  const ConcreteAuthFailure(super.message);
}

/// Base class for user profile-related failures
abstract class UserFailure extends Equatable {
  /// Creates a [UserFailure] with the given [message].
  const UserFailure(this.message);

  /// Human-readable error message
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'UserFailure(message: $message)';
}

/// User profile not found in database
class UserNotFoundFailure extends UserFailure {
  /// Creates a [UserNotFoundFailure].
  const UserNotFoundFailure() : super('User profile not found');
}

/// Invalid user data provided
class InvalidUserDataFailure extends UserFailure {
  /// Creates an [InvalidUserDataFailure] with the provided [message].
  const InvalidUserDataFailure(super.message);
}

/// Database operation failed for user profile
class UserDatabaseFailure extends UserFailure {
  /// Creates a [UserDatabaseFailure] with the provided [message].
  const UserDatabaseFailure(super.message);
}

/// Generic user profile failure with custom message
class GenericUserFailure extends UserFailure {
  /// Creates a [GenericUserFailure] with the provided [message].
  const GenericUserFailure(super.message);
}

/// Base class for validation failures
abstract class ValidationFailure extends Equatable {
  /// Creates a [ValidationFailure] with the given [field] and [message].
  const ValidationFailure(this.field, this.message);

  /// Field that failed validation
  final String field;

  /// Human-readable error message
  final String message;

  @override
  List<Object?> get props => [field, message];

  @override
  String toString() => 'ValidationFailure(field: $field, message: $message)';
}

/// Email format validation failed
class EmailValidationFailure extends ValidationFailure {
  /// Creates an [EmailValidationFailure].
  const EmailValidationFailure()
    : super('email', 'Please enter a valid email address');
}

/// Password strength validation failed
class PasswordValidationFailure extends ValidationFailure {
  /// Creates a [PasswordValidationFailure].
  const PasswordValidationFailure()
    : super(
        'password',
        'Password must be at least 8 characters with mixed case and numbers',
      );
}

/// Display name validation failed
class DisplayNameValidationFailure extends ValidationFailure {
  /// Creates a [DisplayNameValidationFailure].
  const DisplayNameValidationFailure()
    : super('displayName', 'Display name cannot be empty');
}

/// Currency code validation failed
class CurrencyValidationFailure extends ValidationFailure {
  /// Creates a [CurrencyValidationFailure].
  const CurrencyValidationFailure()
    : super('currency', 'Invalid currency code');
}

/// Generic validation failure with custom field and message
class GenericValidationFailure extends ValidationFailure {
  /// Creates a [GenericValidationFailure] with the provided [field] and
  /// [message].
  const GenericValidationFailure(super.field, super.message);
}
