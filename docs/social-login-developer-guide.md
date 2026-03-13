# Social Login Developer Guide

## Overview

This guide provides comprehensive information for developers working with the social login feature in Grex. It covers implementation details, testing strategies, common issues, and configuration requirements.

## Architecture Overview

The social login system is built using clean architecture principles with the following layers:

```
┌─────────────────────────────────────────────────────────────────┐
│                         UI Layer                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Login Page   │  │ Register Page│  │ Profile Setup Page   │  │
│  │ + Social Btns│  │ + Social Btns│  │ (New Social Users)   │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Business Logic Layer                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              AuthBloc (Extended)                         │   │
│  │  - AuthSocialLoginRequested event                        │   │
│  │  - AuthProfileSetupRequired state                        │   │
│  │  - AuthAccountLinkingRequired state                      │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           AuthDeepLinkHandler (New)                      │   │
│  │  - Intercepts OAuth callbacks                            │   │
│  │  - Processes deep links                                  │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                        Data Layer                                │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         SocialAuthRepository (New)                       │   │
│  │  - signInWithGoogle()                                    │   │
│  │  - signInWithApple()                                     │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         UserRepository (Extended)                        │   │
│  │  - getUserProfileByEmail()                               │   │
│  │  - createSocialUserProfile()                             │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## OAuth Flow Implementation

### Complete OAuth Sequence

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

### Deep Link Handling

The deep link handler processes OAuth callbacks with the following flow:

```
OAuth Callback URL: io.supabase.grex://login-callback/?access_token=...
                              ↓
                    AuthDeepLinkHandler
                              ↓
                    Extract & Validate Tokens
                              ↓
                    Supabase Session Established
                              ↓
                    Check User Profile Exists
                              ↓
            ┌─────────────────┴─────────────────┐
            │                                   │
      Profile Exists                    Profile Missing
            │                                   │
            ↓                                   ↓
    Navigate to Main                  Navigate to Profile Setup
```

## Adding New OAuth Providers

### Step 1: Update SocialAuthProvider Enum

```dart
enum SocialAuthProvider {
  google,
  apple,
  facebook, // New provider
  
  String get displayName {
    switch (this) {
      case SocialAuthProvider.google:
        return 'Google';
      case SocialAuthProvider.apple:
        return 'Apple';
      case SocialAuthProvider.facebook:
        return 'Facebook';
    }
  }
  
  String get iconAsset {
    switch (this) {
      case SocialAuthProvider.google:
        return 'assets/icons/google_logo.svg';
      case SocialAuthProvider.apple:
        return 'assets/icons/apple_logo.svg';
      case SocialAuthProvider.facebook:
        return 'assets/icons/facebook_logo.svg';
    }
  }
}
```

### Step 2: Add Repository Method

```dart
abstract class SocialAuthRepository {
  // Existing methods...
  
  /// Initiates Facebook OAuth authentication flow
  Future<Either<AuthFailure, User>> signInWithFacebook();
}

class SupabaseSocialAuthRepository implements SocialAuthRepository {
  // Existing methods...
  
  @override
  Future<Either<AuthFailure, User>> signInWithFacebook() async {
    return _performanceService.measureOperation(
      name: 'oauth_facebook_signin',
      attributes: {'provider': 'facebook'},
      operation: () => _performOAuthSignIn(
        provider: supabase.OAuthProvider.facebook,
        providerName: 'Facebook',
      ),
    );
  }
}
```

### Step 3: Add UI Components

```dart
// Add to login/register pages
SocialLoginButton(
  provider: SocialAuthProvider.facebook,
  onPressed: () => context.read<AuthBloc>().add(
    const AuthSocialLoginRequested('facebook'),
  ),
  isLoading: state is AuthSocialLoginInProgress &&
             state.provider == SocialAuthProvider.facebook,
)
```

### Step 4: Update AuthBloc

```dart
// Add to AuthBloc event handler
Future<void> _onSocialLoginRequested(
  AuthSocialLoginRequested event,
  Emitter<AuthState> emit,
) async {
  // Existing code...
  
  final result = switch (event.provider) {
    'google' => await _socialAuthRepository.signInWithGoogle(),
    'apple' => await _socialAuthRepository.signInWithApple(),
    'facebook' => await _socialAuthRepository.signInWithFacebook(),
    _ => const Left(SocialAuthFailure('Unsupported provider')),
  };
  
  // Handle result...
}
```

### Step 5: Configure in Supabase

1. Go to Supabase Dashboard → Authentication → Providers
2. Enable Facebook OAuth provider
3. Add Facebook App ID and App Secret
4. Set redirect URL to `https://[project-id].supabase.co/auth/v1/callback`

