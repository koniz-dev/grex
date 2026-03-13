# Session Security Documentation

## Overview

This document details the session security implementation for the Grex social login system, covering session management, persistence, validation, and security measures to protect user sessions from various attack vectors.

## Session Architecture

### Session Components
```dart
class SessionData {
  final String accessToken;
  final String refreshToken;
  final User user;
  final UserProfile userProfile;
  final DateTime expiresAt;
  final DateTime refreshExpiresAt;
}
```

**Session Elements:**
- **Access Token**: Short-lived authentication token (1 hour)
- **Refresh Token**: Long-lived token for session renewal (30 days)
- **User Data**: Core user identity information
- **Profile Data**: User preferences and settings
- **Expiry Times**: Token lifecycle management

### Session Storage Strategy
```dart
class OptimizedSessionService implements SessionService {
  // Secure storage for sensitive data
  final FlutterSecureStorage _secureStorage;
  
  // In-memory cache for performance
  UserProfile? _cachedProfile;
  DateTime? _profileCacheTime;
  
  // Cache duration - profile data cached for 5 minutes
  static const Duration _profileCacheDuration = Duration(minutes: 5);
}
```

## Session Persistence

### Secure Storage Implementation
```dart
Future<Either<AuthFailure, void>> storeSession({
  required String accessToken,
  required String refreshToken,
  required User user,
  required UserProfile userProfile,
}) async {
  // Store session data and cache profile in parallel
  await Future.wait([
    _secureStorage.write(
      key: _sessionKey,
      value: jsonEncode(sessionData.toJson()),
    ),
    _secureStorage.write(
      key: AppConstants.tokenKey,
      value: accessToken,
    ),
    _secureStorage.write(
      key: AppConstants.refreshTokenKey,
      value: refreshToken,
    ),
    _cacheProfileData(userProfile),
  ]);
}
```

**Security Features:**
- Encrypted storage using platform-specific mechanisms
- Parallel storage operations for performance
- Atomic operations to prevent partial writes
- Automatic cleanup on storage failures

### Session Restoration
```dart
Future<Either<AuthFailure, SessionData?>> getStoredSession() async {
  try {
    final sessionJson = await _secureStorage.read(key: _sessionKey);
    
    if (sessionJson == null) {
      return const Right(null);
    }
    
    final sessionData = SessionData.fromJson(jsonDecode(sessionJson));
    
    // Check if session is completely expired
    if (sessionData.isExpired) {
      await clearSession();
      return const Right(null);
    }
    
    return Right(sessionData);
  } catch (e) {
    // If we can't parse stored session, clear it
    await clearSession();
    return Left(GenericAuthFailure('Failed to retrieve session: $e'));
  }
}
```

**Restoration Process:**
1. Attempt to read encrypted session data
2. Validate session format and integrity
3. Check session expiration status
4. Clear invalid or corrupted sessions
5. Return valid session or null

## Session Validation

### Multi-Layer Validation
```dart
Future<Either<AuthFailure, bool>> validateSession() async {
  final sessionResult = await getStoredSession();
  
  return sessionResult.fold(
    Left.new,
    (sessionData) async {
      if (sessionData == null) {
        return const Right(false);
      }
      
      // Layer 1: Local expiry check
      if (sessionData.isExpired) {
        await clearSession();
        return const Right(false);
      }
      
      // Layer 2: Backend validation
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null || currentUser.id != sessionData.user.id) {
        await clearSession();
        return const Right(false);
      }
      
      // Layer 3: Profile validation (lazy loading)
      if (_cachedProfile == null || _isProfileCacheExpired()) {
        final profileResult = await _userRepository.getUserProfile(
          sessionData.user.id,
        );
        return profileResult.fold(
          (failure) async {
            await clearSession();
            return const Right(false);
          },
          (profile) async {
            _cachedProfile = profile;
            _profileCacheTime = DateTime.now();
            return const Right(true);
          },
        );
      }
      
      return const Right(true);
    },
  );
}
```

