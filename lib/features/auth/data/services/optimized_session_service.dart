import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grex/core/constants/app_constants.dart';
import 'package:grex/core/performance/performance_service.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/repositories/user_repository.dart';
import 'package:grex/features/auth/domain/services/session_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

/// Optimized session service with lazy loading and caching
///
/// This implementation provides performance optimizations for session
/// management:
/// - Lazy loading for user profile data
/// - In-memory caching of profile data after first load
/// - Optimized session refresh timing
/// - Performance monitoring for all operations
///
/// Requirements: 7.1, 7.2, 7.6
class OptimizedSessionService implements SessionService {
  /// Creates an [OptimizedSessionService] with the provided configuration.
  OptimizedSessionService({
    required FlutterSecureStorage secureStorage,
    required SupabaseClient supabaseClient,
    required UserRepository userRepository,
    required PerformanceService performanceService,
  }) : _secureStorage = secureStorage,
       _supabaseClient = supabaseClient,
       _userRepository = userRepository,
       _performanceService = performanceService;

  static const String _sessionKey = 'grex_session_data';
  static const String _lastValidationKey = 'grex_last_validation';
  static const String _profileCacheKey = 'grex_profile_cache';
  static const String _profileCacheTimestampKey =
      'grex_profile_cache_timestamp';

  final FlutterSecureStorage _secureStorage;
  final SupabaseClient _supabaseClient;
  final UserRepository _userRepository;
  final PerformanceService _performanceService;

  // In-memory cache for profile data
  UserProfile? _cachedProfile;
  DateTime? _profileCacheTime;

  // Cache duration - profile data cached for 5 minutes
  static const Duration _profileCacheDuration = Duration(minutes: 5);

  // Session refresh threshold - refresh when 10 minutes remain
  static const Duration _refreshThreshold = Duration(minutes: 10);

  @override
  Future<Either<AuthFailure, void>> storeSession({
    required String accessToken,
    required String refreshToken,
    required User user,
    required UserProfile userProfile,
  }) async {
    return _performanceService.measureOperation(
      name: 'session_store',
      operation: () => _storeSessionOptimized(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user,
        userProfile: userProfile,
      ),
    );
  }

  Future<Either<AuthFailure, void>> _storeSessionOptimized({
    required String accessToken,
    required String refreshToken,
    required User user,
    required UserProfile userProfile,
  }) async {
    try {
      // Calculate token expiry times (Supabase tokens typically last 1 hour)
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

      // Store session data and cache profile in parallel for better performance
      await Future.wait([
        _secureStorage.write(
          key: _sessionKey,
          value: jsonEncode(sessionData.toJson()),
        ),
        _secureStorage.write(
          key: _lastValidationKey,
          value: now.toIso8601String(),
        ),
        // Cache profile data for faster subsequent access
        _cacheProfileData(userProfile),
      ]);

      // Update in-memory cache
      _cachedProfile = userProfile;
      _profileCacheTime = now;

      debugPrint('Session stored with profile cache updated');
      return const Right(null);
    } on Object catch (e) {
      return Left(GenericAuthFailure('Failed to store session: $e'));
    }
  }

  @override
  Future<Either<AuthFailure, SessionData?>> getStoredSession() async {
    return _performanceService.measureOperation(
      name: 'session_get',
      operation: _getStoredSessionOptimized,
    );
  }

