# OAuth Token Handling Security Documentation

## Overview

This document outlines the security measures implemented for OAuth token handling in the Grex social login system. It covers token storage, transmission, lifecycle management, and security best practices.

## Token Types

### Access Tokens
- **Purpose**: Authenticate API requests to Supabase
- **Lifetime**: 1 hour (configurable in Supabase)
- **Storage**: Encrypted secure storage
- **Transmission**: HTTPS only via Supabase SDK

### Refresh Tokens
- **Purpose**: Obtain new access tokens without re-authentication
- **Lifetime**: 30 days (configurable in Supabase)
- **Storage**: Encrypted secure storage
- **Transmission**: HTTPS only via Supabase SDK

## Secure Storage Implementation

### Platform-Specific Security

#### Android
```dart
static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
);
```

**Security Features:**
- Uses `EncryptedSharedPreferences` for data encryption
- AES-256 encryption with hardware-backed keys when available
- Automatic key rotation on device unlock
- Protection against root access and debugging

#### iOS
```dart
static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);
```

**Security Features:**
- Uses iOS Keychain for secure storage
- Hardware Security Module (HSM) protection on supported devices
- Biometric authentication integration
- Protection against jailbreak and debugging

### Storage Keys
```dart
// Token storage keys
static const String tokenKey = 'auth_token';
static const String refreshTokenKey = 'refresh_token';
```

**Key Management:**
- Unique keys for different token types
- No hardcoded sensitive values
- Automatic cleanup on logout

## Token Transmission Security

### HTTPS Enforcement
All OAuth token transmission is enforced over HTTPS through the Supabase SDK:

```dart
final response = await _supabaseClient.auth.signInWithOAuth(
  provider,
  redirectTo: _redirectUrl,
  authScreenLaunchMode: supabase.LaunchMode.externalApplication,
);
```

**Security Measures:**
- TLS 1.2+ encryption for all communications
- Certificate validation and pinning
- Protection against man-in-the-middle attacks
- Automatic retry with exponential backoff

### Deep Link Security
OAuth callbacks use secure deep link scheme:

```dart
static const String _redirectUrl = 'io.supabase.grex://login-callback/';
```

**Security Features:**
- Custom scheme prevents URL hijacking
- Callback validation before processing
- Timeout protection (10 seconds)
- Error handling without information leakage

## Token Lifecycle Management

### Token Refresh Strategy
```dart
// Session refresh threshold - refresh when 10 minutes remain
static const Duration _refreshThreshold = Duration(minutes: 10);
```

**Proactive Refresh:**
- Automatic refresh before expiration
- Background refresh to maintain session
- Graceful handling of refresh failures
- Fallback to re-authentication when needed

### Token Validation
```dart
Future<Either<AuthFailure, bool>> validateSession() async {
  // Check token expiry
  if (sessionData.isExpired) {
    await clearSession();
    return const Right(false);
  }
  
  // Validate with Supabase backend
  final currentUser = _supabaseClient.auth.currentUser;
  if (currentUser == null || currentUser.id != sessionData.user.id) {
    await clearSession();
    return const Right(false);
  }
  
  return const Right(true);
}
```

**Validation Process:**
1. Local expiry check
2. Backend validation with Supabase
3. User identity verification
4. Automatic cleanup of invalid sessions

### Token Cleanup
```dart
Future<Either<AuthFailure, void>> clearSession() async {
  // Clear all session data in parallel
  await Future.wait([
    _secureStorage.delete(key: _sessionKey),
    _secureStorage.delete(key: AppConstants.tokenKey),
    _secureStorage.delete(key: AppConstants.refreshTokenKey),
    // ... other cleanup operations
  ]);
}
```

**Cleanup Triggers:**
- User logout
- Session expiration
- Token validation failure
- App uninstall (automatic)

## Security Best Practices

### Token Exposure Prevention

#### Debug Logging
```dart
// Tokens are never logged in production
if (kDebugMode) {
  debugPrint('OAuth completed in ${stopwatch.elapsedMilliseconds}ms');
  // Note: No token values in debug output
}
```

#### Error Handling
```dart
AuthFailure _mapAuthException(supabase.AuthException exception) {
  // Map exceptions without exposing tokens
  if (message.contains('network')) {
    return const SocialAuthNetworkFailure();
  }
  // Generic failure without sensitive details
  return SocialAuthFailure(exception.message);
}
```

### Memory Protection
- Tokens stored in secure storage, not in memory
- Automatic garbage collection of temporary variables
- No token caching in plain text
- Secure disposal of sensitive data structures

### Network Security
- Certificate pinning for additional security
- Request/response validation
- Timeout protection against hanging requests
- Retry logic with exponential backoff

## Compliance and Standards

### OAuth 2.0 Compliance
- Follows RFC 6749 OAuth 2.0 specification
- Implements PKCE (Proof Key for Code Exchange) via Supabase
- Uses state parameter for CSRF protection
- Proper scope handling and validation

### Industry Standards
- Follows OWASP Mobile Security guidelines
- Implements NIST cybersecurity framework principles
- Adheres to platform security best practices
- Regular security updates and patches

## Monitoring and Alerting

### Security Metrics
- Token refresh success/failure rates
- Authentication attempt patterns
- Session duration analytics
- Error rate monitoring

### Anomaly Detection
- Unusual authentication patterns
- Multiple failed attempts
- Token validation failures
- Suspicious session behavior

## Incident Response

### Security Incident Procedures
1. **Detection**: Automated monitoring and alerting
2. **Assessment**: Evaluate scope and impact
3. **Containment**: Revoke compromised tokens
4. **Recovery**: Restore secure operations
5. **Lessons Learned**: Update security measures

### Token Revocation
```dart
// Emergency token revocation
await _supabaseClient.auth.signOut();
await clearSession();
```

## Security Testing

### Automated Testing
- Token storage encryption validation
- Network transmission security tests
- Session lifecycle testing
- Error handling verification

### Manual Testing
- Penetration testing of OAuth flows
- Token extraction attempts
- Network interception testing
- Device security validation

## Updates and Maintenance

### Regular Security Reviews
- Quarterly security assessments
- Dependency vulnerability scanning
- Platform security update monitoring
- Compliance requirement updates

### Version Management
- Secure update mechanisms
- Backward compatibility considerations
- Migration strategies for security updates
- Emergency patch deployment procedures

---

**Document Version**: 1.0  
**Last Updated**: December 2024  
**Next Review**: March 2025  
**Owner**: Security Team