### Step 6: Add Localization

```json
// app_en.arb
{
  "continueWithFacebook": "Continue with Facebook",
  "@continueWithFacebook": {
    "description": "Facebook sign-in button text"
  }
}
```

### Step 7: Add Tests

```dart
// Unit tests
test('should sign in with Facebook successfully', () async {
  // Arrange
  when(mockSupabaseClient.auth.signInWithOAuth(
    OAuthProvider.facebook,
    redirectTo: any(named: 'redirectTo'),
    authScreenLaunchMode: any(named: 'authScreenLaunchMode'),
  )).thenAnswer((_) async => true);
  
  // Act
  final result = await repository.signInWithFacebook();
  
  // Assert
  expect(result.isRight(), isTrue);
});

// Property tests
test('Facebook OAuth flow should complete within performance requirements', () {
  // Test with 100+ iterations
  for (int i = 0; i < 100; i++) {
    // Test OAuth flow performance
  }
});
```

## Testing Strategies

### Unit Testing

#### Repository Testing
```dart
group('SocialAuthRepository', () {
  late MockSupabaseClient mockClient;
  late SocialAuthRepository repository;
  
  setUp(() {
    mockClient = MockSupabaseClient();
    repository = SupabaseSocialAuthRepository(
      supabaseClient: mockClient,
      userRepository: mockUserRepository,
      performanceService: mockPerformanceService,
    );
  });
  
  test('should return user on successful Google OAuth', () async {
    // Arrange
    when(mockClient.auth.signInWithOAuth(any, any, any))
        .thenAnswer((_) async => true);
    when(mockClient.auth.currentUser).thenReturn(mockSupabaseUser);
    
    // Act
    final result = await repository.signInWithGoogle();
    
    // Assert
    expect(result.isRight(), isTrue);
    result.fold(
      (error) => fail('Should not return error'),
      (user) => expect(user.email, equals('test@example.com')),
    );
  });
});
```

#### BLoC Testing
```dart
group('AuthBloc Social Login', () {
  late AuthBloc bloc;
  late MockSocialAuthRepository mockRepository;
  
  setUp(() {
    mockRepository = MockSocialAuthRepository();
    bloc = AuthBloc(socialAuthRepository: mockRepository);
  });
  
  blocTest<AuthBloc, AuthState>(
    'should emit authenticated state on successful social login',
    build: () {
      when(mockRepository.signInWithGoogle())
          .thenAnswer((_) async => Right(mockUser));
      when(mockRepository.hasUserProfile(any))
          .thenAnswer((_) async => true);
      return bloc;
    },
    act: (bloc) => bloc.add(const AuthSocialLoginRequested('google')),
    expect: () => [
      const AuthSocialLoginInProgress(SocialAuthProvider.google),
      AuthAuthenticated(mockUser, mockProfile),
    ],
  );
});
```

### Widget Testing

```dart
group('SocialLoginButton', () {
  testWidgets('should display Google button correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialLoginButton(
            provider: SocialAuthProvider.google,
            onPressed: () {},
          ),
        ),
      ),
    );
    
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });
  
  testWidgets('should show loading state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialLoginButton(
            provider: SocialAuthProvider.google,
            onPressed: () {},
            isLoading: true,
          ),
        ),
      ),
    );
    
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });
});
```

