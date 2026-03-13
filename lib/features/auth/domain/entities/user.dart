import 'package:equatable/equatable.dart';
import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// User entity representing authenticated user from Supabase Auth
///
/// This entity contains core authentication information managed by
/// Supabase Auth. For profile information (display name, preferences),
/// see UserProfile entity.
class User extends Equatable {
  /// Creates a [User] with the provided authentication data.
  ///
  /// Required parameters:
  /// - [id]: Unique user identifier
  /// - [email]: User's email address
  /// - [createdAt]: Account creation timestamp
  ///
  /// Optional parameters:
  /// - [emailConfirmed]: Whether email is verified (default: true)
  /// - [lastSignInAt]: Last sign-in timestamp
  /// - [displayName]: User's display name from metadata
  /// - [appMetadata]: Application metadata from Supabase
  /// - [userMetadata]: User metadata from Supabase
  const User({
    required this.id,
    required this.email,
    required this.createdAt,
    this.emailConfirmed = true,
    this.lastSignInAt,
    this.displayName,
    this.appMetadata,
    this.userMetadata,
  });

  /// Create User from Supabase Auth JSON response
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      emailConfirmed: json['email_confirmed_at'] != null,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastSignInAt: json['last_sign_in_at'] != null
          ? DateTime.parse(json['last_sign_in_at'] as String)
          : null,
      displayName: json['display_name'] as String?,
      appMetadata: json['app_metadata'] as Map<String, dynamic>?,
      userMetadata: json['user_metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create User from Supabase User object
  factory User.fromSupabaseUser(supabase.User supabaseUser) {
    return User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      emailConfirmed: supabaseUser.emailConfirmedAt != null,
      createdAt: DateTime.parse(supabaseUser.createdAt),
      lastSignInAt: supabaseUser.lastSignInAt != null
          ? DateTime.parse(supabaseUser.lastSignInAt!)
          : null,
      displayName:
          supabaseUser.userMetadata?['display_name'] as String? ??
          supabaseUser.userMetadata?['full_name'] as String? ??
          supabaseUser.userMetadata?['name'] as String?,
      appMetadata: supabaseUser.appMetadata,
      userMetadata: supabaseUser.userMetadata,
    );
  }

  /// Unique user identifier from Supabase Auth
  final String id;

  /// User's email address
  final String email;

  /// Whether the user's email has been confirmed
  final bool emailConfirmed;

  /// When the user account was created
  final DateTime createdAt;

  /// When the user last signed in (null if never signed in)
  final DateTime? lastSignInAt;

  /// User's display name from metadata
  final String? displayName;

  /// Application metadata from Supabase (contains provider info, etc.)
  final Map<String, dynamic>? appMetadata;

  /// User metadata from Supabase (contains OAuth profile data)
  final Map<String, dynamic>? userMetadata;

  /// Extract social provider from user app metadata
  /// Returns the OAuth provider if user signed in with social auth
  SocialAuthProvider? get socialProvider {
    final providers = appMetadata?['providers'] as List<dynamic>?;
    if (providers == null || providers.isEmpty) return null;

    if (providers.contains('google')) {
      return SocialAuthProvider.google;
    } else if (providers.contains('apple')) {
      return SocialAuthProvider.apple;
    }
    return null;
  }

  /// Get display name from OAuth provider metadata
  /// Attempts to extract name from various OAuth metadata fields
  String? get oauthDisplayName {
    return userMetadata?['full_name'] as String? ??
        userMetadata?['name'] as String? ??
        userMetadata?['display_name'] as String?;
  }

  /// Convert User to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'email_confirmed_at': emailConfirmed ? createdAt.toIso8601String() : null,
      'created_at': createdAt.toIso8601String(),
      'last_sign_in_at': lastSignInAt?.toIso8601String(),
      'display_name': displayName,
      'app_metadata': appMetadata,
      'user_metadata': userMetadata,
    };
  }

  /// Create a copy of this User with updated fields
  User copyWith({
    String? id,
    String? email,
    bool? emailConfirmed,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    String? displayName,
    Map<String, dynamic>? appMetadata,
    Map<String, dynamic>? userMetadata,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      emailConfirmed: emailConfirmed ?? this.emailConfirmed,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      displayName: displayName ?? this.displayName,
      appMetadata: appMetadata ?? this.appMetadata,
      userMetadata: userMetadata ?? this.userMetadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    emailConfirmed,
    createdAt,
    lastSignInAt,
    displayName,
    appMetadata,
    userMetadata,
  ];

  @override
  String toString() {
    return 'User('
        'id: $id, '
        'email: $email, '
        'emailConfirmed: $emailConfirmed, '
        'createdAt: $createdAt, '
        'lastSignInAt: $lastSignInAt, '
        'displayName: $displayName, '
        'socialProvider: $socialProvider'
        ')';
  }
}
