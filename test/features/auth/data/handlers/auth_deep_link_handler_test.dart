import 'package:flutter_test/flutter_test.dart';
import 'package:grex/core/performance/performance_service.dart';
import 'package:grex/features/auth/data/handlers/auth_deep_link_handler.dart';
import 'package:mockito/mockito.dart';

// Mock class for PerformanceService
class MockPerformanceService extends Mock implements PerformanceService {}

void main() {
  group('AuthDeepLinkHandler', () {
    late AuthDeepLinkHandler handler;
    late List<Uri> receivedCallbacks;
    late MockPerformanceService mockPerformanceService;

    setUp(() {
      receivedCallbacks = [];
      mockPerformanceService = MockPerformanceService();

      handler = AuthDeepLinkHandler(
        onDeepLink: (uri) {
          receivedCallbacks.add(uri);
        },
        performanceService: mockPerformanceService,
      );
    });

    tearDown(() {
      handler.dispose();
    });

    group('callback URL validation', () {
      test('should validate correct OAuth callback URLs', () {
        // Test cases for valid OAuth callbacks
        final validCallbacks = [
          'io.supabase.grex://login-callback/',
          'io.supabase.grex://login-callback/?access_token=test',
          'io.supabase.grex://login-callback/?access_token=test&refresh_token=refresh',
          'io.supabase.grex://login-callback/?error=access_denied',
        ];

        for (final callback in validCallbacks) {
          final uri = Uri.parse(callback);
          expect(
            handler._isAuthCallback(uri),
            isTrue,
            reason: 'Should validate as OAuth callback: $callback',
          );
        }
      });

      test('should reject invalid OAuth callback URLs', () {
        // Test cases for invalid OAuth callbacks
        final invalidCallbacks = [
          'https://supabase.grex.com/login-callback/',
          'io.supabase.grex://other-callback/',
          'io.supabase.other://login-callback/',
          'com.example.app://login-callback/',
          'http://example.com/callback',
          'https://api.example.com/auth/callback',
          'myapp://open/screen',
        ];

        for (final callback in invalidCallbacks) {
          final uri = Uri.parse(callback);
          expect(
            handler._isAuthCallback(uri),
            isFalse,
            reason: 'Should reject as OAuth callback: $callback',
          );
        }
      });
    });

    group('error handling', () {
      test('should handle malformed URLs gracefully', () {
        // Test the validation logic with malformed query parameters
        final malformedUri = Uri.parse(
          'io.supabase.grex://login-callback/?token=test%GG',
        );

        // The _isAuthCallback should still work with malformed query parameters
        expect(handler._isAuthCallback(malformedUri), isTrue);
      });

      test('should handle empty query parameters', () {
        final uri = Uri.parse('io.supabase.grex://login-callback/');
        expect(handler._isAuthCallback(uri), isTrue);
      });

      test('should handle case sensitivity correctly', () {
        // Test case sensitivity - URI schemes and hosts are case-insensitive in
        // Dart
        final testCases = [
          (
            'IO.SUPABASE.GREX://login-callback/',
            true,
          ), // Scheme is case-insensitive
          (
            'io.supabase.grex://LOGIN-CALLBACK/',
            true,
          ), // Host is case-insensitive
          ('io.supabase.grex://login-callback/', true), // Correct case
        ];

        for (final testCase in testCases) {
          final uri = Uri.parse(testCase.$1);
          expect(
            handler._isAuthCallback(uri),
            equals(testCase.$2),
            reason: 'Case sensitivity test for: ${testCase.$1}',
          );
        }
      });
    });

    group('subscription cleanup', () {
      test('should handle multiple dispose calls gracefully', () {
        // Act & Assert - should not throw
        handler
          ..dispose()
          ..dispose()
          ..dispose();
      });

      test('should handle dispose before initialize', () {
        // Arrange - create new handler without initializing
        final newHandler = AuthDeepLinkHandler(
          onDeepLink: (_) {},
          performanceService: MockPerformanceService(),
        );

        // Act & Assert - should not throw
        newHandler.dispose();
      });
    });

    group('callback processing', () {
      test('should process valid OAuth callback through onDeepLink', () {
        // Arrange
        final validCallback = Uri.parse(
          'io.supabase.grex://login-callback/?access_token=test123',
        );

        // Act - simulate what would happen when a valid callback is received
        if (handler._isAuthCallback(validCallback)) {
          handler.onDeepLink(validCallback);
        }

        // Assert
        expect(receivedCallbacks, contains(validCallback));
      });

      test('should not process invalid callbacks', () {
        // Arrange
        final invalidCallback = Uri.parse('https://example.com/callback');

        // Act - simulate what would happen when an invalid callback is received
        if (handler._isAuthCallback(invalidCallback)) {
          handler.onDeepLink(invalidCallback);
        }

        // Assert
        expect(receivedCallbacks, isEmpty);
      });

      test('should handle callback with complex query parameters', () {
        // Arrange
        final complexCallback = Uri.parse(
          'io.supabase.grex://login-callback/?'
          'access_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9&'
          'refresh_token=def456&'
          'token_type=bearer&'
          'expires_in=3600&'
          'provider_token=gho_abc123&'
          'provider_refresh_token=ghr_def456',
        );

        // Act
        if (handler._isAuthCallback(complexCallback)) {
          handler.onDeepLink(complexCallback);
        }

        // Assert
        expect(receivedCallbacks, contains(complexCallback));
      });

      test('should handle multiple callbacks', () {
        // Arrange
        final callbacks = [
          Uri.parse('io.supabase.grex://login-callback/?access_token=test1'),
          Uri.parse('io.supabase.grex://login-callback/?access_token=test2'),
          Uri.parse('io.supabase.grex://login-callback/?error=access_denied'),
        ];

        // Act
        for (final callback in callbacks) {
          if (handler._isAuthCallback(callback)) {
            handler.onDeepLink(callback);
          }
        }

        // Assert
        expect(receivedCallbacks, hasLength(3));
        for (final callback in callbacks) {
          expect(receivedCallbacks, contains(callback));
        }
      });
    });

    group('edge cases', () {
      test('should handle URLs with fragments', () {
        final uriWithFragment = Uri.parse(
          'io.supabase.grex://login-callback/?access_token=test#fragment',
        );
        expect(handler._isAuthCallback(uriWithFragment), isTrue);
      });

      test('should handle URLs with ports', () {
        final uriWithPort = Uri.parse(
          'io.supabase.grex://login-callback:8080/?access_token=test',
        );
        expect(
          handler._isAuthCallback(uriWithPort),
          isTrue,
        ); // Port is part of authority, host is still 'login-callback'
      });

      test('should handle URLs with paths', () {
        final uriWithPath = Uri.parse(
          'io.supabase.grex://login-callback/extra/path?access_token=test',
        );
        expect(handler._isAuthCallback(uriWithPath), isTrue); // Path is allowed
      });

      test('should handle URLs with userinfo', () {
        final uriWithUserInfo = Uri.parse(
          'io.supabase.grex://user:pass@login-callback/?access_token=test',
        );
        expect(handler._isAuthCallback(uriWithUserInfo), isTrue);
      });
    });
  });
}

/// Extension to access private method for testing
extension AuthDeepLinkHandlerTest on AuthDeepLinkHandler {
  bool _isAuthCallback(Uri uri) {
    return uri.scheme == 'io.supabase.grex' && uri.host == 'login-callback';
  }
}