  Future<Either<AuthFailure, SessionData?>> _getStoredSessionOptimized() async {
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

      // Load cached profile if available and valid
      if (_cachedProfile == null || _isProfileCacheExpired()) {
        await _loadCachedProfile(sessionData.user.id);
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
    return _performanceService.measureOperation(
      name: 'session_validate',
      operation: _validateSessionOptimized,
    );
  }

  Future<Either<AuthFailure, bool>> _validateSessionOptimized() async {
    try {
      final sessionResult = await getStoredSession();

      return await sessionResult.fold(
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

          // Use cached profile if available, otherwise validate with repository
          if (_cachedProfile != null && !_isProfileCacheExpired()) {
            // Update last validation time
            await _secureStorage.write(
              key: _lastValidationKey,
              value: DateTime.now().toIso8601String(),
            );
            return const Right(true);
          }

          // Validate user profile still exists (lazy loading)
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
              // Cache the profile for future use
              _cachedProfile = profile;
              _profileCacheTime = DateTime.now();
              await _cacheProfileData(profile);

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
    return _performanceService.measureOperation(
      name: 'session_refresh',
      operation: _refreshSessionOptimized,
    );
  }

  Future<Either<AuthFailure, SessionData>> _refreshSessionOptimized() async {
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

          // Use cached profile if available, otherwise fetch from repository
          UserProfile userProfile;
          if (_cachedProfile != null && !_isProfileCacheExpired()) {
            userProfile = _cachedProfile!;
            debugPrint('Using cached profile for session refresh');
          } else {
            final profileResult = await _userRepository.getUserProfile(user.id);
            userProfile = await profileResult.fold(
              (failure) async => throw Exception(failure.message),
              (profile) async {
                // Update cache
                _cachedProfile = profile;
                _profileCacheTime = DateTime.now();
                await _cacheProfileData(profile);
                return profile;
              },
            );
          }

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
    } on Object catch (e) {
      return Left(GenericAuthFailure('Session refresh failed: $e'));
    }
  }

  @override
  Future<Either<AuthFailure, void>> clearSession() async {
    return _performanceService.measureOperation(
      name: 'session_clear',
      operation: _clearSessionOptimized,
    );
  }

  Future<Either<AuthFailure, void>> _clearSessionOptimized() async {
    try {
      // Clear all session data in parallel
      await Future.wait([
        _secureStorage.delete(key: _sessionKey),
        _secureStorage.delete(key: _lastValidationKey),
        _secureStorage.delete(key: AppConstants.tokenKey),
        _secureStorage.delete(key: AppConstants.refreshTokenKey),
        _secureStorage.delete(key: _profileCacheKey),
        _secureStorage.delete(key: _profileCacheTimestampKey),
      ]);

      // Clear in-memory cache
      _cachedProfile = null;
      _profileCacheTime = null;

      debugPrint('Session and profile cache cleared');
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
      return await sessionResult.fold(
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
      return await sessionResult.fold(
        (failure) => true,
        (sessionData) => sessionData?.isExpired ?? true,
      );
    } on Object catch (_) {
      return true;
    }
  }

  /// Check if session needs refresh (optimized timing)
  ///
  /// Refreshes when 10 minutes remain instead of waiting until expiry
  Future<bool> needsRefresh() async {
    try {
      final sessionResult = await getStoredSession();
      return await sessionResult.fold(
        (failure) => false,
        (sessionData) {
          if (sessionData == null) return false;

          final now = DateTime.now();
          final timeUntilExpiry = sessionData.expiresAt.difference(now);

          // Refresh if less than 10 minutes remain
          return timeUntilExpiry <= _refreshThreshold;
        },
      );
    } on Object catch (_) {
      return false;
    }
  }

  /// Get cached user profile (lazy loading)
  ///
  /// Returns cached profile if available and valid, otherwise loads from
  /// storage
  Future<UserProfile?> getCachedProfile(String userId) async {
    return _performanceService.measureOperation(
      name: 'profile_get_cached',
      operation: () => _getCachedProfileOptimized(userId),
    );
  }

  Future<UserProfile?> _getCachedProfileOptimized(String userId) async {
    // Return in-memory cache if valid
    if (_cachedProfile != null && !_isProfileCacheExpired()) {
      debugPrint('Returning in-memory cached profile');
      return _cachedProfile;
    }

    // Load from secure storage cache
    await _loadCachedProfile(userId);
    return _cachedProfile;
  }

  /// Cache profile data to secure storage
  Future<void> _cacheProfileData(UserProfile profile) async {
    try {
      await Future.wait([
        _secureStorage.write(
          key: _profileCacheKey,
          value: jsonEncode(profile.toJson()),
        ),
        _secureStorage.write(
          key: _profileCacheTimestampKey,
          value: DateTime.now().toIso8601String(),
        ),
      ]);
    } on Object catch (e) {
      debugPrint('Failed to cache profile data: $e');
      // Don't throw - caching is optional optimization
    }
  }

  /// Load cached profile from secure storage
  Future<void> _loadCachedProfile(String userId) async {
    try {
      final cachedProfileJson = await _secureStorage.read(
        key: _profileCacheKey,
      );
      final cacheTimestampString = await _secureStorage.read(
        key: _profileCacheTimestampKey,
      );

      if (cachedProfileJson != null && cacheTimestampString != null) {
        final cacheTimestamp = DateTime.parse(cacheTimestampString);
        final cacheAge = DateTime.now().difference(cacheTimestamp);

        if (cacheAge <= _profileCacheDuration) {
          final profileMap =
              jsonDecode(cachedProfileJson) as Map<String, dynamic>;
          final profile = UserProfile.fromJson(profileMap);

          // Verify the cached profile belongs to the current user
          if (profile.id == userId) {
            _cachedProfile = profile;
            _profileCacheTime = cacheTimestamp;
            debugPrint(
              'Loaded cached profile from storage '
              '(age: ${cacheAge.inMinutes}m)',
            );
            return;
          }
        }
      }

      // Clear invalid cache
      await Future.wait([
        _secureStorage.delete(key: _profileCacheKey),
        _secureStorage.delete(key: _profileCacheTimestampKey),
      ]);
    } on Object catch (e) {
      debugPrint('Failed to load cached profile: $e');
      // Clear potentially corrupted cache
      await Future.wait([
        _secureStorage.delete(key: _profileCacheKey),
        _secureStorage.delete(key: _profileCacheTimestampKey),
      ]);
    }
  }

  /// Check if profile cache is expired
  bool _isProfileCacheExpired() {
    if (_profileCacheTime == null) return true;

    final cacheAge = DateTime.now().difference(_profileCacheTime!);
    return cacheAge > _profileCacheDuration;
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

  /// Force refresh of cached profile data
  Future<Either<AuthFailure, UserProfile>> refreshCachedProfile(
    String userId,
  ) async {
    return _performanceService.measureOperation(
      name: 'profile_refresh_cache',
      operation: () => _refreshCachedProfileOptimized(userId),
    );
  }

  Future<Either<AuthFailure, UserProfile>> _refreshCachedProfileOptimized(
    String userId,
  ) async {
    try {
      final profileResult = await _userRepository.getUserProfile(userId);

      return await profileResult.fold(
        (failure) => Left(GenericAuthFailure(failure.message)),
        (profile) async {
          // Update cache
          _cachedProfile = profile;
          _profileCacheTime = DateTime.now();
          await _cacheProfileData(profile);

          debugPrint('Profile cache refreshed for user: $userId');
          return Right(profile);
        },
      );
    } on Object catch (e) {
      return Left(GenericAuthFailure('Failed to refresh profile cache: $e'));
    }
  }
}
