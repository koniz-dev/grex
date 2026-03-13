# Social Login Implementation Guide

## Overview

Grex authentication flow now includes social login options for Google and Apple, providing users with quick and secure authentication alternatives to traditional email/password login.

## Design Integration

### Login Screen
- Social login buttons appear after the password field
- "or" divider separates traditional login from social options
- Google button: White background with gray border
- Apple button: Black background with white text
- Both buttons maintain consistent 48px height

### Register Screen
- Same social login layout as Login screen
- Positioned after currency selector
- Maintains visual consistency across auth flow

## Supabase Configuration

### 1. Enable OAuth Providers in Supabase Dashboard

**Google OAuth**:
1. Go to Supabase Dashboard → Authentication → Providers
2. Enable Google provider
3. Add OAuth credentials from Google Cloud Console
4. Set redirect URL: `https://[your-project].supabase.co/auth/v1/callback`

**Apple OAuth**:
1. Go to Supabase Dashboard → Authentication → Providers
2. Enable Apple provider
3. Add credentials from Apple Developer Console
4. Configure Services ID and Key ID

### 2. Configure Deep Linking

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data
    android:scheme="io.supabase.grex"
    android:host="login-callback" />
</intent-filter>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>io.supabase.grex</string>
    </array>
  </dict>
</array>
```

## Flutter Implementation

### 1. Add Dependencies

```yaml
dependencies:
  supabase_flutter: ^2.9.0
  app_links: ^6.2.0  # For deep linking
  google_sign_in: ^6.1.0  # Optional: for native Google Sign In
  sign_in_with_apple: ^6.1.0  # Optional: for native Apple Sign In
```

### 2. Social Login Repository

```dart
abstract class SocialAuthRepository {
  Future<Either<AuthFailure, User>> signInWithGoogle();
  Future<Either<AuthFailure, User>> signInWithApple();
}

class SocialAuthRepositoryImpl implements SocialAuthRepository {
  final SupabaseClient supabase;
  
  SocialAuthRepositoryImpl(this.supabase);
  
  @override
  Future<Either<AuthFailure, User>> signInWithGoogle() async {
    try {
      final response = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.grex://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      
      if (!response) {
        return Left(SocialAuthCancelledFailure());
      }
      
      // Wait for auth state change
      final user = supabase.auth.currentUser;
      if (user == null) {
        return Left(SocialAuthFailure('Authentication failed'));
      }
      
      return Right(User.fromSupabaseUser(user));
    } catch (e) {
      return Left(SocialAuthFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<AuthFailure, User>> signInWithApple() async {
    try {
      final response = await supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.grex://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      
      if (!response) {
        return Left(SocialAuthCancelledFailure());
      }
      
      final user = supabase.auth.currentUser;
      if (user == null) {
        return Left(SocialAuthFailure('Authentication failed'));
      }
      
      return Right(User.fromSupabaseUser(user));
    } catch (e) {
      return Left(SocialAuthFailure(e.toString()));
    }
  }
}
```

### 3. Handle Deep Link Callbacks

```dart
class AuthDeepLinkHandler {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  
  void initialize(Function(Uri) onLink) {
    // Handle initial link if app was opened from link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        onLink(uri);
      }
    });
    
    // Handle links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      onLink(uri);
    });
  }
  
  void dispose() {
    _linkSubscription?.cancel();
  }
}
```

### 4. Update AuthBloc

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final SocialAuthRepository socialAuthRepository;
  final AuthDeepLinkHandler deepLinkHandler;
  
  AuthBloc({
    required this.authRepository,
    required this.socialAuthRepository,
    required this.deepLinkHandler,
  }) : super(AuthInitial()) {
    on<AuthSocialLoginRequested>(_onSocialLoginRequested);
    
    // Initialize deep link handling
    deepLinkHandler.initialize(_handleDeepLink);
  }
  
  Future<void> _onSocialLoginRequested(
    AuthSocialLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = event.provider == 'google'
        ? await socialAuthRepository.signInWithGoogle()
        : await socialAuthRepository.signInWithApple();
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) async {
        // Check if user profile exists
        final profile = await _getUserProfile(user.id);
        
        if (profile == null) {
          // New user from social login - need to complete profile
          emit(AuthProfileSetupRequired(user));
        } else {
          emit(AuthAuthenticated(user, profile));
        }
      },
    );
  }
  
  void _handleDeepLink(Uri uri) {
    // Supabase handles the OAuth callback automatically
    // Just need to check auth state
    final user = supabase.auth.currentUser;
    if (user != null) {
      add(AuthSessionChecked());
    }
  }
}
```

### 5. UI Implementation

```dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (state is AuthProfileSetupRequired) {
          Navigator.pushNamed(context, '/profile-setup');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  // ... Logo, title, email/password fields ...
                  
                  // Or Divider
                  OrDivider(),
                  
                  SizedBox(height: 12),
                  
                  // Social Login Buttons
                  SocialLoginButton(
                    provider: 'google',
                    onPressed: state is AuthLoading
                        ? null
                        : () => context.read<AuthBloc>().add(
                              AuthSocialLoginRequested('google'),
                            ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  SocialLoginButton(
                    provider: 'apple',
                    onPressed: state is AuthLoading
                        ? null
                        : () => context.read<AuthBloc>().add(
                              AuthSocialLoginRequested('apple'),
                            ),
                  ),
                  
                  // ... Sign In button, Register link ...
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
```

