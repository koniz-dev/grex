import 'package:equatable/equatable.dart';

/// Base class for user profile-related failures
///
/// All user profile failures extend this class to provide consistent
/// error handling for user profile operations.
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

/// Failure when user profile is not found in the database
class UserNotFoundFailure extends UserFailure {
  /// Creates a [UserNotFoundFailure].
  const UserNotFoundFailure() : super('User profile not found');
}

/// Failure when user profile data is invalid
class InvalidUserDataFailure extends UserFailure {
  /// Creates an [InvalidUserDataFailure] with the provided [message].
  const InvalidUserDataFailure(super.message);
}

/// Failure when display name is invalid (empty, too long, etc.)
class InvalidDisplayNameFailure extends UserFailure {
  /// Creates an [InvalidDisplayNameFailure].
  const InvalidDisplayNameFailure() : super('Display name is invalid');
}

/// Failure when currency code is invalid (not ISO 4217)
class InvalidCurrencyFailure extends UserFailure {
  /// Creates an [InvalidCurrencyFailure].
  const InvalidCurrencyFailure() : super('Invalid currency code');
}

/// Failure when language code is invalid (not ISO 639-1)
class InvalidLanguageFailure extends UserFailure {
  /// Creates an [InvalidLanguageFailure].
  const InvalidLanguageFailure() : super('Invalid language code');
}

/// Failure when user profile creation fails
class ProfileCreationFailure extends UserFailure {
  /// Creates a [ProfileCreationFailure] with an optional [customMessage].
  const ProfileCreationFailure([String? customMessage])
    : super(customMessage ?? 'Failed to create user profile');
}

/// Failure when user profile update fails
class ProfileUpdateFailure extends UserFailure {
  /// Creates a [ProfileUpdateFailure] with an optional [customMessage].
  const ProfileUpdateFailure([String? customMessage])
    : super(customMessage ?? 'Failed to update user profile');
}

/// Failure when database operation fails
class DatabaseFailure extends UserFailure {
  /// Creates a [DatabaseFailure] with an optional [customMessage].
  const DatabaseFailure([String? customMessage])
    : super(customMessage ?? 'Database operation failed');
}

/// Failure when user doesn't have permission to perform operation
class PermissionDeniedFailure extends UserFailure {
  /// Creates a [PermissionDeniedFailure].
  const PermissionDeniedFailure() : super('Permission denied');
}

/// Generic user failure for unexpected errors
class UnknownUserFailure extends UserFailure {
  /// Creates an [UnknownUserFailure] with an optional [customMessage].
  const UnknownUserFailure([String? customMessage])
    : super(customMessage ?? 'An unexpected error occurred');
}
