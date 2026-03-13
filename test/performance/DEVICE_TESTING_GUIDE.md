# Device Performance Testing Guide

This guide provides instructions for testing social login performance on various real devices.

## Test Devices

### Low-end Android Devices
- **Target**: Devices with 2-4GB RAM, older processors
- **Examples**: Samsung Galaxy A10, Xiaomi Redmi 8A, Nokia 3.4
- **Performance Targets**:
  - OAuth flow completion: < 8 seconds
  - Deep link processing: < 2 seconds
  - Session restoration: < 3 seconds

### High-end Android Devices
- **Target**: Devices with 6GB+ RAM, modern processors
- **Examples**: Samsung Galaxy S21+, Google Pixel 6, OnePlus 9
- **Performance Targets**:
  - OAuth flow completion: < 5 seconds
  - Deep link processing: < 1 second
  - Session restoration: < 1 second

### iOS Devices
- **Target**: iPhone 8 and newer
- **Examples**: iPhone 8, iPhone 12, iPhone 13, iPad Air
- **Performance Targets**:
  - OAuth flow completion: < 4 seconds
  - Deep link processing: < 800ms
  - Session restoration: < 800ms

## Testing Procedure

### 1. Pre-test Setup

```bash
# Build the app in profile mode for accurate performance measurement
flutter build apk --profile  # For Android
flutter build ios --profile  # For iOS

# Install on test device
flutter install --profile
```

### 2. OAuth Flow Performance Test

#### Test Steps:
1. Launch the app on the test device
2. Navigate to the login screen
3. Start a stopwatch when tapping the social login button
4. Stop the stopwatch when the main app screen appears
5. Record the time

#### Test Cases:
- **Google OAuth (New User)**:
  - Tap "Continue with Google"
  - Complete OAuth in browser
  - Fill profile setup form
  - Measure total time to main screen

- **Google OAuth (Existing User)**:
  - Tap "Continue with Google"
  - Complete OAuth in browser
  - Measure time to main screen (no profile setup)

- **Apple OAuth (iOS only)**:
  - Tap "Continue with Apple"
  - Complete OAuth with Apple ID
  - Measure time to completion

#### Recording Template:
```
Device: [Device Model]
OS Version: [OS Version]
Test: [Google/Apple OAuth - New/Existing User]
Time: [X.X seconds]
Notes: [Any issues or observations]
```

### 3. Deep Link Processing Test

#### Test Steps:
1. Complete an OAuth flow to generate a callback URL
2. Copy the callback URL from logs
3. Close the app completely
4. Open the callback URL (via ADB or Safari)
5. Measure time from URL open to app authentication completion

#### ADB Command (Android):
```bash
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.grex://login-callback/?access_token=test&refresh_token=test" com.example.grex
```

#### Recording Template:
```
Device: [Device Model]
Test: Deep Link Processing
App State: [Closed/Background]
Time: [X.X seconds]
Notes: [Any issues]
```

### 4. Session Restoration Test

#### Test Steps:
1. Complete a successful OAuth login
2. Force close the app
3. Start a stopwatch
4. Reopen the app
5. Stop stopwatch when main screen appears (authenticated)

#### Recording Template:
```
Device: [Device Model]
Test: Session Restoration
Time: [X.X seconds]
Notes: [Any issues]
```

### 5. Memory Usage Test

#### Test Steps:
1. Use device developer options to monitor memory
2. Perform 10 consecutive OAuth flows
3. Monitor memory usage throughout
4. Check for memory leaks or excessive usage

#### Android Memory Monitoring:
```bash
# Monitor memory usage
adb shell dumpsys meminfo com.example.grex

# Or use Android Studio Memory Profiler
```

#### iOS Memory Monitoring:
- Use Xcode Instruments Memory Profiler
- Monitor during OAuth flows

## Performance Benchmarks

### Expected Results

| Device Type | OAuth Flow | Deep Link | Session Restore |
|-------------|------------|-----------|-----------------|
| Low-end Android | < 8s | < 2s | < 3s |
| High-end Android | < 5s | < 1s | < 1s |
| iOS | < 4s | < 800ms | < 800ms |

### Failure Criteria

If any test exceeds these thresholds, investigate:
- Network connectivity issues
- Device storage/memory constraints
- Background app interference
- OAuth provider response times

## Troubleshooting

### Slow OAuth Flow
- Check network connectivity
- Verify OAuth provider configuration
- Monitor browser launch time
- Check for background app interference

### Slow Deep Link Processing
- Verify deep link scheme registration
- Check for URI parsing issues
- Monitor app launch time from background

### Slow Session Restoration
- Check secure storage performance
- Verify session validation logic
- Monitor profile cache effectiveness

### Memory Issues
- Check for unclosed streams/subscriptions
- Verify proper disposal of resources
- Monitor OAuth token storage

## Reporting Results

### Test Report Template

```markdown
# Social Login Performance Test Report

## Test Environment
- Date: [Date]
- App Version: [Version]
- Flutter Version: [Version]
- Tester: [Name]

## Device Results

### [Device Model] - [OS Version]
- **OAuth Flow (Google, New User)**: X.Xs
- **OAuth Flow (Google, Existing User)**: X.Xs
- **OAuth Flow (Apple)**: X.Xs (iOS only)
- **Deep Link Processing**: X.Xs
- **Session Restoration**: X.Xs
- **Memory Usage**: Peak XXmb, Stable XXmb

### Issues Found
- [List any performance issues]
- [Include screenshots if relevant]

### Recommendations
- [Performance optimization suggestions]
```

## Automated Performance Testing

### Integration with CI/CD

```yaml
# .github/workflows/performance-test.yml
name: Performance Tests
on: [push, pull_request]

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      
      - name: Run performance tests
        run: flutter test test/performance/
        
      - name: Upload performance results
        uses: actions/upload-artifact@v2
        with:
          name: performance-results
          path: test/performance/results/
```

### Performance Regression Detection

Monitor performance metrics over time:
- Set up alerts for performance degradation
- Track performance trends across releases
- Maintain performance benchmarks in CI

## Best Practices

1. **Test on Real Devices**: Emulators don't accurately reflect real performance
2. **Multiple Test Runs**: Run each test 3-5 times and average results
3. **Consistent Conditions**: Test with similar network, battery, and background app conditions
4. **Document Everything**: Record device specs, OS versions, and environmental factors
5. **Regular Testing**: Include performance testing in release cycles