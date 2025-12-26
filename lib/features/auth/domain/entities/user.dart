import 'package:equatable/equatable.dart';
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
  const User({
    required this.id,
    required this.email,
    required this.createdAt,
    this.emailConfirmed = true,
    this.lastSignInAt,
    this.displayName,
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
      displayName: supabaseUser.userMetadata?['display_name'] as String?,
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

  /// Convert User to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'email_confirmed_at': emailConfirmed ? createdAt.toIso8601String() : null,
      'created_at': createdAt.toIso8601String(),
      'last_sign_in_at': lastSignInAt?.toIso8601String(),
      'display_name': displayName,
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
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      emailConfirmed: emailConfirmed ?? this.emailConfirmed,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      displayName: displayName ?? this.displayName,
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
  ];

  @override
  String toString() {
    return 'User('
        'id: $id, '
        'email: $email, '
        'emailConfirmed: $emailConfirmed, '
        'createdAt: $createdAt, '
        'lastSignInAt: $lastSignInAt, '
        'displayName: $displayName'
        ')';
  }
}
