# OAuth Testing Procedures for Grex

## Overview

This document provides comprehensive testing procedures for validating Google and Apple OAuth configurations in the Grex app.

## Pre-Testing Setup

### Test Accounts Required

**Google OAuth Testing:**
- Personal Google account for testing
- Test Google account (optional, for edge cases)
- Google Workspace account (optional, for enterprise testing)

**Apple OAuth Testing:**
- Personal Apple ID for testing
- Test Apple ID (create specifically for testing)
- Apple Developer account for configuration

### Development Environment

Ensure your development environment is ready:

```bash
# Verify Flutter setup
flutter doctor

# Install dependencies
flutter pub get

# Verify Supabase connection
flutter test test/core/supabase_test.dart
```

## Google OAuth Testing

### Test 1: Basic Google Sign In Flow

**Objective**: Verify complete Google OAuth flow works end-to-end

**Steps:**
1. Launch the app in debug mode
2. Navigate to login screen
3. Tap "Continue with Google" button
4. Verify browser opens with Google consent screen
5. Sign in with test Google account
6. Grant requested permissions (email, profile)
7. Verify redirect back to app
8. Confirm user is authenticated in app

**Expected Results:**
- ✅ Google consent screen displays correctly
- ✅ User can sign in successfully
- ✅ App receives user profile data (name, email)
- ✅ User is redirected to main app screen
- ✅ Session persists across app restarts

**Test Data:**
```
Test Account: test.grex.user@gmail.com
Expected Name: Test Grex User
Expected Email: test.grex.user@gmail.com
```

### Test 2: Google Sign In Cancellation

**Objective**: Verify graceful handling when user cancels OAuth flow

**Steps:**
1. Launch the app
2. Tap "Continue with Google" button
3. When Google consent screen appears, tap "Cancel" or close browser
4. Verify app handles cancellation gracefully

**Expected Results:**
- ✅ No error message displayed
- ✅ User returns to login screen
- ✅ Can retry Google sign in
- ✅ No crash or unexpected behavior

### Test 3: Google Sign In Error Handling

**Objective**: Test error scenarios and network issues

**Steps:**
1. Disable internet connection
2. Tap "Continue with Google" button
3. Verify error handling
4. Re-enable internet and retry

**Expected Results:**
- ✅ Network error displayed with retry option
- ✅ Retry works after connection restored
- ✅ User-friendly error messages
- ✅ No app crashes

### Test 4: Google Account Switching

**Objective**: Test signing in with different Google accounts

**Steps:**
1. Sign in with first Google account
2. Sign out from app
3. Sign in with different Google account
4. Verify correct account data is used

**Expected Results:**
- ✅ First account data cleared on sign out
- ✅ Second account data loaded correctly
- ✅ No data mixing between accounts
- ✅ Profile information updates correctly

## Apple OAuth Testing

### Test 5: Basic Apple Sign In Flow

**Objective**: Verify complete Apple OAuth flow works end-to-end

**Steps:**
1. Launch the app on iOS device/simulator
2. Navigate to login screen
3. Tap "Continue with Apple" button
4. Verify Apple Sign In screen appears
5. Sign in with test Apple ID
6. Choose email sharing preference
7. Verify redirect back to app
8. Confirm user is authenticated in app

**Expected Results:**
- ✅ Apple Sign In screen displays correctly
- ✅ User can sign in successfully
- ✅ App receives user profile data
- ✅ Email hiding option works if selected
- ✅ User is redirected to main app screen

**Test Data:**
```
Test Apple ID: test.grex@icloud.com
Expected Name: Test Grex (or hidden)
Expected Email: test.grex@icloud.com (or relay email)
```

### Test 6: Apple Email Hiding

**Objective**: Test Apple's email hiding feature

**Steps:**
1. Sign in with Apple ID
2. Choose "Hide My Email" option
3. Complete sign in flow
4. Verify app handles relay email correctly

**Expected Results:**
- ✅ Relay email received (format: random@privaterelay.appleid.com)
- ✅ App accepts relay email as valid
- ✅ User profile created with relay email
- ✅ No errors with non-standard email format

### Test 7: Apple Sign In Cancellation

**Objective**: Verify graceful handling when user cancels Apple OAuth

**Steps:**
1. Launch the app
2. Tap "Continue with Apple" button
3. When Apple Sign In screen appears, tap "Cancel"
4. Verify app handles cancellation gracefully

**Expected Results:**
- ✅ No error message displayed
- ✅ User returns to login screen
- ✅ Can retry Apple sign in
- ✅ No crash or unexpected behavior

## Cross-Platform Testing

### Test 8: Multi-Platform Consistency

**Objective**: Verify OAuth works consistently across platforms

**Platforms to Test:**
- Android device
- iOS device
- Web browser (if supported)

**Steps:**
1. Test Google OAuth on each platform
2. Test Apple OAuth on iOS
3. Verify consistent user experience
4. Test session synchronization

**Expected Results:**
- ✅ Consistent UI across platforms
- ✅ Same OAuth flow behavior
- ✅ Proper platform-specific handling
- ✅ Session data syncs correctly

## Integration Testing

### Test 9: New User Profile Setup

**Objective**: Test profile setup flow for new social login users

**Steps:**
1. Sign in with new Google/Apple account (never used before)
2. Verify profile setup screen appears
3. Complete profile setup with required information
4. Verify user profile created correctly

**Expected Results:**
- ✅ Profile setup screen displays
- ✅ Email and name pre-filled from OAuth
- ✅ User can complete profile setup
- ✅ Profile saved to database correctly

### Test 10: Account Linking

**Objective**: Test linking social account to existing email account

**Steps:**
1. Create account with email/password
2. Sign out
3. Sign in with Google/Apple using same email
4. Verify account linking prompt appears
5. Confirm account linking
6. Verify accounts are linked

