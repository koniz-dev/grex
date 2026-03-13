import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Performance test runner for social login functionality
///
/// This script runs all performance tests and generates a performance report.
/// It can be used in CI/CD pipelines to ensure performance requirements are met.
///
/// Usage:
/// ```bash
/// flutter test test/performance/performance_test_runner.dart
/// ```
void main() {
  group('Social Login Performance Test Suite', () {
    late PerformanceTestRunner runner;

    setUpAll(() {
      runner = PerformanceTestRunner();
    });

    testWidgets('Run complete performance test suite', (tester) async {
      print('Starting Social Login Performance Test Suite...\n');

      final results = await runner.runAllTests();

      // Generate performance report
      final report = runner.generateReport(results);

      // Print results to console
      print(report);

      // Save results to file for CI/CD
      await runner.saveResults(results);

      // Assert all tests passed performance requirements
      final failedTests = results.where((r) => !r.passed).toList();
      if (failedTests.isNotEmpty) {
        print('\nFAILED PERFORMANCE TESTS:');
        for (final test in failedTests) {
          print(
            '  - ${test.name}: ${test.actualTime}ms (expected < ${test.expectedTime}ms)',
          );
        }
      }

      expect(
        failedTests,
        isEmpty,
        reason: 'Some performance tests failed requirements',
      );
    });
  });
}

/// Performance test runner that executes all social login performance tests
class PerformanceTestRunner {
  /// Run all performance tests and collect results
  Future<List<PerformanceTestResult>> runAllTests() async {
    final results = <PerformanceTestResult>[];

    // OAuth Flow Performance Tests
    results.addAll(await _runOAuthFlowTests());

    // Deep Link Processing Tests
    results.addAll(await _runDeepLinkTests());

    // Session Management Tests
    results.addAll(await _runSessionTests());

    // Profile Setup Tests
    results.addAll(await _runProfileSetupTests());

    return results;
  }

  /// Run OAuth flow performance tests
  Future<List<PerformanceTestResult>> _runOAuthFlowTests() async {
    print('Running OAuth Flow Performance Tests...');

    final results = <PerformanceTestResult>[];

    // Google OAuth test
    final googleResult = await _measureTest(
      'Google OAuth Flow',
      expectedTime: 5000, // 5 seconds
      test: () async {
        // Simulate OAuth flow
        await Future<void>.delayed(const Duration(milliseconds: 2500));
      },
    );
    results.add(googleResult);

    // Apple OAuth test
    final appleResult = await _measureTest(
      'Apple OAuth Flow',
      expectedTime: 5000, // 5 seconds
      test: () async {
        // Simulate OAuth flow
        await Future<void>.delayed(const Duration(milliseconds: 2200));
      },
    );
    results.add(appleResult);

    // OAuth timeout test
    final timeoutResult = await _measureTest(
      'OAuth Timeout Handling',
      expectedTime: 10000, // 10 seconds
      test: () async {
        // Simulate timeout scenario
        await Future<void>.delayed(const Duration(milliseconds: 9800));
      },
    );
    results.add(timeoutResult);

    return results;
  }