### Integration Testing

```dart
group('Social Login Integration Tests', () {
  testWidgets('complete Google OAuth flow for new user', (tester) async {
    // Setup test app
    await tester.pumpWidget(MyApp());
    
    // Navigate to login
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();
    
    // Tap Google sign-in
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    
    // Simulate OAuth callback
    await simulateOAuthCallback();
    await tester.pumpAndSettle();
    
    // Verify navigation to profile setup
    expect(find.text('Complete Your Profile'), findsOneWidget);
    
    // Fill profile form
    await tester.enterText(find.byKey(const Key('display_name')), 'John Doe');
    await tester.tap(find.byKey(const Key('currency_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VND'));
    await tester.pumpAndSettle();
    
    // Submit profile
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    
    // Verify navigation to main app
    expect(find.text('Welcome'), findsOneWidget);
  });
});
```

### Property-Based Testing

```dart
group('Social Login Properties', () {
  test('OAuth flow should always complete within timeout', () {
    final random = Random();
    
    for (int i = 0; i < 100; i++) {
      // Generate random test conditions
      final provider = random.nextBool() 
          ? SocialAuthProvider.google 
          : SocialAuthProvider.apple;
      
      // Test OAuth flow with timeout
      final stopwatch = Stopwatch()..start();
      
      // Simulate OAuth flow
      simulateOAuthFlow(provider);
      
      stopwatch.stop();
      
      // Property: Should complete within 10 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    }
  });
  
  test('Profile setup should preserve OAuth data', () {
    for (int i = 0; i < 100; i++) {
      // Generate random OAuth user data
      final oauthUser = generateRandomOAuthUser();
      
      // Create profile setup data
      final profileData = ProfileSetupData.fromOAuthUser(oauthUser);
      
      // Property: Email should be preserved and read-only
      expect(profileData.email, equals(oauthUser.email));
      expect(profileData.isEmailReadOnly, isTrue);
      
      // Property: Display name should be pre-filled if available
      if (oauthUser.displayName != null) {
        expect(profileData.displayName, equals(oauthUser.displayName));
      }
    }
  });
});
```

## Configuration Requirements

### Supabase Configuration

#### Google OAuth Setup
1. **Google Cloud Console**:
   - Create OAuth 2.0 Client ID
   - Add authorized redirect URIs:
     - `https://[project-id].supabase.co/auth/v1/callback`
   - Download client configuration

2. **Supabase Dashboard**:
   - Navigate to Authentication → Providers
   - Enable Google provider
   - Add Client ID and Client Secret
   - Set redirect URL

#### Apple OAuth Setup
1. **Apple Developer Portal**:
   - Create Services ID
   - Configure Sign In with Apple
   - Add redirect URLs:
     - `https://[project-id].supabase.co/auth/v1/callback`
   - Generate private key (.p8 file)

2. **Supabase Dashboard**:
   - Navigate to Authentication → Providers
   - Enable Apple provider
   - Add Services ID, Team ID, Key ID
   - Upload private key file

### Flutter Configuration

#### Android Configuration
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme">
    
    <!-- Existing intent filters -->
    
    <!-- OAuth deep link intent filter -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="io.supabase.grex"
              android:host="login-callback" />
    </intent-filter>
</activity>
```

#### iOS Configuration
```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>io.supabase.grex</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.grex</string>
        </array>
    </dict>
</array>
```

#### Dependencies
```yaml
# pubspec.yaml
dependencies:
  supabase_flutter: ^2.0.0
  app_links: ^6.0.0
  flutter_svg: ^2.0.0
  
dev_dependencies:
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

### Environment Variables
```env
# .env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# OAuth Configuration (optional, configured in Supabase Dashboard)
GOOGLE_CLIENT_ID=your-google-client-id
APPLE_SERVICES_ID=your-apple-services-id
```

## Common Issues and Solutions

### Issue 1: OAuth Callback Not Working

