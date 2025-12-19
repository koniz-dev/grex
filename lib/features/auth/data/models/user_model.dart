import 'package:grex/features/auth/domain/entities/user.dart';

/// Data model for user, extends User entity.
///
/// This model is used for JSON serialization/deserialization in the data layer.
/// It extends the domain User entity and provides methods for converting
/// between JSON and the domain entity.
class UserModel extends User {
  /// Creates a [UserModel] with the given parameters
  const UserModel({
    required super.id,
    required super.email,
    required super.createdAt,
    super.emailConfirmed,
    super.lastSignInAt,
  });

  /// Creates a [UserModel] from a [User] entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      emailConfirmed: user.emailConfirmed,
      createdAt: user.createdAt,
      lastSignInAt: user.lastSignInAt,
    );
  }

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      emailConfirmed: json['email_confirmed_at'] != null,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastSignInAt: json['last_sign_in_at'] != null
          ? DateTime.parse(json['last_sign_in_at'] as String)
          : null,
    );
  }

  /// Convert UserModel to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'email_confirmed_at': emailConfirmed ? createdAt.toIso8601String() : null,
      'created_at': createdAt.toIso8601String(),
      'last_sign_in_at': lastSignInAt?.toIso8601String(),
    };
  }

  /// Convert UserModel to User entity
  ///
  /// Since UserModel extends User, this method simply returns this instance
  /// cast to User. It's provided for consistency with the model pattern.
  User toEntity() {
    return User(
      id: id,
      email: email,
      emailConfirmed: emailConfirmed,
      createdAt: createdAt,
      lastSignInAt: lastSignInAt,
    );
  }
}
