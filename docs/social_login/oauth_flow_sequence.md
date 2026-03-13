# OAuth Flow Sequence Documentation

## Overview

This document describes the complete OAuth authentication flow for social login in Grex, including the sequence of operations, component interactions, and error handling scenarios.

## Flow Sequence Diagram

```
User                 App                 Supabase Auth        OAuth Provider
 │                    │                       │                     │
 │  Tap Social Btn    │                       │                     │
 ├───────────────────>│                       │                     │
 │                    │  signInWithOAuth()    │                     │
 │                    ├──────────────────────>│                     │
 │                    │                       │  Redirect to OAuth  │
 │                    │                       ├────────────────────>│
 │                    │                       │                     │
 │  <──────────────── Browser Opens ──────────────────────────────>│
 │                    │                       │                     │
 │  Authorize         │                       │                     │
 ├────────────────────────────────────────────────────────────────>│
 │                    │                       │  Auth Code          │
 │                    │                       │<────────────────────┤
 │                    │                       │                     │
 │                    │  Deep Link Callback   │                     │
 │                    │<──────────────────────┤                     │
 │                    │                       │                     │
 │                    │  Check Profile Exists │                     │
 │                    ├──────────────────────>│                     │
 │                    │                       │                     │
 │  Navigate to       │                       │                     │
 │  Main/Profile      │                       │                     │
 │<───────────────────┤                       │                     │
```

## Detailed Flow Steps

### 1. User Initiates OAuth

**Components Involved:**
- `SocialLoginButton` widget
- `AuthBloc` state management

**Process:**
1. User taps Google or Apple sign-in button
2. Button triggers `AuthSocialLoginRequested` event
3. AuthBloc emits `AuthSocialLoginInProgress` state
4. UI shows loading indicator and disables buttons

**Code Example:**
```dart
// In SocialLoginButton
onPressed: () => context.read<AuthBloc>().add(
  AuthSocialLoginRequested(provider.name),
)

// In AuthBloc
Future<void> _onSocialLoginRequested(
  AuthSocialLoginRequested event,
  Emitter<AuthState> emit,
) async {
  emit(AuthSocialLoginInProgress(
    SocialAuthProvider.fromString(event.provider)!,
  ));
  
  final result = await _socialAuthRepository.signInWithGoogle();
  // Handle result...
}
```

### 2. OAuth Provider Redirect

**Components Involved:**
- `SupabaseSocialAuthRepository`
- Supabase Auth SDK
- External browser

**Process:**
1. Repository calls `supabase.auth.signInWithOAuth()`
2. Supabase generates OAuth URL with state parameter
3. External browser launches with OAuth provider consent screen
4. User authorizes the application

**Code Example:**
```dart
// In SupabaseSocialAuthRepository
final response = await _supabaseClient.auth.signInWithOAuth(
  provider,
  redirectTo: 'io.supabase.grex://login-callback/',
  authScreenLaunchMode: supabase.LaunchMode.externalApplication,
);
```

**Performance Optimization:**
- Uses `externalApplication` launch mode for fastest browser startup
- Minimal UI blocking during browser launch

### 3. OAuth Callback Processing

**Components Involved:**
- `AuthDeepLinkHandler`
- Deep link system (app_links package)
- Supabase Auth SDK

**Process:**
1. OAuth provider redirects to `io.supabase.grex://login-callback/`
2. Deep link handler intercepts the callback URL
3. Supabase SDK automatically processes tokens
4. Auth state changes to authenticated

**Code Example:**
```dart
// In AuthDeepLinkHandler
bool _isAuthCallback(Uri uri) {
  return uri.scheme == 'io.supabase.grex' && 
         uri.host == 'login-callback';
}

Future<void> handleDeepLink(Uri uri) async {
  if (_isAuthCallback(uri)) {
    // Supabase automatically processes the callback
    onDeepLink(uri);
  }
}
```

**Performance Optimization:**
- Fast URI validation (microsecond-level)
- Immediate callback processing without async operations
- Performance monitoring for callback processing time

### 4. User Profile Check

**Components Involved:**
- `AuthBloc`
- `SocialAuthRepository`
- `UserRepository`

**Process:**
1. After successful OAuth, check if user profile exists
2. Query user profile by user ID
3. Determine next navigation step based on profile existence

**Code Example:**
```dart
// In AuthBloc after successful OAuth
final hasProfile = await _socialAuthRepository.hasUserProfile(user.id);

if (hasProfile) {
  // Existing user - navigate to main screen
  final profile = await _userRepository.getUserProfile(user.id);
  emit(AuthAuthenticated(user, profile));
} else {
  // New user - check for account linking
  await _checkAccountLinking(user);
}
```

### 5. Account Linking Detection

**Components Involved:**
- `AuthBloc`
- `UserRepository`

