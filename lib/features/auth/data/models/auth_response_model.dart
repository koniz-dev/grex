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
    final session = json['session'] as Map<String, dynamic>?;
    final userJson =
        (json['user'] ?? session?['user']) as Map<String, dynamic>?;

    if (userJson == null) {
      throw Exception('User data not found in auth response');
    }

    // Handle both app-specific 'token' and Supabase-native 'access_token'
    final token =
        (json['token'] ?? session?['access_token'] ?? json['access_token'])
            as String? ??
        '';
    final refreshToken =
        (json['refresh_token'] ?? session?['refresh_token']) as String?;

    return AuthResponseModel(
      user: UserModel.fromJson(userJson),
      token: token,
      refreshToken: refreshToken,
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
