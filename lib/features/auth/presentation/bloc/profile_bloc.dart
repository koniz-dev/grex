import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/repositories/repositories.dart';
import 'package:grex/features/auth/domain/validators/validators.dart';
import 'package:grex/features/auth/presentation/bloc/profile_event.dart';
import 'package:grex/features/auth/presentation/bloc/profile_state.dart';

/// BLoC for managing user profile state and operations.
///
/// This BLoC handles all profile-related events including
/// loading, updating, and refreshing user profile data.
/// It coordinates between the UI and the user repository.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  /// Creates a ProfileBloc with the required repositories.
  ///
  /// The [userRepository] handles user profile operations.
  /// The [authRepository] provides current user information.
  ProfileBloc({
    required UserRepository userRepository,
    required AuthRepository authRepository,
  }) : _userRepository = userRepository,
       _authRepository = authRepository,
       super(const ProfileInitial()) {
    // Register event handlers
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfileRefreshRequested>(_onProfileRefreshRequested);
  }
  final UserRepository _userRepository;
  final AuthRepository _authRepository;

  /// Handles profile load requests.
  ///
  /// Loads the current user's profile from the repository.
  /// Requires an authenticated user to be present.
  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    // Get current user
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      emit(
        const ProfileError(
          message: 'No authenticated user found',
        ),
      );
      return;
    }

    // Load user profile
    final result = await _userRepository.getUserProfile(currentUser.id);

    result.fold(
      (failure) => emit(
        ProfileError(
          message: _getErrorMessage(failure),
          failure: failure,
        ),
      ),
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }

  /// Handles profile update requests.
  ///
  /// Validates the input data and updates the user profile.
  /// Uses optimistic updates to provide immediate UI feedback.
  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    // Ensure we have a current profile
    final currentState = state;
    if (currentState is! ProfileLoaded &&
        currentState is! ProfileUpdateSuccess) {
      emit(
        const ProfileError(
          message: 'No profile data available for update',
        ),
      );
      return;
    }

    final currentProfile = currentState is ProfileLoaded
        ? currentState.profile
        : (currentState as ProfileUpdateSuccess).profile;

    // Validate input data
    final validationError = _validateUpdateData(event);
    if (validationError != null) {
      emit(
        ProfileError(
          message: validationError,
          profile: currentProfile,
        ),
      );
      return;
    }

    // Create updated profile for optimistic update
    final updatedProfile = currentProfile.copyWith(
      displayName: event.displayName,
      preferredCurrency: event.preferredCurrency,
      languageCode: event.languageCode,
    );

    // Show optimistic update
    emit(
      ProfileUpdating(
        profile: currentProfile,
        updatedProfile: updatedProfile,
      ),
    );

    // Perform actual update
    final result = await _userRepository.updateUserProfile(updatedProfile);

    result.fold(
      (failure) => emit(
        ProfileError(
          message: _getErrorMessage(failure),
          profile: currentProfile,
          failure: failure,
        ),
      ),
      (profile) => emit(ProfileUpdateSuccess(profile: profile)),
    );
  }

  /// Handles profile refresh requests.
  ///
  /// Reloads the profile data from the server, useful for
  /// recovering from errors or getting the latest data.
  Future<void> _onProfileRefreshRequested(
    ProfileRefreshRequested event,
    Emitter<ProfileState> emit,
  ) async {
    // Keep current profile data during refresh if available
    UserProfile? currentProfile;
    if (state is ProfileLoaded) {
      currentProfile = (state as ProfileLoaded).profile;
    } else if (state is ProfileUpdateSuccess) {
      currentProfile = (state as ProfileUpdateSuccess).profile;
    } else if (state is ProfileError) {
      currentProfile = (state as ProfileError).profile;
    }

    emit(const ProfileLoading());

    // Get current user
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      emit(
        ProfileError(
          message: 'No authenticated user found',
          profile: currentProfile,
        ),
      );
      return;
    }

    // Refresh profile data
    final result = await _userRepository.getUserProfile(currentUser.id);

    result.fold(
      (failure) => emit(
        ProfileError(
          message: _getErrorMessage(failure),
          profile: currentProfile,
          failure: failure,
        ),
      ),
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }

  /// Validates profile update data.
  ///
  /// Returns null if all data is valid, or an error message if validation
  /// fails.
  String? _validateUpdateData(ProfileUpdateRequested event) {
    // Validate display name if provided
    if (event.displayName != null) {
      final displayNameError = InputValidators.validateDisplayName(
        event.displayName,
      );
      if (displayNameError != null) {
        return displayNameError;
      }
    }

    // Validate currency code if provided
    if (event.preferredCurrency != null) {
      final currencyError = InputValidators.validateCurrencyCode(
        event.preferredCurrency,
      );
      if (currencyError != null) {
        return currencyError;
      }
    }

    // Validate language code if provided
    if (event.languageCode != null) {
      final languageError = InputValidators.validateLanguageCode(
        event.languageCode,
      );
      if (languageError != null) {
        return languageError;
      }
    }

    // Check if at least one field is being updated
    if (event.displayName == null &&
        event.preferredCurrency == null &&
        event.languageCode == null) {
      return 'No changes to update';
    }

    return null;
  }

  /// Maps user failures to user-friendly error messages.
  String _getErrorMessage(dynamic failure) {
    if (failure is UserFailure) {
      if (failure is UserNotFoundFailure) {
        return 'User profile not found. Please try refreshing.';
      } else if (failure is InvalidUserDataFailure) {
        return failure.message;
      } else if (failure is UserDatabaseFailure) {
        return failure.message;
      } else {
        return failure.message;
      }
    }

    if (failure is ValidationFailure) {
      return failure.message;
    }

    if (failure is AuthFailure) {
      if (failure is NetworkFailure) {
        return 'Network connection failed. Please try again.';
      } else {
        return failure.message;
      }
    }

    return failure.toString();
  }
}