**Process:**
1. Check if email already exists in user profiles
2. If exists, prompt for account linking
3. If not exists, proceed to profile setup

**Code Example:**
```dart
Future<void> _checkAccountLinking(User user) async {
  final existingProfile = await _userRepository.getUserProfileByEmail(user.email);
  
  if (existingProfile != null) {
    emit(AuthAccountLinkingRequired(
      newUser: user,
      existingProfile: existingProfile,
      provider: user.socialProvider!,
    ));
  } else {
    emit(AuthProfileSetupRequired(
      user: user,
      provider: user.socialProvider!,
      displayName: user.oauthDisplayName,
      email: user.email,
    ));
  }
}
```

## Error Handling Scenarios

### 1. User Cancellation

**Trigger:** User closes OAuth browser or cancels authorization

**Handling:**
```dart
if (!response) {
  return const Left(SocialAuthCancelledFailure());
}
```

**UI Response:** Return to login screen without error message

### 2. Network Errors

**Trigger:** Network connectivity issues during OAuth

**Handling:**
```dart
AuthFailure _mapAuthException(supabase.AuthException exception) {
  if (exception.message.toLowerCase().contains('network')) {
    return const SocialAuthNetworkFailure();
  }
  // Other error mappings...
}
```

**UI Response:** Show retry button with network error message

### 3. Timeout Errors

**Trigger:** OAuth callback not received within 10 seconds

**Handling:**
```dart
Future<supabase.User?> _waitForAuthUserOptimized() async {
  const maxAttempts = 40; // 40 * 250ms = 10 seconds
  
  for (int attempt = 0; attempt < maxAttempts; attempt++) {
    final user = _supabaseClient.auth.currentUser;
    if (user != null) return user;
    
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  
  throw TimeoutException('Authentication timeout after 10 seconds');
}
```

**UI Response:** Show timeout message and return to login

### 4. Deep Link Processing Errors

**Trigger:** Malformed callback URL or processing failure

**Handling:**
```dart
Future<void> _processDeepLinkOptimized(Uri uri) async {
  try {
    if (!_isAuthCallback(uri)) return;
    onDeepLink(uri);
  } catch (e) {
    debugPrint('Error handling deep link: $uri');
    debugPrint('Error details: $e');
    rethrow; // Let upper layers handle with generic message
  }
}
```

**UI Response:** Generic error message with retry option

## Performance Characteristics

### Target Performance Metrics

- **Browser Launch:** < 500ms from button tap
- **Callback Processing:** < 1 second from deep link to UI update
- **Profile Check:** < 2 seconds for database query
- **Total Flow:** < 10 seconds for complete OAuth flow

### Optimization Techniques

1. **External Browser Launch:** Fastest OAuth experience
2. **Optimized Polling:** 250ms intervals for auth state checking
3. **Minimal UI Updates:** Reduce redraws during authentication
4. **Performance Monitoring:** Track all operations with metrics

### Memory Management

- Dispose deep link subscriptions properly
- Clean up OAuth state after completion
- Avoid memory leaks in auth state management

## Security Considerations

### OAuth Scopes

- **Google:** `email`, `profile` (minimal required scopes)
- **Apple:** `email`, `name` (minimal required scopes)

### Token Handling

- Tokens handled entirely by Supabase SDK
- Never exposed in application code
- Automatic secure storage by Supabase

### Deep Link Security

- Validate callback URLs before processing
- Use specific scheme and host validation
- Log security events for monitoring

## Testing Strategies

### Unit Tests

- Test OAuth initiation for both providers
- Test error mapping for all failure types
- Test deep link validation logic

### Property-Based Tests

- OAuth flow properties with 100+ iterations
- Error handling properties for edge cases
- Performance properties for timing requirements

### Integration Tests

- Complete OAuth flow with real providers
- Deep link handling with various URLs
- Account linking scenarios

## Troubleshooting Guide

### Common Issues

1. **Deep Link Not Working**
   - Check URL scheme configuration
   - Verify AndroidManifest.xml and Info.plist settings
   - Test with `adb shell am start` command

2. **OAuth Timeout**
   - Check network connectivity
   - Verify Supabase project configuration
   - Test with different OAuth providers

3. **Profile Creation Fails**
   - Check database permissions (RLS policies)
   - Verify user data from OAuth provider
   - Test with different user scenarios

### Debug Information

Enable debug logging to see detailed OAuth flow:

```dart
debugPrint('OAuth initiated for provider: $providerName');
debugPrint('OAuth completed in ${stopwatch.elapsedMilliseconds}ms');
debugPrint('Deep link processed in ${stopwatch.elapsedMicroseconds}μs');
```

## Related Documentation

- [Account Linking Logic](./account_linking_logic.md)
- [Deep Link Handling](./deep_link_handling.md)
- [Social Auth API Reference](./social_auth_api.md)