## Profile Completion Flow

When a user signs in with social login for the first time, they may need to complete their profile:

```dart
class AuthProfileSetupRequired extends AuthState {
  final User user;
  
  const AuthProfileSetupRequired(this.user);
}
```

**Profile Setup Screen** should:
1. Pre-fill display name from social provider (if available)
2. Pre-fill email from social provider
3. Ask for currency preference
4. Ask for language preference
5. Optional: avatar from social provider

## Error Handling

### Common Social Login Errors

```dart
class SocialAuthFailure extends AuthFailure {
  const SocialAuthFailure(String message) : super(message);
}

class SocialAuthCancelledFailure extends AuthFailure {
  const SocialAuthCancelledFailure() 
      : super('Sign in was cancelled');
}

class SocialAuthNetworkFailure extends AuthFailure {
  const SocialAuthNetworkFailure() 
      : super('Network error during sign in');
}
```

### User-Friendly Error Messages

```dart
String getSocialAuthErrorMessage(AuthFailure failure) {
  if (failure is SocialAuthCancelledFailure) {
    return context.l10n.socialAuthCancelled;
  } else if (failure is SocialAuthNetworkFailure) {
    return context.l10n.networkError;
  } else if (failure is SocialAuthFailure) {
    return context.l10n.socialAuthFailed;
  }
  return context.l10n.unexpectedError;
}
```

## Localization

Add to `lib/l10n/app_en.arb`:

```json
{
  "continueWithGoogle": "Continue with Google",
  "continueWithApple": "Continue with Apple",
  "or": "or",
  "socialAuthCancelled": "Sign in was cancelled",
  "socialAuthFailed": "Sign in failed. Please try again.",
  "socialAuthNetworkError": "Network error. Please check your connection."
}
```

## Testing

### Unit Tests

```dart
group('Social Auth Repository', () {
  test('signInWithGoogle returns user on success', () async {
    // Arrange
    when(mockSupabase.auth.signInWithOAuth(any, any))
        .thenAnswer((_) async => true);
    when(mockSupabase.auth.currentUser)
        .thenReturn(mockSupabaseUser);
    
    // Act
    final result = await repository.signInWithGoogle();
    
    // Assert
    expect(result.isRight(), true);
  });
  
  test('signInWithGoogle returns failure when cancelled', () async {
    // Arrange
    when(mockSupabase.auth.signInWithOAuth(any, any))
        .thenAnswer((_) async => false);
    
    // Act
    final result = await repository.signInWithGoogle();
    
    // Assert
    expect(result.isLeft(), true);
  });
});
```

### Widget Tests

```dart
testWidgets('Social login buttons trigger correct events', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => mockAuthBloc,
        child: LoginPage(),
      ),
    ),
  );
  
  // Tap Google button
  await tester.tap(find.text('Continue with Google'));
  await tester.pump();
  
  verify(mockAuthBloc.add(AuthSocialLoginRequested('google'))).called(1);
  
  // Tap Apple button
  await tester.tap(find.text('Continue with Apple'));
  await tester.pump();
  
  verify(mockAuthBloc.add(AuthSocialLoginRequested('apple'))).called(1);
});
```

## Security Considerations

1. **OAuth Redirect URI**: Always use HTTPS in production
2. **State Parameter**: Supabase handles CSRF protection automatically
3. **Token Storage**: Supabase stores tokens securely
4. **Scope Permissions**: Request only necessary permissions
5. **User Consent**: Always show what data will be accessed

## Platform-Specific Setup

### Google Sign In

**Android**:
1. Add SHA-1 fingerprint to Firebase Console
2. Download `google-services.json`
3. Place in `android/app/`

**iOS**:
1. Add URL scheme to Info.plist
2. Download `GoogleService-Info.plist`
3. Place in `ios/Runner/`

### Apple Sign In

**iOS**:
1. Enable "Sign in with Apple" capability in Xcode
2. Configure App ID in Apple Developer Console
3. Add Services ID for web authentication

**Android**:
- Apple Sign In works through web flow
- No additional setup required

## Production Checklist

- [ ] OAuth credentials configured in Supabase
- [ ] Deep linking tested on both platforms
- [ ] Profile completion flow implemented
- [ ] Error handling for all scenarios
- [ ] Localization for all social auth strings
- [ ] Analytics tracking for social login events
- [ ] Privacy policy updated with social login info
- [ ] Terms of service updated if needed

## Troubleshooting

### Issue: OAuth popup doesn't open
**Solution**: Check deep link configuration and URL scheme

### Issue: Callback not received
**Solution**: Verify redirect URI matches exactly in Supabase dashboard

### Issue: User data not available
**Solution**: Check OAuth scope permissions in provider settings

### Issue: Works on iOS but not Android
**Solution**: Verify SHA-1 fingerprint and package name in Google Console
