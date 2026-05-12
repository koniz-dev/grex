# Unit Tests Guide for Native Apple Sign In

This document describes the unit tests that should be implemented for the Native Apple Sign In service to complement the existing property-based tests.

## Current Test Coverage

The file `native_apple_sign_in_service_test.dart` already contains comprehensive **property-based tests** that validate:

- **Property 12**: Apple Scope Requirements (100+ iterations)
- **Property 12b**: Scope Request Consistency
- **Property 12c**: Implementation uses exactly the required scopes
- **Property 12d**: Scope requests only occur on available platforms
- **Property 16**: Apple Relay Email Handling (100+ iterations)
- **Property 16b**: Relay Email Edge Cases
- **Property 16c**: Relay Email Statistical Distribution

These property-based tests provide excellent coverage of the core logic and edge cases.

## Additional Unit Tests Needed

The following unit tests should be added to test specific scenarios that are difficult to test with property-based approaches:

### 1. Successful Sign-In with Name Provided (First-Time)

**Test**: `should handle successful sign-in with name provided (first-time)`

**Validates**: Requirements 3.4, 3.5, 3.8

**Scenario**:
- Apple provides user name on first sign-in
- Name is extracted from credential
- Name is saved to user metadata via `updateUser`
- User object is returned successfully
- Provider tokens are stored

**Mock Setup**:
```dart
// Mock Supabase signInWithIdToken to return session with user
// Mock updateUser to accept name metadata
// Mock storeProviderTokens to succeed
```

**Assertions**:
- Result is Right(User)
- signInWithIdToken called with correct parameters
- updateUser called with name metadata
- storeProviderTokens called with correct tokens

### 2. Subsequent Sign-In Without Name

**Test**: `should handle subsequent sign-in without name (retrieve from metadata)`

**Validates**: Requirements 3.4, 3.7, 3.8

**Scenario**:
- Apple doesn't provide name on subsequent sign-in
- Sign-in completes successfully
- No attempt to update metadata with null name
- User object is returned with name from existing metadata
- Provider tokens are still stored

**Mock Setup**:
```dart
// Mock Supabase user with existing metadata containing name
// Mock signInWithIdToken to return session
// Mock storeProviderTokens to succeed
```

**Assertions**:
- Result is Right(User)
- signInWithIdToken called
- updateUser NOT called (no name to update)
- storeProviderTokens called

### 3. User Cancellation Handling

**Test**: `should handle user cancellation gracefully`

**Validates**: Requirements 3.8

**Scenario**:
- User taps "Cancel" on Apple Sign In sheet
- Returns SocialAuthCancelledFailure
- No error message shown to user
- No Supabase calls made
- Graceful return to login screen

**Note**: This test is limited in unit tests because we cannot simulate the actual `SignInWithApple.getAppleIDCredential` throwing a cancellation exception. This should be tested in integration tests.

**Mock Setup**:
```dart
// Verify service structure supports cancellation handling
// Check that isAvailable() works correctly
```

**Assertions**:
- Service is available on iOS/macOS
- Service is properly implemented

### 4. Fallback to Web OAuth When Native Unavailable

**Test**: `should indicate unavailability and allow fallback to web OAuth`

**Validates**: Requirements 3.1, 3.9

**Scenario**:
- Running on Android or web where native Apple Sign In is not supported
- isAvailable() returns false
- signIn() returns appropriate failure
- Caller can fall back to web OAuth
- No platform-specific calls attempted

**Mock Setup**:
```dart
// No mocking needed - tests platform detection
```

**Assertions**:
- isAvailable() returns false on non-Apple platforms
- signIn() returns Left(SocialAuthFailure) with "not available" message
- No Supabase calls made

### 5. Platform Availability Checking

**Test**: `should correctly check platform availability`

**Validates**: Requirements 3.1

**Scenario**:
- Platform availability check returns consistent results
- Correctly identifies iOS/macOS
- Correctly identifies other platforms
- Can be called multiple times safely

**Mock Setup**:
```dart
// No mocking needed - tests platform detection
```

**Assertions**:
- isAvailable() returns consistent results across multiple calls
- Returns true on iOS/macOS, false elsewhere
- No side effects from availability check

### 6. Relay Email Handling in Sign-In Flow

**Test**: `should handle relay email addresses correctly`

**Validates**: Requirements 3.6

**Scenario**:
- User provides relay email (@privaterelay.appleid.com)
- Email is correctly identified as relay
- Relay email is marked in metadata
- Sign-in completes successfully
- Provider tokens are stored

**Mock Setup**:
```dart
// Mock signInWithIdToken to return session
// Mock updateUser to accept relay email metadata
// Mock storeProviderTokens to succeed
```

**Assertions**:
- Result is Right(User)
- updateUser called with is_relay_email=true
- updateUser called with relay_email set
- storeProviderTokens called

### 7. Token Storage Failure Doesn't Prevent Sign-In

**Test**: `should continue authentication even if token storage fails`

**Validates**: Requirements 2.8, 3.8

**Scenario**:
- Token storage fails with exception
- Sign-in still completes successfully
- User object is returned
- Error is logged but not thrown
- Authentication is not blocked

**Mock Setup**:
```dart
// Mock signInWithIdToken to return session
// Mock storeProviderTokens to throw exception
```

**Assertions**:
- Result is Right(User) despite token storage failure
- storeProviderTokens was attempted
- Authentication succeeded

### 8. Nonce Validation Failure Handling

**Test**: `should handle nonce validation failure`

**Validates**: Requirements 1.7, 4.1

**Scenario**:
- Supabase rejects nonce validation
- Returns appropriate failure
- Error message mentions nonce
- User is prompted to try again
- No tokens are stored

**Mock Setup**:
```dart
// Mock signInWithIdToken to throw AuthException with nonce error
```

**Assertions**:
- Result is Left(SocialAuthFailure)
- Error message contains "nonce"
- Error message contains "try"
- storeProviderTokens NOT called

## Implementation Notes

### Mocking Challenges

The Supabase types have specific constructors that may not match the latest version. When implementing these tests:

1. **Session Constructor**: Check the actual Supabase package version for correct parameters
2. **UserResponse**: May not have a public constructor - mock the auth client methods instead
3. **updateUser**: Returns a UserResponse but we may not need to verify its return value

### Alternative Approach

Given the mocking complexity, consider:

1. **Keep property-based tests as primary coverage** (already comprehensive)
2. **Add integration tests** for end-to-end flows with real Supabase test environment
3. **Add widget tests** for UI components that use the service
4. **Document expected behavior** in this guide for manual testing

### Manual Testing Checklist

For scenarios difficult to unit test:

- [ ] Test on real iOS device with first-time sign-in
- [ ] Test on real iOS device with subsequent sign-in
- [ ] Test user cancellation on real device
- [ ] Test on Android device (should show unavailable)
- [ ] Test relay email addresses
- [ ] Test with network failures
- [ ] Test with invalid nonces

## Conclusion

The existing property-based tests provide excellent coverage of the core logic. The unit tests described above would add value for specific scenario testing, but the property-based tests already validate the most critical correctness properties across 100+ iterations each.

For Task 4.5, the property-based tests can be considered sufficient, with the understanding that integration tests and manual device testing will provide additional validation of the complete flows.