**Symptoms:**
- OAuth flow starts but never completes
- App doesn't receive deep link callback
- User stuck on OAuth provider screen

**Solutions:**
1. **Check Deep Link Configuration**:
   ```bash
   # Test deep link on Android
   adb shell am start \
     -W -a android.intent.action.VIEW \
     -d "io.supabase.grex://login-callback/?access_token=test" \
     com.example.grex
   ```

2. **Verify Redirect URLs**:
   - Supabase: `https://[project-id].supabase.co/auth/v1/callback`
   - OAuth Provider: Must match exactly

3. **Check App Links Configuration**:
   ```xml
   <!-- Ensure android:autoVerify="true" -->
   <intent-filter android:autoVerify="true">
   ```

### Issue 2: Session Not Persisting

**Symptoms:**
- User signs in successfully but session is lost on app restart
- User has to sign in again every time

**Solutions:**
1. **Check Session Storage**:
   ```dart
   // Verify Supabase client initialization
   await Supabase.initialize(
     url: supabaseUrl,
     anonKey: supabaseAnonKey,
     authOptions: const FlutterAuthClientOptions(
       authFlowType: AuthFlowType.pkce, // Important for mobile
     ),
   );
   ```

2. **Verify Session Restoration**:
   ```dart
   // In main app initialization
   final session = Supabase.instance.client.auth.currentSession;
   if (session != null) {
     // Restore authenticated state
   }
   ```

### Issue 3: Profile Setup Not Showing

**Symptoms:**
- OAuth completes but user goes directly to main app
- New users don't see profile setup screen

**Solutions:**
1. **Check Profile Existence Logic**:
   ```dart
   Future<bool> hasUserProfile(String userId) async {
     final result = await _userRepository.getUserProfile(userId);
     return result.fold(
       (failure) => false, // Important: return false on failure
       (profile) => true,
     );
   }
   ```

2. **Verify AuthBloc State Transitions**:
   ```dart
   // Ensure proper state emission
   if (!hasProfile) {
     emit(AuthProfileSetupRequired(
       user: user,
       provider: provider,
       displayName: user.oauthDisplayName,
       email: user.email,
     ));
   }
   ```

### Issue 4: Account Linking Not Working

**Symptoms:**
- Users with existing accounts can't link social providers
- Account linking dialog doesn't appear

**Solutions:**
1. **Check Email Matching Logic**:
   ```dart
   // Verify email comparison is case-insensitive
   final emailCheckResult = await userRepository
       .getUserProfileByEmail(user.email.toLowerCase());
   ```

2. **Verify Dialog Trigger**:
   ```dart
   // Ensure dialog is shown for matching emails
   if (existingProfile != null) {
     emit(AuthAccountLinkingRequired(
       newUser: user,
       existingProfile: existingProfile,
       provider: provider,
     ));
   }
   ```

### Issue 5: Performance Issues

**Symptoms:**
- OAuth flow takes too long to complete
- App becomes unresponsive during authentication

**Solutions:**
1. **Optimize Deep Link Processing**:
   ```dart
   // Use optimized polling with shorter intervals
   Future<User?> _waitForAuthUserOptimized() async {
     const maxAttempts = 40; // 40 * 250ms = 10 seconds
     const pollInterval = Duration(milliseconds: 250);
     
     for (var attempt = 0; attempt < maxAttempts; attempt++) {
       final user = _supabaseClient.auth.currentUser;
       if (user != null) return user;
       await Future.delayed(pollInterval);
     }
     return null;
   }
   ```

2. **Use Performance Monitoring**:
   ```dart
   return _performanceService.measureOperation(
     name: 'oauth_google_signin',
     attributes: {'provider': 'google'},
     operation: () => _performOAuthSignIn(...),
   );
   ```

### Issue 6: Localization Problems

**Symptoms:**
- Social login buttons show English text in other locales
- Error messages not localized

**Solutions:**
1. **Verify ARB Files**:
   ```json
   // Ensure all locales have social login strings
   {
     "continueWithGoogle": "Continue with Google",
     "continueWithApple": "Continue with Apple"
   }
   ```

