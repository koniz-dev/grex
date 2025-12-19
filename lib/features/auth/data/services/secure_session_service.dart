import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/repositories/user_repository.dart';
import 'package:grex/features/auth/domain/services/session_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

/// Secure implementation of session service using Flutter Secure Storage
///
/// This implementation stores session data in encrypted local storage
/// and handles automatic token refresh and session validation.
class SecureSessionService implements SessionService {
  /// Creates a [SecureSessionService] with the provided configuration.
  ///
  /// The [secureStorage], [supabaseClient], and [userRepository] are required.
  const SecureSessionService({
    required FlutterSecureStorage secureStorage,
    required SupabaseClient supabaseClient,
    required UserRepository userRepository,
  }) : _secureStorage = secureStorage,
       _supabaseClient = supabaseClient,
       _userRepository = userRepository;
  static const String _sessionKey = 'grex_session_data';
  static const String _lastValidationKey = 'grex_last_validation';

  final FlutterSecureStorage _secureStorage;
  final SupabaseClient _supabaseClient;
  final UserRepository _userRepository;

  @override
  Future<Either<AuthFailure, void>> storeSession({
    required String accessToken,
    required String refreshToken,
    required User user,
    required UserProfile userProfile,
  }) async {
    try {
      // Calculate token expiry times (Supabase tokens typically expire
      // in 1 hour)
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 1));
      final refreshExpiresAt = now.add(const Duration(days: 30));

      final sessionData = SessionData(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user,
        userProfile: userProfile,
        expiresAt: expiresAt,
        refreshExpiresAt: refreshExpiresAt,
      );

      // Store session data securely
      await _secureStorage.write(
        key: _sessionKey,
        value: jsonEncode(sessionData.toJson()),
      );

      // Store last validation time
      await _secureStorage.write(
        key: _lastValidationKey,
        value: now.toIso8601String(),
      );

      return const Right(null);
    } on Object catch (e) {
      return Left(GenericAuthFailure('Failed to store session: $e'));
    }
  }

  @override
  Future<Either<AuthFailure, SessionData?>> getStoredSession() async {
    try {
      final sessionJson = await _secureStorage.read(key: _sessionKey);

      if (sessionJson == null) {
        return const Right(null);
      }

      final sessionMap = jsonDecode(sessionJson) as Map<String, dynamic>;
      final sessionData = SessionData.fromJson(sessionMap);

      // Check if session is completely expired
      if (sessionData.isExpired) {
        // Clear expired session
        await clearSession();
        return const Right(null);
      }

      return Right(sessionData);
    } on Object catch (e) {
      // If we can't parse stored session, clear it
      await clearSession();
      return Left(GenericAuthFailure('Failed to retrieve session: $e'));
    }
  }

  @override
  Future<Either<AuthFailure, bool>> validateSession() async {
    try {
      final sessionResult = await getStoredSession();

      return sessionResult.fold(
        Left.new,
        (sessionData) async {
          if (sessionData == null) {
            return const Right(false);
          }

          // Check if session is expired
          if (sessionData.isExpired) {
            await clearSession();
            return const Right(false);
          }

          // Check with Supabase if user still exists and is active
          final currentUser = _supabaseClient.auth.currentUser;
          if (currentUser == null || currentUser.id != sessionData.user.id) {
            await clearSession();
            return const Right(false);
          }

          // Validate user profile still exists
          final profileResult = await _userRepository.getUserProfile(
            sessionData.user.id,
          );
          return profileResult.fold(
            (failure) async {
              // If profile doesn't exist, session is invalid
              await clearSession();
              return const Right(false);
            },
            (profile) async {
              // Update last validation time
              await _secureStorage.write(
                key: _lastValidationKey,
                value: DateTime.now().toIso8601String(),
              );
              return const Right(true);
            },
          );
        },
      );
    } on Object catch (e) {
      return Left(GenericAuthFailure('Session validation failed: $e'));
    }
  }

  @override
  Future<Either<AuthFailure, SessionData>> refreshSession() async {
    try {
      final sessionResult = await getStoredSession();

      return await sessionResult.fold(
        (failure) async => Left(failure),
        (sessionData) async {
          if (sessionData == null) {
            return const Left(GenericAuthFailure('No session to refresh'));
          }

          if (sessionData.isRefreshTokenExpired) {
            await clearSession();
            return const Left(GenericAuthFailure('No session to refresh'));
          }

          // Use Supabase to refresh the session
          final response = await _supabaseClient.auth.refreshSession();

          if (response.session == null) {
            await clearSession();
            return const Left(
              GenericAuthFailure('Failed to refresh session'),
            );
          }

          final session = response.session!;
          final user = User.fromSupabaseUser(session.user);

          // Get updated user profile
          final profileResult = await _userRepository.getUserProfile(user.id);

          return await profileResult.fold(
            (failure) async => Left(GenericAuthFailure(failure.message)),
            (userProfile) async {
              // Store refreshed session
              final storeResult = await storeSession(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken ?? sessionData.refreshToken,
                user: user,
                userProfile: userProfile,
              );

              return storeResult.fold(
                Left.new,
                (_) async {
                  final newSessionResult = await getStoredSession();
                  return newSessionResult.fold(
                    Left.new,
                    (newSession) => newSession != null
                        ? Right(newSession)
                        : const Left(
                            GenericAuthFailure(
                              'Failed to retrieve refreshed session',
                            ),
                          ),
                  );
                },
              );
            },
          );
        },
      );
    } on Object catch (e) {
      return Left(GenericAuthFailure('Session refresh failed: $e'));
    }
  }

  @override
  Future<Either<AuthFailure, void>> clearSession() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: _sessionKey),
        _secureStorage.delete(key: _lastValidationKey),
      ]);

      return const Right(null);
    } on Object catch (e) {
      return Left(GenericAuthFailure('Failed to clear session: $e'));
    }
  }

  @override
  Future<bool> hasStoredSession() async {
    try {
      final sessionJson = await _secureStorage.read(key: _sessionKey);
      return sessionJson != null;
    } on Object catch (_) {
      return false;
    }
  }

  @override
  Future<DateTime?> getSessionExpiry() async {
    try {
      final sessionResult = await getStoredSession();
      return sessionResult.fold(
        (failure) => null,
        (sessionData) => sessionData?.expiresAt,
      );
    } on Object catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isSessionExpired() async {
    try {
      final sessionResult = await getStoredSession();
      return sessionResult.fold(
        (failure) => true,
        (sessionData) => sessionData?.isExpired ?? true,
      );
    } on Object catch (_) {
      return true;
    }
  }

  /// Check if session needs refresh (access token expires soon)
  Future<bool> needsRefresh() async {
    try {
      final sessionResult = await getStoredSession();
      return sessionResult.fold(
        (failure) => false,
        (sessionData) => sessionData?.needsRefresh ?? false,
      );
    } on Object catch (_) {
      return false;
    }
  }

  /// Get time since last validation
  Future<Duration?> getTimeSinceLastValidation() async {
    try {
      final lastValidationString = await _secureStorage.read(
        key: _lastValidationKey,
      );
      if (lastValidationString == null) return null;

      final lastValidation = DateTime.parse(lastValidationString);
      return DateTime.now().difference(lastValidation);
    } on Object catch (_) {
      return null;
    }
  }
}
