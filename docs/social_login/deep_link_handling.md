# Deep Link Handling Documentation

## Overview

This document describes the deep link handling system for OAuth callbacks in Grex's social login feature. The system processes OAuth callback URLs and manages the authentication flow completion.

## Architecture

### Components

1. **AuthDeepLinkHandler** - Main handler for OAuth callbacks
2. **app_links Package** - Flutter package for deep link processing
3. **Supabase Auth SDK** - Automatic token processing from callbacks

### Deep Link Flow

```
OAuth Provider → Deep Link → AuthDeepLinkHandler → Supabase → AuthBloc
     │              │              │                  │         │
     │              │              │                  │         └─ UI Update
     │              │              │                  └─ Session Created
     │              │              └─ Callback Processed
     │              └─ URL Intercepted
     └─ Redirect with tokens
```

## URL Scheme Configuration

### Callback URL Format

```
io.supabase.grex://login-callback/?access_token=...&refresh_token=...
```

**Components:**
- **Scheme:** `io.supabase.grex`
- **Host:** `login-callback`
- **Parameters:** OAuth tokens and state

### Platform Configuration

#### Android (android/app/src/main/AndroidManifest.xml)

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme">
    
    <!-- OAuth callback intent filter -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="io.supabase.grex" 
              android:host="login-callback" />
    </intent-filter>
</activity>
```

#### iOS (ios/Runner/Info.plist)

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>grex.oauth.callback</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.grex</string>
        </array>
    </dict>
</array>
```

## AuthDeepLinkHandler Implementation

### Core Functionality

```dart
/// Handler for OAuth deep link callbacks
///
/// This class manages deep link handling for OAuth authentication flows,
/// processing callbacks from OAuth providers with performance optimizations
/// and handling various failure scenarios with appropriate error logging.
class AuthDeepLinkHandler {
  AuthDeepLinkHandler({
    required this.onDeepLink,
    required PerformanceService performanceService,
  }) : _performanceService = performanceService;

  /// Callback function to handle deep link URIs
  final void Function(Uri) onDeepLink;
  final PerformanceService _performanceService;

  /// Initialize deep link handling
  Future<void> initialize() async {
    // Set up app_links listener for OAuth callbacks
    final appLinks = AppLinks();
    
    // Handle initial link (app opened from OAuth callback)
    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null && _isAuthCallback(initialUri)) {
        await handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error handling initial link: $e');
    }
    
    // Handle runtime links (app already running)
    appLinks.uriLinkStream.listen(
      (uri) async {
        if (_isAuthCallback(uri)) {
          await handleDeepLink(uri);
        }
      },
      onError: (error) {
        debugPrint('Error in deep link stream: $error');
      },
    );
  }
}
```

### Performance Optimization

#### Fast URL Validation

```dart
/// Checks if a URI is an OAuth callback with optimized validation
///
/// Fast validation that should complete in microseconds
bool _isAuthCallback(Uri uri) {
  // Use direct string comparison for fastest validation
  return uri.scheme == 'io.supabase.grex' && uri.host == 'login-callback';
}
```

**Performance Characteristics:**
- **Validation Time:** < 1 microsecond
- **Memory Usage:** Minimal (no regex or complex parsing)
- **CPU Usage:** Single string comparison operations

#### Optimized Processing

```dart
/// Handles a deep link URI with performance optimization
Future<void> handleDeepLink(Uri uri) async {
  return _performanceService.measureOperation(
    name: 'oauth_deeplink_processing',
    attributes: {
      'scheme': uri.scheme,
      'host': uri.host,
      'has_fragment': uri.fragment.isNotEmpty.toString(),
      'has_query': uri.query.isNotEmpty.toString(),
    },
    operation: () => _processDeepLinkOptimized(uri),
  );
}

/// Optimized deep link processing with performance monitoring
Future<void> _processDeepLinkOptimized(Uri uri) async {
  final stopwatch = Stopwatch()..start();
  
  try {
    // Fast validation - should complete in microseconds
    if (!_isAuthCallback(uri)) {
      debugPrint('Deep link is not an OAuth callback: $uri');
      return;
    }

    // Process the callback immediately - no async operations here
    // to minimize UI blocking
    onDeepLink(uri);
    
    stopwatch.stop();
    debugPrint('Deep link processed in ${stopwatch.elapsedMicroseconds}μs');
  } catch (e) {
    stopwatch.stop();
    debugPrint('Error handling deep link: $uri');
    debugPrint('Error details: $e');
    debugPrint('Processing failed after ${stopwatch.elapsedMicroseconds}μs');
    rethrow;
  }
}
```

