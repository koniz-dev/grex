import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'package:grex/features/auth/domain/entities/entities.dart';

/// Abstract session service for managing authentication sessions
///
/// This service handles session persistence, validation, refresh, and cleanup
/// across app restarts and device changes.
abstract class SessionService {
  /// Store session data securely
  ///
  /// Stores authentication tokens and user data in secure storage
  /// for persistence across app restarts.
  Future<Either<AuthFailure, void>> storeSession({
    required String accessToken,
    required String refreshToken,
    required User user,
    required UserProfile userProfile,
  });

  /// Retrieve stored session data
  ///
  /// Returns stored session data if available and valid,
  /// otherwise returns null.
  Future<Either<AuthFailure, SessionData?>> getStoredSession();

  /// Validate current session
  ///
  /// Checks if the current session is still valid by verifying
  /// token expiration and user status.
  Future<Either<AuthFailure, bool>> validateSession();

  /// Refresh session tokens
  ///
  /// Uses refresh token to obtain new access token and
  /// updates stored session data.
  Future<Either<AuthFailure, SessionData>> refreshSession();

  /// Clear all session data
  ///
  /// Removes all stored authentication data from secure storage.
  /// Used during logout and session cleanup.
  Future<Either<AuthFailure, void>> clearSession();

  /// Check if session exists
  ///
  /// Quick check to see if any session data is stored
  /// without loading the full session.
  Future<bool> hasStoredSession();

  /// Get session expiry time
  ///
  /// Returns when the current session will expire,
  /// or null if no session exists.
  Future<DateTime?> getSessionExpiry();

  /// Check if session is expired
  ///
  /// Returns true if the current session has expired
  /// and needs to be refreshed or cleared.
  Future<bool> isSessionExpired();
}

/// Session data container
///
/// Contains all data needed to maintain an authenticated session
/// including tokens, user information, and expiry times.
@immutable
class SessionData {
  /// Creates a [SessionData] with the provided session information.
  ///
  /// All parameters are required:
  /// - [accessToken]: JWT access token for API authentication
  /// - [refreshToken]: Token for refreshing the access token
  /// - [user]: Authenticated user entity
  /// - [userProfile]: User profile information
  /// - [expiresAt]: When the access token expires
  /// - [refreshExpiresAt]: When the refresh token expires
  const SessionData({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.userProfile,
    required this.expiresAt,
    required this.refreshExpiresAt,
  });

  /// Create from JSON storage
  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      userProfile: UserProfile.fromJson(
        json['userProfile'] as Map<String, dynamic>,
      ),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      refreshExpiresAt: DateTime.parse(json['refreshExpiresAt'] as String),
    );
  }

  /// JWT access token for API authentication
  final String accessToken;

  /// Token for refreshing the access token
  final String refreshToken;

  /// Authenticated user entity
  final User user;

  /// User profile information
  final UserProfile userProfile;

  /// When the access token expires
  final DateTime expiresAt;

  /// When the refresh token expires
  final DateTime refreshExpiresAt;

  /// Check if access token is expired
  bool get isAccessTokenExpired => DateTime.now().isAfter(expiresAt);

  /// Check if refresh token is expired
  bool get isRefreshTokenExpired => DateTime.now().isAfter(refreshExpiresAt);

  /// Check if session is completely expired
  bool get isExpired => isRefreshTokenExpired;

  /// Check if access token needs refresh (expires within 5 minutes)
  bool get needsRefresh =>
      DateTime.now().add(const Duration(minutes: 5)).isAfter(expiresAt);

  /// Create copy with updated tokens
  SessionData copyWith({
    String? accessToken,
    String? refreshToken,
    User? user,
    UserProfile? userProfile,
    DateTime? expiresAt,
    DateTime? refreshExpiresAt,
  }) {
    return SessionData(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
      userProfile: userProfile ?? this.userProfile,
      expiresAt: expiresAt ?? this.expiresAt,
      refreshExpiresAt: refreshExpiresAt ?? this.refreshExpiresAt,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user.toJson(),
      'userProfile': userProfile.toJson(),
      'expiresAt': expiresAt.toIso8601String(),
      'refreshExpiresAt': refreshExpiresAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionData &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.user == user &&
        other.userProfile == userProfile &&
        other.expiresAt == expiresAt &&
        other.refreshExpiresAt == refreshExpiresAt;
  }

  @override
  int get hashCode {
    return accessToken.hashCode ^
        refreshToken.hashCode ^
        user.hashCode ^
        userProfile.hashCode ^
        expiresAt.hashCode ^
        refreshExpiresAt.hashCode;
  }

  @override
  String toString() {
    return 'SessionData(user: ${user.email}, expiresAt: $expiresAt, '
        'needsRefresh: $needsRefresh)';
  }
}