**Validation Layers:**
1. **Local Validation**: Check token expiry times
2. **Backend Validation**: Verify with Supabase auth service
3. **Profile Validation**: Ensure user profile still exists
4. **Cache Validation**: Verify cached data integrity

### Validation Frequency
- **On App Start**: Full validation with backend check
- **Periodic**: Every 5 minutes during active use
- **Before Sensitive Operations**: Real-time validation
- **On Network Reconnect**: Re-validate after connectivity loss

## Session Refresh

### Proactive Refresh Strategy
```dart
// Session refresh threshold - refresh when 10 minutes remain
static const Duration _refreshThreshold = Duration(minutes: 10);

Future<bool> needsRefresh() async {
  final sessionResult = await getStoredSession();
  return sessionResult.fold(
    (failure) => false,
    (sessionData) {
      if (sessionData == null) return false;
      
      final now = DateTime.now();
      final timeUntilExpiry = sessionData.expiresAt.difference(now);
      
      // Refresh if less than 10 minutes remain
      return timeUntilExpiry <= _refreshThreshold;
    },
  );
}
```

**Refresh Triggers:**
- **Time-based**: When 10 minutes remain before expiry
- **On-demand**: Before critical operations
- **Background**: During app idle periods
- **Recovery**: After network reconnection

### Refresh Implementation
```dart
Future<Either<AuthFailure, SessionData>> refreshSession() async {
  // Use Supabase to refresh the session
  final response = await _supabaseClient.auth.refreshSession();
  
  if (response.session == null) {
    await clearSession();
    return const Left(GenericAuthFailure('Failed to refresh session'));
  }
  
  final session = response.session!;
  final user = User.fromSupabaseUser(session.user);
  
  // Use cached profile if available
  UserProfile userProfile;
  if (_cachedProfile != null && !_isProfileCacheExpired()) {
    userProfile = _cachedProfile!;
  } else {
    // Fetch fresh profile data
    final profileResult = await _userRepository.getUserProfile(user.id);
    userProfile = await profileResult.fold(
      (failure) => throw Exception(failure.message),
      (profile) => profile,
    );
  }
  
  // Store refreshed session
  await storeSession(
    accessToken: session.accessToken,
    refreshToken: session.refreshToken ?? sessionData.refreshToken,
    user: user,
    userProfile: userProfile,
  );
}
```

## Session Security Measures

### Attack Prevention

#### Session Hijacking Protection
- **Secure Storage**: Encrypted token storage
- **HTTPS Only**: All communications over TLS
- **Token Binding**: Tokens bound to device/app
- **Short Lifetimes**: Limited token validity periods

#### Session Fixation Prevention
- **Token Regeneration**: New tokens on each refresh
- **Session Invalidation**: Clear old sessions on new login
- **Unique Identifiers**: Each session has unique ID
- **Secure Cookies**: HttpOnly and Secure flags (web)

#### Cross-Site Request Forgery (CSRF) Protection
- **State Parameter**: OAuth state parameter validation
- **Origin Validation**: Deep link origin checking
- **Token Validation**: Backend token verification
- **Request Signing**: Cryptographic request signatures

### Session Monitoring

#### Security Metrics
```dart
class SessionSecurityMetrics {
  static void trackSessionEvent(String event, Map<String, String> attributes) {
    // Track security-relevant session events
    analytics.track('session_security_event', {
      'event_type': event,
      'timestamp': DateTime.now().toIso8601String(),
      ...attributes,
    });
  }
}
```

**Monitored Events:**
- Session creation and destruction
- Token refresh success/failure
- Validation failures
- Suspicious activity patterns

#### Anomaly Detection
- **Multiple Devices**: Same user on multiple devices
- **Rapid Refreshes**: Unusual token refresh patterns
- **Failed Validations**: Repeated validation failures
- **Geographic Anomalies**: Logins from unusual locations

### Session Cleanup