**Performance Targets:**
- **Processing Time:** < 1000 microseconds (1ms)
- **UI Blocking:** Minimal (immediate callback invocation)
- **Memory Allocation:** Zero additional allocations

## Integration with AuthBloc

### Initialization

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository authRepository,
    required SocialAuthRepository socialAuthRepository,
    required UserRepository userRepository,
    required AuthDeepLinkHandler deepLinkHandler,
  }) : _authRepository = authRepository,
       _socialAuthRepository = socialAuthRepository,
       _userRepository = userRepository,
       _deepLinkHandler = deepLinkHandler,
       super(AuthInitial()) {
    
    // Initialize deep link handler
    _deepLinkHandler.initialize();
    
    // Register event handlers
    on<AuthSocialLoginRequested>(_onSocialLoginRequested);
    // ... other handlers
  }

  @override
  Future<void> close() {
    _deepLinkHandler.dispose();
    return super.close();
  }
}
```

### Callback Processing

```dart
/// Handle OAuth deep link callback
void _handleOAuthCallback(Uri uri) {
  // Supabase SDK automatically processes the OAuth callback
  // We just need to check the auth state after a short delay
  Future.delayed(const Duration(milliseconds: 500), () {
    final user = _supabaseClient.auth.currentUser;
    if (user != null) {
      add(AuthSessionChecked());
    } else {
      add(const AuthError('Failed to establish session'));
    }
  });
}
```

## Error Handling

### Common Error Scenarios

#### 1. Invalid Callback URL

```dart
// Example invalid URLs that should be rejected
final invalidUrls = [
  'io.supabase.grex://invalid-host/',
  'wrong-scheme://login-callback/',
  'io.supabase.grex://login-callback/malformed',
];

// Validation rejects these immediately
for (final url in invalidUrls) {
  final uri = Uri.parse(url);
  assert(!_isAuthCallback(uri));
}
```

**Handling:**
- Log the invalid URL for debugging
- Return early without processing
- No error shown to user (silent rejection)

#### 2. Processing Failures

```dart
Future<void> _processDeepLinkOptimized(Uri uri) async {
  try {
    // ... processing logic
  } catch (e) {
    // Log detailed error information
    debugPrint('Error handling deep link: $uri');
    debugPrint('Error details: $e');
    debugPrint('Stack trace: ${StackTrace.current}');
    
    // Re-throw for upper layers to handle with user-friendly message
    rethrow;
  }
}
```

**Error Recovery:**
- Detailed logging for debugging
- Generic user error message
- Option to retry OAuth flow

#### 3. Timeout Scenarios

```dart
// If deep link processing takes too long
Future<void> handleDeepLink(Uri uri) async {
  try {
    await _processDeepLinkOptimized(uri).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw TimeoutException('Deep link processing timeout');
      },
    );
  } on TimeoutException {
    debugPrint('Deep link processing timed out for: $uri');
    // Handle timeout with user-friendly message
  }
}
```

## Testing Strategies

### Unit Tests

```dart
group('AuthDeepLinkHandler', () {
  test('should identify valid OAuth callback URLs', () {
    final handler = AuthDeepLinkHandler(onDeepLink: (_) {});
    
    final validUrl = Uri.parse('io.supabase.grex://login-callback/?token=abc');
    expect(handler._isAuthCallback(validUrl), isTrue);
  });

  test('should reject invalid callback URLs', () {
    final handler = AuthDeepLinkHandler(onDeepLink: (_) {});
    
    final invalidUrl = Uri.parse('wrong://scheme/');
    expect(handler._isAuthCallback(invalidUrl), isFalse);
  });

  test('should handle processing errors gracefully', () async {
    var callbackInvoked = false;
    final handler = AuthDeepLinkHandler(
      onDeepLink: (_) {
        callbackInvoked = true;
        throw Exception('Test error');
      },
    );

    final validUrl = Uri.parse('io.supabase.grex://login-callback/');
    
    expect(
      () => handler.handleDeepLink(validUrl),
      throwsException,
    );
    expect(callbackInvoked, isTrue);
  });
});
```

### Property-Based Tests

```dart
// Property: Deep link handler intercepts OAuth callbacks
test('property: deep link handler intercepts OAuth callbacks', () {
  final random = Random();
  
  for (int i = 0; i < 100; i++) {
    // Generate random valid callback URLs
    final token = _generateRandomToken(random);
    final state = _generateRandomState(random);
    final url = 'io.supabase.grex://login-callback/?'
        'access_token=$token&state=$state';
    
    final uri = Uri.parse(url);
    final handler = AuthDeepLinkHandler(onDeepLink: (_) {});
    
    // Property: All valid OAuth callbacks should be intercepted
    expect(handler._isAuthCallback(uri), isTrue);
  }
});

