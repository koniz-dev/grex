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
}
