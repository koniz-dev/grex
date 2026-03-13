import 'package:dartz/dartz.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/failures/user_failure.dart'
    show PermissionDeniedFailure, ProfileCreationFailure;

/// Repository interface for user profile operations.
///
/// This interface defines the contract for user profile-related operations
/// including fetching, creating, and updating user profiles in the database.
/// All methods return `Either<Failure, Success>` for proper error handling.
abstract class UserRepository {
  /// Gets the user profile for the specified user ID.
  ///
  /// Returns [Right<UserProfile>] on successful retrieval.
  /// Returns [Left<UserFailure>] on failure.
  ///
  /// Possible failures:
  /// - [UserNotFoundFailure] if profile doesn't exist
  /// - `NetworkFailure` for connection issues
  /// - [PermissionDeniedFailure] for RLS policy violations
  Future<Either<UserFailure, UserProfile>> getUserProfile(String userId);

  /// Creates a new user profile in the database.
  ///
  /// Returns [Right<UserProfile>] on successful creation.
  /// Returns [Left<UserFailure>] on failure.
  ///
  /// This is typically called after successful user registration
  /// to create the corresponding profile record.
  ///
  /// Possible failures:
  /// - [ProfileCreationFailure] if profile creation fails
  /// - `ValidationFailure` for invalid profile data
  /// - `NetworkFailure` for connection issues
  Future<Either<UserFailure, UserProfile>> createUserProfile(
    UserProfile profile,
  );

  /// Updates an existing user profile.
  ///
  /// Returns [Right<UserProfile>] with updated profile on success.
  /// Returns [Left<UserFailure>] on failure.
  ///
  /// Only the fields present in the profile parameter will be updated.
  /// Uses the profile's ID to identify which record to update.
  ///
  /// Possible failures:
  /// - [UserNotFoundFailure] if profile doesn't exist
  /// - `ValidationFailure` for invalid profile data
  /// - `NetworkFailure` for connection issues
  /// - [PermissionDeniedFailure] for RLS policy violations
  Future<Either<UserFailure, UserProfile>> updateUserProfile(
    UserProfile profile,
  );

  /// Gets the user profile for the specified email address.
  ///
  /// This method is used for account linking scenarios where we need to
  /// check if a user profile already exists with the same email address
  /// as a social login user.
  ///
  /// Returns [Right<UserProfile?>] on successful query:
  /// - Returns the [UserProfile] if a profile exists with the email
  /// - Returns null if no profile exists with the email
  /// Returns [Left<UserFailure>] on failure.
  ///
  /// Possible failures:
  /// - `NetworkFailure` for connection issues
  /// - [PermissionDeniedFailure] for RLS policy violations
  /// - `DatabaseFailure` for database query errors
  Future<Either<UserFailure, UserProfile?>> getUserProfileByEmail(String email);

  /// Creates a new user profile for social login users.
  ///
  /// This method creates a user profile with social provider metadata
  /// for users who sign up through OAuth providers (Google, Apple, etc.).
  ///
  /// Returns [Right<UserProfile>] on successful creation.
  /// Returns [Left<UserFailure>] on failure.
  ///
  /// Parameters:
  /// - [userId]: The user ID from the authentication provider
  /// - [email]: The user's email address
  /// - [displayName]: The user's display name from OAuth provider
  /// - [preferredCurrency]: The user's preferred currency
  /// - [languageCode]: The user's preferred language
  /// - [provider]: The social authentication provider used
  ///
  /// Possible failures:
  /// - [ProfileCreationFailure] if profile creation fails
  /// - `ValidationFailure` for invalid profile data
  /// - `NetworkFailure` for connection issues
  /// - `DatabaseFailure` for duplicate email or other database errors
  Future<Either<UserFailure, UserProfile>> createSocialUserProfile({
    required String userId,
    required String email,
    required String displayName,
    required String preferredCurrency,
    required String languageCode,
    required String provider,
  });
}