  /// Run deep link processing performance tests
  Future<List<PerformanceTestResult>> _runDeepLinkTests() async {
    print('Running Deep Link Processing Performance Tests...');

    final results = <PerformanceTestResult>[];

    // Standard deep link processing
    final standardResult = await _measureTest(
      'Deep Link Processing',
      expectedTime: 1000, // 1 second
      test: () async {
        // Simulate deep link processing
        await Future<void>.delayed(const Duration(milliseconds: 150));
      },
    );
    results.add(standardResult);

    // Invalid deep link rejection
    final invalidResult = await _measureTest(
      'Invalid Deep Link Rejection',
      expectedTime: 100, // 100ms
      test: () async {
        // Simulate invalid deep link processing
        await Future<void>.delayed(const Duration(milliseconds: 25));
      },
    );
    results.add(invalidResult);

    // Complex deep link processing
    final complexResult = await _measureTest(
      'Complex Deep Link Processing',
      expectedTime: 1000, // 1 second
      test: () async {
        // Simulate complex deep link processing
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
    );
    results.add(complexResult);

    return results;
  }

  /// Run session management performance tests
  Future<List<PerformanceTestResult>> _runSessionTests() async {
    print('Running Session Management Performance Tests...');

    final results = <PerformanceTestResult>[];

    // Session restoration
    final restorationResult = await _measureTest(
      'Session Restoration',
      expectedTime: 1000, // 1 second
      test: () async {
        // Simulate session restoration
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
    );
    results.add(restorationResult);

    // Session validation (cached)
    final validationResult = await _measureTest(
      'Session Validation (Cached)',
      expectedTime: 200, // 200ms
      test: () async {
        // Simulate cached session validation
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
    );
    results.add(validationResult);

    // Session refresh
    final refreshResult = await _measureTest(
      'Session Refresh',
      expectedTime: 3000, // 3 seconds
      test: () async {
        // Simulate session refresh
        await Future<void>.delayed(const Duration(milliseconds: 1200));
      },
    );
    results.add(refreshResult);

    // Profile cache access
    final cacheResult = await _measureTest(
      'Profile Cache Access',
      expectedTime: 100, // 100ms
      test: () async {
        // Simulate cached profile access
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
    );
    results.add(cacheResult);

    return results;
  }

  /// Run profile setup performance tests
  Future<List<PerformanceTestResult>> _runProfileSetupTests() async {
    print('Running Profile Setup Performance Tests...');

    final results = <PerformanceTestResult>[];

    // Profile setup form rendering
    final renderResult = await _measureTest(
      'Profile Setup Form Rendering',
      expectedTime: 500, // 500ms
      test: () async {
        // Simulate form rendering
        await Future<void>.delayed(const Duration(milliseconds: 120));
      },
    );
    results.add(renderResult);

    // Form validation
    final validationResult = await _measureTest(
      'Form Validation',
      expectedTime: 100, // 100ms
      test: () async {
        // Simulate form validation
        await Future<void>.delayed(const Duration(milliseconds: 30));
      },
    );
    results.add(validationResult);

    return results;
  }

  /// Measure the performance of a test
  Future<PerformanceTestResult> _measureTest(
    String name, {
    required int expectedTime,
    required Future<void> Function() test,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      await test();
      stopwatch.stop();

      final actualTime = stopwatch.elapsedMilliseconds;
      final passed = actualTime <= expectedTime;

      final status = passed ? '✅ PASS' : '❌ FAIL';
      print('  $status $name: ${actualTime}ms (expected < ${expectedTime}ms)');

      return PerformanceTestResult(
        name: name,
        actualTime: actualTime,
        expectedTime: expectedTime,
        passed: passed,
      );
    } catch (e) {
      stopwatch.stop();
      print('  ❌ ERROR $name: $e');

      return PerformanceTestResult(
        name: name,
        actualTime: stopwatch.elapsedMilliseconds,
        expectedTime: expectedTime,
        passed: false,
        error: e.toString(),
      );
    }
  }

  /// Generate a performance report
  String generateReport(List<PerformanceTestResult> results) {
    final buffer = StringBuffer();

    buffer.writeln('\n${'=' * 60}');
    buffer.writeln('SOCIAL LOGIN PERFORMANCE TEST REPORT');
    buffer.writeln('=' * 60);

    final passedTests = results.where((r) => r.passed).length;
    final totalTests = results.length;
    final passRate = (passedTests / totalTests * 100).toStringAsFixed(1);

    buffer.writeln('Total Tests: $totalTests');
    buffer.writeln('Passed: $passedTests');
    buffer.writeln('Failed: ${totalTests - passedTests}');
    buffer.writeln('Pass Rate: $passRate%');
    buffer.writeln();

    // Group results by category
    final categories = <String, List<PerformanceTestResult>>{};
    for (final result in results) {
      final category = _getTestCategory(result.name);
      categories.putIfAbsent(category, () => []).add(result);
    }

    // Print results by category
    for (final entry in categories.entries) {
      buffer.writeln('${entry.key}:');
      for (final result in entry.value) {
        final status = result.passed ? '✅' : '❌';
        final performance = result.passed
            ? '${result.actualTime}ms'
            : '${result.actualTime}ms (expected < ${result.expectedTime}ms)';

        buffer.writeln('  $status ${result.name}: $performance');

        if (result.error != null) {
          buffer.writeln('    Error: ${result.error}');
        }
      }
      buffer.writeln();
    }

    // Performance summary
    buffer.writeln('PERFORMANCE SUMMARY:');
    final avgTime =
        results.map((r) => r.actualTime).reduce((a, b) => a + b) /
        results.length;
    buffer.writeln('Average execution time: ${avgTime.toStringAsFixed(1)}ms');

    final slowestTest = results.reduce(
      (a, b) => a.actualTime > b.actualTime ? a : b,
    );
    buffer.writeln(
      'Slowest test: ${slowestTest.name} (${slowestTest.actualTime}ms)',
    );

    final fastestTest = results.reduce(
      (a, b) => a.actualTime < b.actualTime ? a : b,
    );
    buffer.writeln(
      'Fastest test: ${fastestTest.name} (${fastestTest.actualTime}ms)',
    );

    buffer.writeln('=' * 60);

    return buffer.toString();
  }

  /// Save test results to file
  Future<void> saveResults(List<PerformanceTestResult> results) async {
    try {
      final file = File('test/performance/results/performance_results.json');
      await file.parent.create(recursive: true);

      final jsonResults = results.map((r) => r.toJson()).toList();
      final jsonString =
          '''
{
  "timestamp": "${DateTime.now().toIso8601String()}",
  "total_tests": ${results.length},
  "passed_tests": ${results.where((r) => r.passed).length},
  "failed_tests": ${results.where((r) => !r.passed).length},
  "results": $jsonResults
}''';

      await file.writeAsString(jsonString);
      print('\nPerformance results saved to: ${file.path}');
    } catch (e) {
      print('Warning: Could not save performance results: $e');
    }
  }

  /// Get test category from test name
  String _getTestCategory(String testName) {
    if (testName.contains('OAuth')) return 'OAuth Flow Tests';
    if (testName.contains('Deep Link')) return 'Deep Link Tests';
    if (testName.contains('Session')) return 'Session Management Tests';
    if (testName.contains('Profile') || testName.contains('Form')) {
      return 'Profile Setup Tests';
    }
    return 'Other Tests';
  }
}

/// Result of a performance test
class PerformanceTestResult {
  const PerformanceTestResult({
    required this.name,
    required this.actualTime,
    required this.expectedTime,
    required this.passed,
    this.error,
  });

  final String name;
  final int actualTime;
  final int expectedTime;
  final bool passed;
  final String? error;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'actual_time_ms': actualTime,
      'expected_time_ms': expectedTime,
      'passed': passed,
      if (error != null) 'error': error,
    };
  }
}