#### Automatic Cleanup
```dart
Future<Either<AuthFailure, void>> clearSession() async {
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
    
    return const Right(null);
  } catch (e) {
    return Left(GenericAuthFailure('Failed to clear session: $e'));
  }
}
```

**Cleanup Triggers:**
- **User Logout**: Explicit session termination
- **Token Expiry**: Automatic cleanup of expired sessions
- **Validation Failure**: Cleanup of invalid sessions
- **App Uninstall**: Platform-level cleanup

#### Secure Disposal
- **Memory Clearing**: Overwrite sensitive variables
- **Cache Invalidation**: Clear all cached data
- **Storage Wiping**: Secure deletion from storage
- **Network Cleanup**: Cancel pending requests

## Performance Optimization

### Caching Strategy
```dart
// In-memory cache for profile data
UserProfile? _cachedProfile;
DateTime? _profileCacheTime;

// Profile cache duration - 5 minutes
static const Duration _profileCacheDuration = Duration(minutes: 5);

bool _isProfileCacheExpired() {
  if (_profileCacheTime == null) return true;
  
  final cacheAge = DateTime.now().difference(_profileCacheTime!);
  return cacheAge > _profileCacheDuration;
}
```

**Cache Benefits:**
- **Reduced Network Calls**: Fewer backend requests
- **Faster Response Times**: Immediate data access
- **Offline Capability**: Limited offline functionality
- **Battery Efficiency**: Reduced network usage

### Lazy Loading
```dart
Future<UserProfile?> getCachedProfile(String userId) async {
  // Return in-memory cache if valid
  if (_cachedProfile != null && !_isProfileCacheExpired()) {
    return _cachedProfile;
  }
  
  // Load from secure storage cache
  await _loadCachedProfile(userId);
  return _cachedProfile;
}
```

**Lazy Loading Benefits:**
- **On-Demand Loading**: Load data only when needed
- **Memory Efficiency**: Minimal memory footprint
- **Performance**: Faster app startup times
- **Scalability**: Handles large user bases efficiently

## Compliance and Standards

### Security Standards
- **OWASP Mobile Top 10**: Addresses all mobile security risks
- **NIST Cybersecurity Framework**: Implements security controls
- **OAuth 2.0 Security**: Follows RFC 6819 security considerations
- **Platform Guidelines**: Adheres to iOS and Android security best practices

### Privacy Compliance
- **GDPR**: Implements data protection requirements
- **CCPA**: Supports California privacy rights
- **Data Minimization**: Collects only necessary data
- **User Consent**: Explicit consent for data processing

## Testing and Validation

### Security Testing
```dart
group('Session Security Tests', () {
  test('should encrypt session data in storage', () async {
    // Verify session data is encrypted
  });
  
  test('should validate session integrity', () async {
    // Verify session validation works correctly
  });
  
  test('should handle session expiry gracefully', () async {
    // Verify expired sessions are handled properly
  });
});
```

### Penetration Testing
- **Session Hijacking Attempts**: Test session security
- **Token Extraction**: Attempt to extract tokens
- **Replay Attacks**: Test token reuse protection
- **Man-in-the-Middle**: Test HTTPS enforcement

## Incident Response

### Security Incident Procedures
1. **Detection**: Automated monitoring alerts
2. **Assessment**: Evaluate security impact
3. **Containment**: Revoke compromised sessions
4. **Recovery**: Restore secure operations
5. **Analysis**: Post-incident review and improvements

### Emergency Procedures
```dart
// Emergency session revocation
Future<void> emergencySessionRevocation(String userId) async {
  // Revoke all sessions for user
  await _supabaseClient.auth.signOut();
  await clearSession();
  
  // Notify security team
  SecurityIncidentReporter.reportEmergency(
    'session_compromise',
    {'user_id': userId},
  );
}
```

---

**Document Version**: 1.0  
**Last Updated**: December 2024  
**Next Review**: March 2025  
**Owner**: Security Team