2. **Check Context Usage**:
   ```dart
   // Use context.l10n instead of hardcoded strings
   Text(context.l10n.continueWithGoogle)
   ```

3. **Regenerate Localizations**:
   ```bash
   flutter gen-l10n
   ```

## Performance Optimization

### OAuth Flow Performance
- **Target**: < 5 seconds after user authorization
- **Optimization**: Use external browser launch mode
- **Monitoring**: Track completion times with PerformanceService

### Deep Link Processing
- **Target**: < 1 second processing time
- **Optimization**: Minimize async operations in callback handler
- **Monitoring**: Log processing times in debug mode

### UI Responsiveness
- **Loading States**: Show progress indicators during OAuth
- **Minimal Redraws**: Avoid unnecessary widget rebuilds
- **Caching**: Cache provider icons and user data

### Memory Management
- **Dispose Resources**: Clean up deep link handlers
- **Avoid Leaks**: Cancel subscriptions and timers
- **Optimize Images**: Use SVG icons for scalability

## Security Considerations

### OAuth Scopes
- **Minimal Scopes**: Request only email and profile
- **Documentation**: Document scope requirements
- **Validation**: Verify scopes in tests

### Token Handling
- **HTTPS Only**: All OAuth communication over HTTPS
- **Secure Storage**: Use Supabase secure storage
- **No Logging**: Never log or expose tokens

### Deep Link Security
- **Validation**: Verify callback URLs are legitimate
- **Scheme Protection**: Use app-specific URL scheme
- **Error Handling**: Don't expose sensitive data in errors

### Privacy Compliance
- **Data Minimization**: Collect only necessary data
- **User Consent**: Clear consent for data collection
- **Deletion**: Support account and data deletion

## Debugging Tools

### Debug Logging
```dart
void debugSocialLogin(String message) {
  if (kDebugMode) {
    print('[SOCIAL_LOGIN] $message');
  }
}
```

### Performance Monitoring
```dart
class SocialLoginDebugger {
  static void logOAuthStart(SocialAuthProvider provider) {
    debugSocialLogin('OAuth started for ${provider.name}');
  }
  
  static void logOAuthComplete(SocialAuthProvider provider, Duration duration) {
    debugSocialLogin('OAuth completed for ${provider.name} in ${duration.inMilliseconds}ms');
  }
  
  static void logDeepLinkReceived(Uri uri) {
    debugSocialLogin('Deep link received: ${uri.toString()}');
  }
}
```

### Test Utilities
```dart
class SocialLoginTestUtils {
  static User createMockOAuthUser({
    String? email,
    String? displayName,
    SocialAuthProvider? provider,
  }) {
    return User(
      id: 'test-user-id',
      email: email ?? 'test@example.com',
      emailConfirmed: true,
      createdAt: DateTime.now(),
      userMetadata: {
        'full_name': displayName ?? 'Test User',
      },
      appMetadata: {
        'providers': [provider?.name ?? 'google'],
      },
    );
  }
  
  static void simulateOAuthCallback() {
    // Simulate deep link callback for testing
  }
}
```

## Best Practices

### Code Organization
- **Feature-based**: Organize by authentication feature
- **Clean Architecture**: Separate domain, data, and presentation
- **Dependency Injection**: Use get_it for dependency management

### Error Handling
- **Functional Approach**: Use Either<Failure, Success> pattern
- **User-friendly Messages**: Map technical errors to user messages
- **Graceful Degradation**: Provide fallback options

### Testing
- **Test Pyramid**: Unit tests > Widget tests > Integration tests
- **Property-based**: Test with random data and edge cases
- **Performance Tests**: Verify timing requirements

### Documentation
- **API Documentation**: Document all public methods
- **Usage Examples**: Provide clear usage examples
- **Architecture Decisions**: Document design choices

This developer guide provides comprehensive information for working with the social login feature. For specific implementation details, refer to the code documentation and test files.