import 'package:equatable/equatable.dart';

import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';

/// Data model for profile setup after social login
///
/// Contains the information needed to create a user profile
/// for a new social login user.
class ProfileSetupData extends Equatable {
  /// Creates a [ProfileSetupData] with the provided information.
  ///
  /// Required parameters:
  /// - [displayName]: User's display name
  /// - [preferredCurrency]: User's preferred currency code
  /// - [languageCode]: User's preferred language code
  ///
  /// Optional parameters:
  /// - [socialProvider]: The OAuth provider used for authentication
  const ProfileSetupData({
    required this.displayName,
    required this.preferredCurrency,
    required this.languageCode,
    this.socialProvider,
  });

  /// Create from JSON response
  factory ProfileSetupData.fromJson(Map<String, dynamic> json) {
    return ProfileSetupData(
      displayName: json['display_name'] as String,
      preferredCurrency: json['preferred_currency'] as String,
      languageCode: json['language_code'] as String,
      socialProvider: json['social_provider'] != null
          ? SocialAuthProvider.fromString(json['social_provider'] as String)
          : null,
    );
  }

  /// User's display name
  final String displayName;

  /// User's preferred currency code (e.g., 'VND', 'USD')
  final String preferredCurrency;

  /// User's preferred language code (e.g., 'vi', 'en')
  final String languageCode;

  /// The social authentication provider used (if applicable)
  final SocialAuthProvider? socialProvider;

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'preferred_currency': preferredCurrency,
      'language_code': languageCode,
      if (socialProvider != null) 'social_provider': socialProvider!.name,
    };
  }

  /// Create a copy with updated fields
  ProfileSetupData copyWith({
    String? displayName,
    String? preferredCurrency,
    String? languageCode,
    SocialAuthProvider? socialProvider,
  }) {
    return ProfileSetupData(
      displayName: displayName ?? this.displayName,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      languageCode: languageCode ?? this.languageCode,
      socialProvider: socialProvider ?? this.socialProvider,
    );
  }

  @override
  List<Object?> get props => [
    displayName,
    preferredCurrency,
    languageCode,
    socialProvider,
  ];

  @override
  String toString() {
    return 'ProfileSetupData('
        'displayName: $displayName, '
        'preferredCurrency: $preferredCurrency, '
        'languageCode: $languageCode, '
        'socialProvider: $socialProvider'
        ')';
  }

  /// Validate display name
  /// Returns error message if invalid, null if valid
  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name is required';
    }
    if (value.trim().length < 2) {
      return 'Display name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Display name must be less than 50 characters';
    }
    return null;
  }

  /// Validate currency selection
  /// Returns error message if invalid, null if valid
  static String? validateCurrency(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a currency';
    }
    return null;
  }

  /// Validate language selection
  /// Returns error message if invalid, null if valid
  static String? validateLanguage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a language';
    }
    return null;
  }

  /// Validate all fields and return true if valid
  /// Returns a map of field names to error messages for invalid fields
  Map<String, String> validate() {
    final errors = <String, String>{};

    final displayNameError = validateDisplayName(displayName);
    if (displayNameError != null) {
      errors['displayName'] = displayNameError;
    }

    final currencyError = validateCurrency(preferredCurrency);
    if (currencyError != null) {
      errors['preferredCurrency'] = currencyError;
    }

    final languageError = validateLanguage(languageCode);
    if (languageError != null) {
      errors['languageCode'] = languageError;
    }

    return errors;
  }

  /// Check if all fields are valid
  bool get isValid => validate().isEmpty;
}
