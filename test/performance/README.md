# Social Login Performance Testing

This directory contains comprehensive performance tests for the social login functionality in Grex.

## Overview

The performance testing suite ensures that all social login operations meet the specified performance requirements:

- **OAuth Flow Completion**: < 5 seconds after user authorization
- **Deep Link Processing**: < 1 second
- **Profile Setup Form Rendering**: < 500ms
- **Session Restoration**: < 1 second on app restart

## Test Files

### Core Test Files

- **`social_login_performance_test.dart`**: Main performance test suite with comprehensive test cases
- **`device_performance_test.dart`**: Device-specific performance tests for different hardware configurations
- **`performance_test_runner.dart`**: Test runner that executes all performance tests and generates reports

### Supporting Files

- **`DEVICE_TESTING_GUIDE.md`**: Manual testing guide for real device performance testing
- **`../helpers/mock_helpers.dart`**: Mock objects and test utilities

## Running Performance Tests

### Automated Tests

```bash
# Run all performance tests
flutter test test/performance/

# Run specific performance test file
flutter test test/performance/social_login_performance_test.dart

# Run with performance profiling
flutter test --profile test/performance/

# Run performance test runner (generates report)
flutter test test/performance/performance_test_runner.dart
```

### Manual Device Testing

Follow the guide in `DEVICE_TESTING_GUIDE.md` for testing on real devices:

```bash
# Build for performance testing
flutter build apk --profile  # Android
flutter build ios --profile  # iOS

# Install and test on device
flutter install --profile
```

## Performance Requirements

### OAuth Flow Performance
- **Google OAuth (New User)**: < 5 seconds total (including profile setup)
- **Google OAuth (Existing User)**: < 5 seconds total
- **Apple OAuth**: < 5 seconds total
- **OAuth Timeout**: Must timeout within 10 seconds

### Deep Link Processing
- **Standard Processing**: < 1 second
- **Invalid Link Rejection**: < 100ms
- **Complex Link Processing**: < 1 second

### Session Management
- **Session Restoration**: < 1 second
- **Session Validation (Cached)**: < 200ms
- **Session Refresh**: < 3 seconds
- **Profile Cache Access**: < 100ms

### UI Performance
- **Profile Setup Form Rendering**: < 500ms
- **Form Validation**: < 100ms

## Test Categories

### 1. OAuth Flow Performance Tests
Tests the complete OAuth authentication flow from button tap to successful authentication.

**Key Metrics:**
- Time from OAuth initiation to completion
- Timeout handling performance
- Multiple attempt performance consistency

### 2. Deep Link Processing Tests
Tests the performance of OAuth callback URL processing.

**Key Metrics:**
- Deep link validation speed
- URI parsing performance
- Error handling speed

### 3. Session Management Tests
Tests session-related operations including restoration, validation, and refresh.

**Key Metrics:**
- Session restoration from storage
- Cached vs non-cached validation
- Session refresh performance
- Profile cache effectiveness

### 4. UI Performance Tests
Tests user interface rendering and interaction performance.

**Key Metrics:**
- Form rendering time
- Validation response time
- UI state transition speed

### 5. Device-Specific Tests
Tests performance across different device capabilities.

**Device Categories:**
- Low-end Android (2-4GB RAM)
- High-end Android (6GB+ RAM)
- iOS devices (iPhone 8+)

## Performance Monitoring

### Continuous Integration

The performance tests are integrated into the CI/CD pipeline:

```yaml
# Example CI configuration
- name: Run Performance Tests
  run: flutter test test/performance/
  
- name: Upload Performance Results
  uses: actions/upload-artifact@v2
  with:
    name: performance-results
    path: test/performance/results/
```

### Performance Regression Detection

- Performance results are saved to `results/` directory
- Historical performance data is tracked
- Alerts are triggered for performance degradation > 20%

## Interpreting Results

### Test Output Format

```
✅ PASS Google OAuth Flow: 2500ms (expected < 5000ms)
❌ FAIL Deep Link Processing: 1200ms (expected < 1000ms)
```

### Performance Report

The test runner generates a comprehensive report including:
- Overall pass/fail statistics
- Performance by category
- Slowest and fastest tests
- Average execution times

### Failure Investigation

When tests fail performance requirements:

1. **Check Network Conditions**: Slow network can affect OAuth flows
2. **Verify Device Resources**: Low memory/CPU can impact performance
3. **Review Recent Changes**: Code changes may have introduced performance regressions
4. **Check Background Processes**: Other apps may be consuming resources

## Best Practices

### Writing Performance Tests

1. **Use Realistic Scenarios**: Test with realistic data and network conditions
2. **Measure End-to-End**: Include all user-visible delays
3. **Account for Variance**: Run multiple iterations and average results
4. **Set Reasonable Thresholds**: Allow for device and network variations

### Performance Optimization

1. **Profile Before Optimizing**: Use Flutter's performance profiling tools
2. **Focus on Critical Paths**: Optimize the most user-visible operations first
3. **Cache Appropriately**: Use caching for frequently accessed data
4. **Minimize Network Calls**: Reduce unnecessary API requests

### Maintaining Tests

1. **Update Thresholds**: Adjust performance requirements as needed
2. **Add New Scenarios**: Include new test cases for new features
3. **Review Regularly**: Ensure tests remain relevant and accurate
4. **Document Changes**: Record reasons for performance requirement changes

## Troubleshooting

### Common Issues

**Tests Running Slowly:**
- Check for debug mode (use `--profile` flag)
- Verify no background processes interfering
- Ensure adequate device resources

**Inconsistent Results:**
- Run tests multiple times
- Check for network variability
- Verify consistent test environment

**Mock Setup Issues:**
- Verify mock configurations
- Check test data setup
- Ensure proper cleanup between tests

### Getting Help

1. Check the test output for specific error messages
2. Review the device testing guide for manual verification
3. Compare results across different devices/environments
4. Check recent code changes that might affect performance

## Contributing

When adding new performance tests:

1. Follow the existing test structure and naming conventions
2. Include appropriate performance thresholds
3. Add documentation for new test scenarios
4. Update this README with new test information
5. Ensure tests are deterministic and reliable