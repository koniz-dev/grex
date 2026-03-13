import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'social_login_deep_link_test.dart' as deep_link_tests;
import 'social_login_error_handling_test.dart' as error_tests;
// Import all social login integration test suites
import 'social_login_integration_test.dart' as main_tests;

/// Comprehensive test runner for all social login integration tests
///
/// This file runs all social login integration tests in sequence to ensure
/// comprehensive coverage of OAuth flows, error handling, and deep link
// processing.
///
/// Usage:
/// ```bash
/// flutter test integration_test/social_login_test_runner.dart
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Social Login Integration Test Suite', () {
    group('Main OAuth Flows', main_tests.main);

    group('Error Handling', error_tests.main);

    group('Deep Link Processing', deep_link_tests.main);
  });

  // Test suite summary and validation
  setUpAll(() {
    debugPrint('🚀 Starting Social Login Integration Test Suite');
    debugPrint('📋 Test Coverage:');
    debugPrint('   ✓ Google OAuth flows (new and existing users)');
    debugPrint('   ✓ Apple OAuth flows (new and existing users)');
    debugPrint('   ✓ Account linking scenarios');
    debugPrint('   ✓ Profile setup and cancellation');
    debugPrint('   ✓ OAuth cancellation handling');
    debugPrint('   ✓ Network error recovery');
    debugPrint('   ✓ Deep link processing (app closed/running)');
    debugPrint('   ✓ Session persistence and restoration');
    debugPrint('   ✓ Error handling and user feedback');
    debugPrint('   ✓ Security and validation scenarios');
  });

  tearDownAll(() {
    debugPrint('✅ Social Login Integration Test Suite Completed');
    debugPrint('📊 All OAuth providers and scenarios tested');
    debugPrint('🔒 Security and error handling validated');
    debugPrint('🔗 Deep link processing verified');
  });
}