**Expected Results:**
- ✅ Account linking detected
- ✅ Confirmation dialog appears
- ✅ User can link accounts
- ✅ Can sign in with either method after linking

### Test 11: Session Persistence

**Objective**: Test OAuth session persistence across app restarts

**Steps:**
1. Sign in with Google/Apple
2. Close app completely
3. Reopen app
4. Verify user remains authenticated

**Expected Results:**
- ✅ User remains signed in after app restart
- ✅ No need to re-authenticate
- ✅ Profile data available immediately
- ✅ OAuth tokens refreshed automatically

## Performance Testing

### Test 12: OAuth Flow Performance

**Objective**: Measure OAuth flow performance and responsiveness

**Metrics to Measure:**
- Time from button tap to browser opening
- Time from OAuth completion to app redirect
- App responsiveness during OAuth flow

**Steps:**
1. Measure OAuth initiation time
2. Measure callback processing time
3. Test with slow network conditions
4. Verify UI remains responsive

**Expected Results:**
- ✅ OAuth initiation < 2 seconds
- ✅ Callback processing < 3 seconds
- ✅ UI remains responsive throughout
- ✅ Graceful handling of slow networks

## Security Testing

### Test 13: OAuth Security Validation

**Objective**: Verify OAuth implementation follows security best practices

**Security Checks:**
- Redirect URI validation
- State parameter usage (if applicable)
- Token storage security
- Scope minimization

**Steps:**
1. Verify only necessary scopes requested
2. Check redirect URI matches configuration
3. Verify tokens stored securely
4. Test with invalid redirect attempts

**Expected Results:**
- ✅ Only email and profile scopes requested
- ✅ Redirect URI validation works
- ✅ Tokens stored in secure storage
- ✅ Invalid redirects rejected

## Automated Testing

### Test Suite Execution

Run the automated test suite to validate OAuth implementation:

```bash
# Run OAuth-specific tests
flutter test test/features/auth/oauth/

# Run social login integration tests
flutter test test/features/auth/social_login/

# Run all authentication tests
flutter test test/features/auth/

# Run with coverage
flutter test --coverage test/features/auth/
```

### Property-Based Tests

Execute property-based tests for OAuth flows:

```bash
# Run OAuth property tests
flutter test test/features/auth/oauth_properties_test.dart

# Run social login property tests
flutter test test/features/auth/social_login_properties_test.dart
```

## Test Reporting

### Test Results Template

Use this template to document test results:

```markdown
## OAuth Testing Results

**Date**: [Test Date]
**Tester**: [Tester Name]
**Environment**: [Development/Staging/Production]
**Platform**: [Android/iOS/Web]

### Google OAuth Results
- [ ] Basic sign in flow: PASS/FAIL
- [ ] Cancellation handling: PASS/FAIL
- [ ] Error handling: PASS/FAIL
- [ ] Account switching: PASS/FAIL

### Apple OAuth Results
- [ ] Basic sign in flow: PASS/FAIL
- [ ] Email hiding: PASS/FAIL
- [ ] Cancellation handling: PASS/FAIL

### Integration Results
- [ ] New user profile setup: PASS/FAIL
- [ ] Account linking: PASS/FAIL
- [ ] Session persistence: PASS/FAIL

### Issues Found
1. [Issue description]
2. [Issue description]

### Recommendations
1. [Recommendation]
2. [Recommendation]
```

## Troubleshooting Test Failures

### Common Test Failures

**"redirect_uri_mismatch" Error:**
- Verify Supabase project ID is correct
- Check redirect URI in provider configuration
- Ensure HTTPS is used

**"invalid_client" Error:**
- Verify OAuth credentials in Supabase dashboard
- Check that required APIs are enabled
- Ensure OAuth consent screen is configured

**App Crashes on OAuth Callback:**
- Check deep link configuration
- Verify app_links package is properly configured
- Test deep link handling separately

**Session Not Persisting:**
- Verify Supabase client initialization
- Check token storage configuration
- Test session refresh logic

### Debug Tools

Use these tools for debugging OAuth issues:

```dart
// Enable OAuth debug logging
import 'package:flutter/foundation.dart';

void debugOAuth(String message) {
  if (kDebugMode) {
    print('[OAUTH DEBUG] $message');
  }
}

// Log OAuth events
void logOAuthEvent(String event, Map<String, dynamic> data) {
  debugOAuth('$event: ${data.toString()}');
}
```

## Test Environment Cleanup

After testing, clean up test data:

```sql
-- Remove test users (if needed)
DELETE FROM auth.users WHERE email LIKE '%test.grex%';

-- Remove test profiles
DELETE FROM users WHERE email LIKE '%test.grex%';
```

## Continuous Testing

### CI/CD Integration

Add OAuth testing to your CI/CD pipeline:

```yaml
# .github/workflows/oauth_test.yml
name: OAuth Tests
on: [push, pull_request]

jobs:
  oauth_tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      
      - name: Install dependencies
        run: flutter pub get
        
      - name: Run OAuth tests
        run: flutter test test/features/auth/oauth/
        
      - name: Run integration tests
        run: flutter test integration_test/oauth_test.dart
```

## Next Steps

After completing OAuth testing:

1. **Document any issues found** and create tickets for fixes
2. **Update test procedures** based on lessons learned
3. **Automate repetitive tests** where possible
4. **Plan regular regression testing** for OAuth functionality
5. **Prepare for production testing** with real user accounts

## References

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Supabase Auth Testing](https://supabase.com/docs/guides/auth/testing)
- [Google OAuth Testing](https://developers.google.com/identity/protocols/oauth2/testing)
- [Apple Sign In Testing](https://developer.apple.com/documentation/sign_in_with_apple/testing_sign_in_with_apple)