import 'package:equatable/equatable.dart';
import 'package:grex/shared/utils/locale_defaults.dart';

/// User profile entity representing user information stored in the users table
///
/// This entity contains user profile information that can be updated by
/// the user, such as display name, currency preferences, and language
/// settings. This is separate from User which contains core authentication
/// data.
class UserProfile extends Equatable {
  /// Creates a [UserProfile] with the provided profile data.
  ///
  /// All parameters are required:
  /// - [id]: Unique user identifier
  /// - [email]: User's email address
  /// - [displayName]: Display name shown to other users
  /// - [preferredCurrency]: Currency code (ISO 4217)
  /// - [languageCode]: Language code (ISO 639-1)
  /// - [createdAt]: Profile creation timestamp
  /// - [updatedAt]: Last update timestamp
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.preferredCurrency,
    required this.languageCode,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create UserProfile from database JSON response
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      preferredCurrency: json['preferred_currency'] as String,
      languageCode: json['preferred_language'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Create a new UserProfile for user registration
  ///
  /// Sets both [createdAt] and [updatedAt] to the current time.
  factory UserProfile.create({
    required String id,
    required String email,
    required String displayName,
    String? preferredCurrency,
    String? languageCode,
  }) {
    final currency = preferredCurrency ?? LocaleDefaults.currencyCode;
    final language = languageCode ?? LocaleDefaults.languageCode;
    final now = DateTime.now();
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      preferredCurrency: currency,
      languageCode: language,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Unique user identifier (matches Supabase Auth user ID)
  final String id;

  /// User's email address (synced from Supabase Auth)
  final String email;

  /// Display name shown to other users
  final String displayName;

  /// User's preferred currency code (ISO 4217)
  final String preferredCurrency;

  /// User's language code (ISO 639-1)
  final String languageCode;

  /// When the profile was created
  final DateTime createdAt;

  /// When the profile was last updated
  final DateTime updatedAt;

  /// Convert UserProfile to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'preferred_currency': preferredCurrency,
      'preferred_language': languageCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this UserProfile with updated fields.
  ///
  /// Pure data copy — does NOT auto-update [updatedAt]. The caller (or the
  /// backend on a real write) is responsible for setting [updatedAt] when
  /// the change should bump the modification time.
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? preferredCurrency,
    String? languageCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      languageCode: languageCode ?? this.languageCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    preferredCurrency,
    languageCode,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'UserProfile('
        'id: $id, '
        'email: $email, '
        'displayName: $displayName, '
        'preferredCurrency: $preferredCurrency, '
        'languageCode: $languageCode, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
