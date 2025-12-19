import 'package:equatable/equatable.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';

/// Base class for all profile-related states.
///
/// All profile states extend this class to provide consistent
/// state management throughout the profile management feature.
abstract class ProfileState extends Equatable {
  /// Creates a [ProfileState].
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the ProfileBloc is first created.
///
/// This is the default state before any profile operations
/// have been performed.
class ProfileInitial extends ProfileState {
  /// Creates a [ProfileInitial] state.
  const ProfileInitial();

  @override
  String toString() => 'ProfileInitial()';
}

/// State indicating that a profile operation is in progress.
///
/// This state is used during profile loading, updating, or refreshing
/// operations to show loading indicators in the UI.
class ProfileLoading extends ProfileState {
  /// Creates a [ProfileLoading] state.
  const ProfileLoading();

  @override
  String toString() => 'ProfileLoading()';
}

/// State indicating that the profile has been successfully loaded.
///
/// This state contains the current user profile data that can be
/// displayed in the UI.
class ProfileLoaded extends ProfileState {
  /// Creates a [ProfileLoaded] state with the provided profile.
  ///
  /// The [profile] is required and contains the loaded user profile data.
  const ProfileLoaded({
    required this.profile,
  });

  /// The loaded user profile
  final UserProfile profile;

  @override
  List<Object?> get props => [profile];

  @override
  String toString() => 'ProfileLoaded(profile: $profile)';
}

/// State indicating that a profile update is in progress.
///
/// This state maintains the current profile data while showing
/// that an update operation is ongoing. This allows for optimistic
/// updates in the UI.
class ProfileUpdating extends ProfileState {
  /// Creates a [ProfileUpdating] state with current and updated profiles.
  ///
  /// The [profile] is the current profile data. The [updatedProfile]
  /// contains the changes being saved for optimistic UI updates.
  const ProfileUpdating({
    required this.profile,
    required this.updatedProfile,
  });

  /// The current profile data
  final UserProfile profile;

  /// The updated data being saved (for optimistic updates)
  final UserProfile updatedProfile;

  @override
  List<Object?> get props => [profile, updatedProfile];

  @override
  String toString() =>
      'ProfileUpdating(profile: $profile, updatedProfile: $updatedProfile)';
}

/// State indicating that the profile has been successfully updated.
///
/// This state contains the updated profile data after a successful
/// update operation.
class ProfileUpdateSuccess extends ProfileState {
  /// Creates a [ProfileUpdateSuccess] state with the updated profile.
  ///
  /// The [profile] is the successfully updated user profile data.
  const ProfileUpdateSuccess({
    required this.profile,
  });

  /// The updated user profile
  final UserProfile profile;

  @override
  List<Object?> get props => [profile];

  @override
  String toString() => 'ProfileUpdateSuccess(profile: $profile)';
}

/// State indicating that a profile operation has failed.
///
/// This state contains error information that can be displayed
/// to the user, along with the last known profile data if available.
class ProfileError extends ProfileState {
  /// Creates a [ProfileError] state with error information.
  ///
  /// The [message] is required. The [profile] and [failure] are optional
  /// and provide context for error recovery.
  const ProfileError({
    required this.message,
    this.profile,
    this.failure,
  });

  /// Human-readable error message
  final String message;

  /// The last known profile data (null if never loaded)
  final UserProfile? profile;

  /// The underlying failure object for detailed error handling
  final dynamic failure;

  @override
  List<Object?> get props => [message, profile, failure];

  @override
  String toString() =>
      'ProfileError(message: $message, profile: $profile, failure: $failure)';
}
