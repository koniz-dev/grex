# Social Login Integration Tests

This directory contains comprehensive integration tests for the social login functionality in Grex. These tests validate complete OAuth flows, error handling, and deep link processing across both Google and Apple OAuth providers.

## Test Structure

### Main Test Files

- **`social_login_integration_test.dart`** - Core OAuth flow tests (Tasks 15.1-15.12)
- **`social_login_error_handling_test.dart`** - Error scenarios and recovery
- **`social_login_deep_link_test.dart`** - Deep link processing validation
- **`social_login_test_runner.dart`** - Comprehensive test suite runner

### Test Helpers

- **`test_helpers/mock_supabase_client.dart`** - Mock Supabase client for testing
- **`test_helpers/test_data_generators.dart`** - Test data generation utilities
- **`test_helpers/oauth_simulator.dart`** - OAuth flow simulation helpers

## Test Coverage

### OAuth Flow Tests (15.1-15.12)

| Test ID | Description | Coverage |
|---------|-------------|----------|
| 15.1 | Google OAuth flow (new user) | Requirements 1.1, 1.2, 1.6, 4.2, 4.3, 4.4, 4.5 |
| 15.2 | Apple OAuth flow (new user) | Requirements 2.1, 2.2, 2.6, 4.2, 4.3, 4.4, 4.5 |
| 15.3 | Google OAuth flow (existing user) | Requirements 1.1, 1.2, 1.5 |
| 15.4 | Apple OAuth flow (existing user) | Requirements 2.1, 2.2, 2.5 |
| 15.5 | Account linking flow | Requirements 5.1, 5.2, 5.3, 5.5 |
| 15.6 | Declined account linking | Requirements 5.1, 5.2, 5.4 |
| 15.7 | Profile setup cancellation | Requirements 4.6 |
| 15.8 | OAuth cancellation | Requirements 1.3, 2.3 |
| 15.9 | Network error handling | Requirements 1.4, 2.4, 8.2 |
| 15.10 | Deep link handling (app closed) | Requirements 3.3 |
| 15.11 | Deep link handling (app running) | Requirements 3.4 |
| 15.12 | Session persistence | Requirements 7.1, 7.2 |

### Error Handling Tests

- Network connectivity issues
- OAuth provider timeouts
- Invalid callback URLs
- Account linking failures
- Profile setup validation errors
- Session expiration scenarios
- Multiple failure recovery

### Deep Link Processing Tests

- App closed state handling
- App running state handling
- Malformed URL validation
- Security parameter validation
- Multiple callback handling
- Timeout scenarios

## Running Tests

### Run All Integration Tests

```bash
# Run complete test suite
flutter test integration_test/social_login_test_runner.dart

# Run with verbose output
flutter test integration_test/social_login_test_runner.dart --verbose
```

### Run Individual Test Suites

```bash
# Run main OAuth flow tests
flutter test integration_test/social_login_integration_test.dart

# Run error handling tests
flutter test integration_test/social_login_error_handling_test.dart

# Run deep link tests
flutter test integration_test/social_login_deep_link_test.dart
```

### Run Specific Test Cases

```bash
# Run specific test by name
flutter test integration_test/social_login_integration_test.dart --name "Google OAuth flow (new user)"

# Run tests matching pattern
flutter test integration_test/ --name "*account linking*"
```

## Test Environment Setup

### Prerequisites

1. **Flutter SDK** - Latest stable version
2. **Test Dependencies** - Ensure all test packages are installed:
   ```bash
   flutter pub get
   ```

3. **Mock Configuration** - Tests use mocked Supabase clients, no real OAuth setup needed

### Environment Variables

For integration tests, no real environment variables are needed as all external services are mocked. However, for reference:

```env
# Not needed for integration tests (mocked)
SUPABASE_URL=https://test-project.supabase.co
SUPABASE_ANON_KEY=test-anon-key
```

## Test Data and Mocking

### Mock Supabase Client

The tests use a comprehensive mock of the Supabase client that simulates:
- OAuth authentication flows
- Database operations
- Session management
- Error conditions

### Test Data Generation

Test data is generated dynamically using `TestDataGenerators`:
- Random user profiles
- OAuth provider responses
- Session tokens
- Error scenarios

### OAuth Flow Simulation

The `OAuthSimulator` class provides realistic OAuth flow simulation:
- Provider-specific responses
- Success and failure scenarios
- Deep link callback processing
- Session state management

## Validation Criteria

### Success Criteria

Each test validates:
- ✅ Correct navigation flow
- ✅ Proper state management
- ✅ Data persistence
- ✅ Error handling
- ✅ User feedback
- ✅ Security measures

### Performance Criteria

Tests also validate:
- OAuth flow completion time < 5 seconds
- Deep link processing time < 1 second
- UI responsiveness during authentication
- Memory usage stability

## Debugging Tests

### Common Issues

1. **Mock Setup Errors**
   ```bash
   # Verify mock configuration
   flutter test integration_test/ --verbose
   ```

2. **Timing Issues**
   ```dart
   // Add delays for async operations
   await tester.pumpAndSettle();
   ```

3. **Widget Finding Issues**
   ```dart
   // Use specific keys for test widgets
   find.byKey(Key('social_login_button'))
   ```

### Debug Output

Enable debug output in tests:
```dart
debugPrint('Test checkpoint: OAuth initiated');
```

### Test Screenshots

For visual debugging, tests can capture screenshots:
```dart
await tester.binding.takeScreenshot('oauth_flow_step_1');
```

## Continuous Integration

### CI Configuration

Add to your CI pipeline:
```yaml
- name: Run Integration Tests
  run: flutter test integration_test/social_login_test_runner.dart
```

### Test Reports

Generate test reports:
```bash
flutter test integration_test/ --reporter json > test_results.json
```

## Maintenance

### Adding New Tests

1. Create test file in `integration_test/`
2. Follow naming convention: `social_login_[feature]_test.dart`
3. Add to test runner in `social_login_test_runner.dart`
4. Update this README with new test coverage

### Updating Mocks

When adding new Supabase features:
1. Update `MockSupabaseClient` with new methods
2. Add corresponding simulation in `OAuthSimulator`
3. Update test data generators as needed

### Test Data Cleanup

Tests are designed to be isolated and don't require cleanup, but ensure:
- No persistent state between tests
- Mock resets between test cases
- Memory usage remains stable

## Security Considerations

### Test Security

- No real OAuth credentials used in tests
- All tokens are mock/test values
- No sensitive data persisted
- Network calls are mocked

### Validation Testing

Tests specifically validate:
- Token security (never exposed in logs)
- Deep link scheme validation
- CSRF protection via state parameters
- Session security measures

## Support

For issues with integration tests:
1. Check test output for specific error messages
2. Verify mock configuration matches expected API
3. Ensure Flutter and dependencies are up to date
4. Review test data generation for edge cases

## Related Documentation

- [Social Login Design Document](../.kiro/specs/social-login/design.md)
- [Social Login Requirements](../.kiro/specs/social-login/requirements.md)
- [Social Login Tasks](../.kiro/specs/social-login/tasks.md)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)