import 'package:grex/features/auth/data/models/user_model.dart';

/// Data model for authentication response from API.
///
/// This model represents the response structure from authentication endpoints
/// (login, register, refresh token) and contains the user data and tokens.
class AuthResponseModel {
  /// Creates an [AuthResponseModel] with the given parameters
  const AuthResponseModel({
    required this.user,
    required this.token,
    this.refreshToken,
  });

  /// Create AuthResponseModel from JSON
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
      refreshToken: json['refresh_token'] as String?,
    );
  }

  /// User data from the authentication response
  final UserModel user;

  /// Access token for authenticated requests
  final String token;

  /// Refresh token for obtaining new access tokens (optional)
  final String? refreshToken;

  /// Convert AuthResponseModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      if (refreshToken != null) 'refresh_token': refreshToken,
    };
  }
}
