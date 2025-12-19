import 'package:equatable/equatable.dart';

/// Base class for all profile-related events.
///
/// All profile events extend this class to provide consistent
/// event handling throughout the profile management feature.
abstract class ProfileEvent extends Equatable {
  /// Creates a [ProfileEvent].
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Event to request loading of the current user's profile.
///
/// This event is typically triggered when the profile screen is opened
/// or when the profile data needs to be refreshed.
class ProfileLoadRequested extends ProfileEvent {
  /// Creates a [ProfileLoadRequested] event.
  const ProfileLoadRequested();

  @override
  String toString() => 'ProfileLoadRequested()';
}

/// Event to request updating the user's profile information.
///
/// This event contains the updated profile data that should be saved
/// to the database. Only non-null fields will be updated.
class ProfileUpdateRequested extends ProfileEvent {
  /// Creates a [ProfileUpdateRequested] event with the profile updates.
  ///
  /// All parameters are optional. Only non-null fields will be updated.
  const ProfileUpdateRequested({
    this.displayName,
    this.preferredCurrency,
    this.languageCode,
  });

  /// Updated display name (null means no change)
  final String? displayName;

  /// Updated preferred currency code (null means no change)
  final String? preferredCurrency;

  /// Updated language code (null means no change)
  final String? languageCode;

  @override
  List<Object?> get props => [
    displayName,
    preferredCurrency,
    languageCode,
  ];

  @override
  String toString() {
    return 'ProfileUpdateRequested('
        'displayName: $displayName, '
        'preferredCurrency: $preferredCurrency, '
        'languageCode: $languageCode'
        ')';
  }
}

/// Event to refresh the profile data from the server.
///
/// This is useful when the profile might have been updated
/// externally or when recovering from an error state.
class ProfileRefreshRequested extends ProfileEvent {
  /// Creates a [ProfileRefreshRequested] event.
  const ProfileRefreshRequested();

  @override
  String toString() => 'ProfileRefreshRequested()';
}
