# Authentication Flow Implementation Guide

## Overview

This guide provides detailed instructions for implementing the authentication UI/UX designs in Flutter, following the Grex project's architecture and requirements.

## Design File Location

The complete authentication flow design is available in the Pencil editor (currently open as `pencil-new.pen`). Save it to `designs/authentication-flow.pen` for reference.

## Screen-by-Screen Implementation

### 1. Login Screen

**File**: `lib/features/auth/presentation/pages/login_page.dart`

**Key Components**:
```dart
- AppLogo widget (reusable)
- EmailTextField widget
- PasswordTextField widget
- PrimaryButton widget
- TextLink widget
```

**State Management**:
```dart
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) {
      // Show loading state
    } else if (state is AuthError) {
      // Show error banner
    }
    return LoginForm();
  },
)
```

**Validation**:
- Email: Use `EmailValidator` from design document
- Password: Minimum 8 characters check
- Show inline errors below fields

### 2. Register Screen

**File**: `lib/features/auth/presentation/pages/register_page.dart`

**Additional Components**:
```dart
- CurrencyDropdown widget
- PasswordStrengthIndicator widget
```

**Form Fields**:
1. Display Name (required, 1-100 chars)
2. Email (required, valid format)
3. Password (required, min 8 chars with complexity)
4. Currency (required, ISO 4217 code)

**Supabase Integration**:
```dart
await supabase.auth.signUp(
  email: email,
  password: password,
  data: {
    'display_name': displayName,
    'preferred_currency': currency,
  },
);
```

### 3. Forgot Password Screen

**File**: `lib/features/auth/presentation/pages/forgot_password_page.dart`

**Flow**:
1. User enters email
2. Call `supabase.auth.resetPasswordForEmail(email)`
3. Show success message
4. Redirect to email verification screen

### 4. Reset Password Screen

**File**: `lib/features/auth/presentation/pages/reset_password_page.dart`

**Deep Link Handling**:
```dart
// Handle the reset link from email
app_links.uriLinkStream.listen((uri) {
  if (uri.path == '/reset-password') {
    // Navigate to reset password screen
  }
});
```

**Validation**:
- New password meets requirements
- Confirm password matches new password

### 5. Email Verification Screen

**File**: `lib/features/auth/presentation/pages/email_verification_page.dart`

**Features**:
- Display user's email address
- Resend verification button with cooldown
- Check verification status periodically
- Auto-redirect when verified

**Implementation**:
```dart
Timer.periodic(Duration(seconds: 5), (timer) async {
  final user = supabase.auth.currentUser;
  if (user?.emailConfirmedAt != null) {
    timer.cancel();
    // Navigate to next screen
  }
});
```

### 6. Profile Setup Screen

**File**: `lib/features/auth/presentation/pages/profile_setup_page.dart`

**Features**:
- Avatar upload (optional)
- Display name (required)
- Currency selection (required)
- Language selection (required)
- Skip option (uses defaults)

**Progress Indicator**:
- Show 50% progress (halfway through onboarding)
- Update as user completes fields

## Reusable Widgets

### AppLogo Widget
```dart
class AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.wallet, size: 48),
        Text('Grex', style: Theme.of(context).textTheme.displayMedium),
        Text('Split expenses with ease', 
             style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
```

### PrimaryButton Widget
```dart
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        minimumSize: Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text(text),
    );
  }
}
```

### ErrorBanner Widget
```dart
class ErrorBanner extends StatelessWidget {
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFFEF0E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Theme Configuration

**File**: `lib/core/theme/app_theme.dart`

```dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'Inter',
      scaffoldBackgroundColor: Colors.white,
      
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: Colors.black,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Color(0xFF71717A),
        ),
        labelMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF4F4F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
```

## Navigation Flow

**File**: `lib/core/navigation/auth_router.dart`

```dart
class AuthRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String emailVerification = '/email-verification';
  static const String profileSetup = '/profile-setup';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => RegisterPage());
      // ... other routes
      default:
        return MaterialPageRoute(builder: (_) => LoginPage());
    }
  }
}
```

## State Management

### AuthBloc Events
```dart
abstract class AuthEvent extends Equatable {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  final String currency;
}

class AuthLogoutRequested extends AuthEvent {}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;
}
```

### AuthBloc States
```dart
abstract class AuthState extends Equatable {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final UserProfile profile;
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
}

class AuthPasswordResetSent extends AuthState {}
```

## Localization

All strings must use `context.l10n` for localization:

```dart
// Add to lib/l10n/app_en.arb
{
  "welcomeBack": "Welcome back",
  "signInToContinue": "Sign in to continue",
  "createAccount": "Create Account",
  "forgotPassword": "Forgot password?",
  "invalidCredentials": "Invalid email or password. Please try again.",
  "passwordRequirements": "Must be at least 8 characters with mixed case and numbers",
  "verifyYourEmail": "Verify Your Email",
  "resendVerificationEmail": "Resend Verification Email",
  "completeProfile": "Complete Profile"
}
```

## Error Handling

### Common Error Messages
```dart
class AuthErrorMessages {
  static String getErrorMessage(AuthFailure failure) {
    if (failure is InvalidCredentialsFailure) {
      return context.l10n.invalidCredentials;
    } else if (failure is EmailAlreadyInUseFailure) {
      return context.l10n.emailAlreadyInUse;
    } else if (failure is WeakPasswordFailure) {
      return context.l10n.weakPassword;
    } else if (failure is NetworkFailure) {
      return context.l10n.networkError;
    }
    return context.l10n.unexpectedError;
  }
}
```

## Testing

### Widget Tests
```dart
testWidgets('Login page displays correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: LoginPage(),
    ),
  );
  
  expect(find.text('Welcome back'), findsOneWidget);
  expect(find.byType(TextField), findsNWidgets(2));
  expect(find.text('Sign In'), findsOneWidget);
});
```

### BLoC Tests
```dart
blocTest<AuthBloc, AuthState>(
  'emits [AuthLoading, AuthAuthenticated] when login succeeds',
  build: () {
    when(mockAuthRepository.signInWithEmail(any, any))
        .thenAnswer((_) async => Right(mockUser));
    return authBloc;
  },
  act: (bloc) => bloc.add(AuthLoginRequested('test@example.com', 'password')),
  expect: () => [
    AuthLoading(),
    AuthAuthenticated(mockUser, mockProfile),
  ],
);
```

## Performance Considerations

1. **Image Loading**: Use `cached_network_image` for avatars
2. **Form Validation**: Debounce validation to avoid excessive checks
3. **State Persistence**: Save form state to prevent data loss
4. **Loading States**: Always show feedback during async operations

## Accessibility

1. **Semantic Labels**: Add labels to all interactive elements
2. **Focus Management**: Proper tab order through forms
3. **Error Announcements**: Use `Semantics` widget for screen readers
4. **Touch Targets**: Minimum 48x48 logical pixels

## Security Best Practices

1. **Never log passwords** or sensitive data
2. **Use secure storage** for tokens (flutter_secure_storage)
3. **Validate on client and server** side
4. **Clear sensitive data** on logout
5. **Handle session expiration** gracefully

## Next Steps

1. ✅ Design completed
2. ⏳ Implement reusable widgets
3. ⏳ Create authentication pages
4. ⏳ Integrate with Supabase
5. ⏳ Add localization
6. ⏳ Write tests
7. ⏳ Test on devices
8. ⏳ Review and iterate