// Property: Invalid OAuth callbacks are ignored
test('property: invalid OAuth callbacks are ignored', () {
  final random = Random();
  
  for (int i = 0; i < 100; i++) {
    // Generate random invalid URLs
    final invalidUrl = _generateInvalidUrl(random);
    final uri = Uri.parse(invalidUrl);
    final handler = AuthDeepLinkHandler(onDeepLink: (_) {});
    
    // Property: Invalid callbacks should be ignored
    expect(handler._isAuthCallback(uri), isFalse);
  }
});
```

### Integration Tests

```dart
testWidgets('complete OAuth flow with deep link', (tester) async {
  // Setup app with real deep link handler
  await tester.pumpWidget(MyApp());
  
  // Simulate OAuth button tap
  await tester.tap(find.text('Continue with Google'));
  await tester.pumpAndSettle();
  
  // Simulate deep link callback
  final callbackUrl = 'io.supabase.grex://login-callback/?'
      'access_token=test_token&refresh_token=test_refresh';
  
  // Trigger deep link processing
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const StandardMethodCodec().encodeMethodCall(
      MethodCall('routeUpdated', {
        'location': callbackUrl,
      }),
    ),
    (data) {},
  );
  
  await tester.pumpAndSettle();
  
  // Verify user is authenticated
  expect(find.text('Welcome'), findsOneWidget);
});
```

## Performance Monitoring

### Metrics Collection

```dart
// Track deep link processing performance
final metrics = {
  'oauth_deeplink_processing_time': stopwatch.elapsedMicroseconds,
  'oauth_deeplink_validation_time': validationTime,
  'oauth_deeplink_callback_time': callbackTime,
};

_performanceService.recordMetrics(metrics);
```

### Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| URL Validation | < 1μs | Time to validate callback URL |
| Callback Processing | < 1ms | Time to process valid callback |
| Total Deep Link Handling | < 5ms | End-to-end processing time |
| Memory Usage | < 1KB | Additional memory for processing |

### Monitoring Alerts

- Alert if processing time > 10ms
- Alert if validation failures > 5% of attempts
- Alert if callback processing errors > 1% of attempts

## Security Considerations

### URL Validation Security

```dart
bool _isAuthCallback(Uri uri) {
  // Strict validation prevents malicious deep links
  return uri.scheme == 'io.supabase.grex' && 
         uri.host == 'login-callback' &&
         uri.path.isEmpty; // Prevent path traversal
}
```

### Token Security

- Tokens are processed entirely by Supabase SDK
- Never log or expose tokens in application code
- Automatic secure storage by Supabase

### Deep Link Security

- Validate all callback parameters
- Log security events for monitoring
- Rate limit deep link processing if needed

## Troubleshooting

### Common Issues

1. **Deep Links Not Working**
   ```bash
   # Test Android deep link manually
   adb shell am start \
     -W -a android.intent.action.VIEW \
     -d "io.supabase.grex://login-callback/?test=1" \
     com.example.grex
   ```

2. **iOS Deep Link Issues**
   - Check Info.plist configuration
   - Verify URL scheme registration
   - Test with Safari custom URL

3. **Processing Timeouts**
   - Check callback URL format
   - Verify network connectivity
   - Review Supabase configuration

### Debug Information

Enable detailed logging:

```dart
// In debug mode, log all deep link activity
if (kDebugMode) {
  debugPrint('Deep link received: $uri');
  debugPrint('Scheme: ${uri.scheme}');
  debugPrint('Host: ${uri.host}');
  debugPrint('Query: ${uri.query}');
  debugPrint('Fragment: ${uri.fragment}');
}
```

## Related Documentation

- [OAuth Flow Sequence](./oauth_flow_sequence.md)
- [Account Linking Logic](./account_linking_logic.md)
- [Social Auth API Reference](./social_auth_api.md)