import 'dart:async';
import 'package:dartz/dartz.dart';

import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/services/session_service.dart';

/// Session manager that handles automatic session management
///
/// This service coordinates between the session service and repositories
/// to provide automatic session validation, refresh, and cleanup.
class SessionManager {
  /// Creates a [SessionManager] with the provided [sessionService].
  SessionManager({
    required SessionService sessionService,
  }) : _sessionService = sessionService;
  final SessionService _sessionService;

  Timer? _refreshTimer;
  Timer? _validationTimer;

  static const Duration _refreshCheckInterval = Duration(minutes: 5);
  static const Duration _validationInterval = Duration(hours: 1);

  /// Initialize session manager
  ///
  /// Starts automatic session validation and refresh timers.
  /// Should be called when the app starts.
  Future<Either<AuthFailure, SessionData?>> initialize() async {
    // Try to restore session from storage
    final sessionResult = await _sessionService.getStoredSession();

    return await sessionResult.fold(
      (failure) async => Left(failure),
      (sessionData) async {
        if (sessionData == null) {
          return const Right(null);
        }

        // Validate the stored session
        final isValid = await _sessionService.validateSession();

        return await isValid.fold(
          (failure) async => Left(failure),
          (valid) async {
            if (!valid) {
              return const Right(null);
            }

            // Start automatic management
            _startAutomaticManagement();

            return Right(sessionData);
          },
        );
      },
    );
  }

  /// Start session with new authentication
  ///
  /// Stores session data and starts automatic management.
  Future<Either<AuthFailure, void>> startSession({
    required String accessToken,
    required String refreshToken,
    required User user,
    required UserProfile userProfile,
  }) async {
    final storeResult = await _sessionService.storeSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
      userProfile: userProfile,
    );

    return storeResult.fold(
      Left.new,
      (_) {
        _startAutomaticManagement();
        return const Right(null);
      },
    );
  }

  /// End current session
  ///
  /// Clears session data and stops automatic management.
  Future<Either<AuthFailure, void>> endSession() async {
    _stopAutomaticManagement();
    return _sessionService.clearSession();
  }

  /// Get current session data
  Future<Either<AuthFailure, SessionData?>> getCurrentSession() async {
    return _sessionService.getStoredSession();
  }

  /// Check if session is valid
  Future<Either<AuthFailure, bool>> isSessionValid() async {
    return _sessionService.validateSession();
  }

  /// Manually refresh session
  Future<Either<AuthFailure, SessionData>> refreshSession() async {
    return _sessionService.refreshSession();
  }

  /// Start automatic session management
  void _startAutomaticManagement() {
    _stopAutomaticManagement(); // Stop any existing timers

    // Start refresh check timer
    _refreshTimer = Timer.periodic(_refreshCheckInterval, (_) {
      unawaited(_checkAndRefreshSession());
    });

    // Start validation timer
    _validationTimer = Timer.periodic(_validationInterval, (_) {
      unawaited(_validateSession());
    });
  }

  /// Stop automatic session management
  void _stopAutomaticManagement() {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    _validationTimer?.cancel();
    _validationTimer = null;
  }

  /// Check if session needs refresh and refresh if needed
  Future<void> _checkAndRefreshSession() async {
    try {
      final sessionResult = await _sessionService.getStoredSession();

      await sessionResult.fold(
        (failure) async {
          // If we can't get session, stop management
          _stopAutomaticManagement();
        },
        (sessionData) async {
          if (sessionData == null) {
            _stopAutomaticManagement();
            return;
          }

          // Check if session needs refresh
          if (sessionData.needsRefresh && !sessionData.isRefreshTokenExpired) {
            final refreshResult = await _sessionService.refreshSession();

            refreshResult.fold(
              (failure) {
                // If refresh fails, stop management
                _stopAutomaticManagement();
              },
              (newSessionData) {
                // Session refreshed successfully
                // The session service already stored the new data
              },
            );
          } else if (sessionData.isExpired) {
            // Session is completely expired, clear it
            await _sessionService.clearSession();
            _stopAutomaticManagement();
          }
        },
      );
    } on Object catch (_) {
      // If anything goes wrong, stop management
      _stopAutomaticManagement();
    }
  }

  /// Validate current session
  Future<void> _validateSession() async {
    try {
      final isValidResult = await _sessionService.validateSession();

      isValidResult.fold(
        (failure) {
          // If validation fails, stop management
          _stopAutomaticManagement();
        },
        (isValid) {
          if (!isValid) {
            // Session is invalid, stop management
            _stopAutomaticManagement();
          }
        },
      );
    } on Object catch (_) {
      // If validation throws, stop management
      _stopAutomaticManagement();
    }
  }

  /// Dispose resources
  void dispose() {
    _stopAutomaticManagement();
  }

  /// Get session expiry information
  Future<SessionExpiryInfo> getExpiryInfo() async {
    final sessionResult = await _sessionService.getStoredSession();

    return sessionResult.fold(
      (failure) => const SessionExpiryInfo(
        hasSession: false,
        isExpired: true,
        needsRefresh: false,
        expiresAt: null,
        timeUntilExpiry: null,
      ),
      (sessionData) {
        if (sessionData == null) {
          return const SessionExpiryInfo(
            hasSession: false,
            isExpired: true,
            needsRefresh: false,
            expiresAt: null,
            timeUntilExpiry: null,
          );
        }

        final now = DateTime.now();
        final timeUntilExpiry = sessionData.expiresAt.isAfter(now)
            ? sessionData.expiresAt.difference(now)
            : Duration.zero;

        return SessionExpiryInfo(
          hasSession: true,
          isExpired: sessionData.isExpired,
          needsRefresh: sessionData.needsRefresh,
          expiresAt: sessionData.expiresAt,
          timeUntilExpiry: timeUntilExpiry,
        );
      },
    );
  }
}

/// Session expiry information
class SessionExpiryInfo {
  /// Creates a [SessionExpiryInfo] with the provided expiry data.
  ///
  /// All parameters are required:
  /// - [hasSession]: Whether a session exists
  /// - [isExpired]: Whether the session is expired
  /// - [needsRefresh]: Whether the session needs to be refreshed
  /// - [expiresAt]: When the session expires
  /// - [timeUntilExpiry]: Duration until expiry
  const SessionExpiryInfo({
    required this.hasSession,
    required this.isExpired,
    required this.needsRefresh,
    required this.expiresAt,
    required this.timeUntilExpiry,
  });

  /// Whether a session exists
  final bool hasSession;

  /// Whether the session is expired
  final bool isExpired;

  /// Whether the session needs to be refreshed
  final bool needsRefresh;

  /// When the session expires
  final DateTime? expiresAt;

  /// Duration until the session expires
  final Duration? timeUntilExpiry;

  @override
  String toString() {
    return 'SessionExpiryInfo('
        'hasSession: $hasSession, '
        'isExpired: $isExpired, '
        'needsRefresh: $needsRefresh, '
        'expiresAt: $expiresAt, '
        'timeUntilExpiry: $timeUntilExpiry'
        ')';
  }
}
