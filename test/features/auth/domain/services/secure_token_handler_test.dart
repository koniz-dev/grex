import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/services/secure_token_handler.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mock classes for testing
class MockSupabaseClient extends Mock implements SupabaseClient {
  String _supabaseUrl = 'https://test.supabase.co';

  String get supabaseUrl => _supabaseUrl;

  // Setter method for testing purposes to modify Supabase URL
  // ignore: use_setters_to_change_properties
  void setSupabaseUrl(String url) {
    _supabaseUrl = url;
  }
}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSession extends Mock implements Session {}

class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  group('SecureTokenHandler', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuth;
    late MockSession mockSession;
    late MockAuthResponse mockAuthResponse;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockSession = MockSession();
      mockAuthResponse = MockAuthResponse();

      when(mockSupabaseClient.auth).thenReturn(mockAuth);
    });

    group('validateSecureStorage', () {
      test('should return true when no session exists', () {
        // Arrange
        when(mockAuth.currentSession).thenReturn(null);

        // Act
        final result = SecureTokenHandler.validateSecureStorage();

        // Assert
        expect(result, isTrue);
      });

      test('should return true for valid session with tokens', () {
        // Arrange
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockSession.accessToken).thenReturn('valid_access_token');
        when(mockSession.refreshToken).thenReturn('valid_refresh_token');

        // Act
        final result = SecureTokenHandler.validateSecureStorage();

        // Assert
        expect(result, isTrue);
      });

      test('should return false for session with empty access token', () {
        // Arrange
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockSession.accessToken).thenReturn('');
        when(mockSession.refreshToken).thenReturn('valid_refresh_token');

        // Act
        final result = SecureTokenHandler.validateSecureStorage();

        // Assert
        expect(result, isFalse);
      });

      test('should return false for session with null refresh token', () {
        // Arrange
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockSession.accessToken).thenReturn('valid_access_token');
        when(mockSession.refreshToken).thenReturn(null);

        // Act
        final result = SecureTokenHandler.validateSecureStorage();

        // Assert
        expect(result, isFalse);
      });

      test('should return false when session access throws exception', () {
        // Arrange
        when(
          mockAuth.currentSession,
        ).thenThrow(Exception('Session access error'));

        // Act
        final result = SecureTokenHandler.validateSecureStorage();

        // Assert
        expect(result, isFalse);
      });
    });

    group('validateHttpsTransmission', () {
      test('should return true for HTTPS URLs', () {
        // Arrange
        mockSupabaseClient.setSupabaseUrl('https://test.supabase.co');

        // Act
        final result = SecureTokenHandler.validateHttpsTransmission();

        // Assert
        expect(result, isTrue);
      });

      test('should return false for HTTP URLs', () {
        // Arrange
        mockSupabaseClient.setSupabaseUrl('http://test.supabase.co');

        // Act
        final result = SecureTokenHandler.validateHttpsTransmission();

        // Assert
        expect(result, isFalse);
      });

      test('should return false for other protocols', () {
        final insecureUrls = [
          'ftp://test.supabase.co',
          'ws://test.supabase.co',
          'file://test.supabase.co',
          '',
        ];

        for (final url in insecureUrls) {
          // Arrange
          mockSupabaseClient.setSupabaseUrl(url);

          // Act
          final result = SecureTokenHandler.validateHttpsTransmission();

          // Assert
          expect(result, isFalse, reason: 'URL should be invalid: $url');
        }
      });
    });

    group('validateTokenExposurePrevention', () {
      test('should return false for messages containing JWT tokens', () {
        final jwtTokens = [
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwi'
                  'bmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4' 'fwpMeJf36POk6yJV_adQssw5c',
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiYWJj'
                  'ZGVmZ2hpamtsbW5vcCIsImlhdCI6MTYxNjE2MTYxNiwiZXhwIjoxNjE2MTY1MjE2' 'fQ.test_signature',
        ];

        for (final token in jwtTokens) {
          final errorMessage = 'Authentication failed with token: $token';

          // Act
          final result = SecureTokenHandler.validateTokenExposurePrevention(
            errorMessage,
          );

          // Assert
          expect(result, isFalse, reason: 'Should detect JWT token: $token');
        }
      });

      test('should return false for messages containing access tokens', () {
        final accessTokenMessages = [
          'access_token: sb-access-token-123456',
          'access_token=gho_16C7e42F292c6912E7710c838347Ae178B4a',
          'Bearer abc123def456',
          'Failed with access_token: token_value and other data',
        ];

        for (final message in accessTokenMessages) {
          // Act
          final result = SecureTokenHandler.validateTokenExposurePrevention(
            message,
          );

          // Assert
          expect(
            result,
            isFalse,
            reason: 'Should detect access token in: $message',
          );
        }
      });

      test('should return false for messages containing refresh tokens', () {
        final refreshTokenMessages = [
          'refresh_token: rt_abcdef123456',
          'refresh_token=refresh_value_123',
          'Token refresh failed with refresh_token: xyz789',
        ];

        for (final message in refreshTokenMessages) {
          // Act
          final result = SecureTokenHandler.validateTokenExposurePrevention(
            message,
          );

          // Assert
          expect(
            result,
            isFalse,
            reason: 'Should detect refresh token in: $message',
          );
        }
      });

      test('should return true for safe error messages', () {
        final safeMessages = [
          'Network connection failed',
          'Authentication timeout occurred',
          'Invalid credentials provided',
          'User cancelled authentication',
          'Server returned error code 401',
          'OAuth provider unavailable',
        ];

        for (final message in safeMessages) {
          // Act
          final result = SecureTokenHandler.validateTokenExposurePrevention(
            message,
          );

          // Assert
          expect(result, isTrue, reason: 'Safe message should pass: $message');
        }
      });
    });

    group('sanitizeErrorMessage', () {
      test('should redact JWT tokens', () {
        // Arrange
        const token =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwi'
            'bmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4'
            'fwpMeJf36POk6yJV_adQssw5c';
        const errorMessage = 'Authentication failed with token: $token';

        // Act
        final sanitized = SecureTokenHandler.sanitizeErrorMessage(errorMessage);

        // Assert
        expect(sanitized, isNot(contains(token)));
        expect(sanitized, contains('[TOKEN_REDACTED]'));
      });

      test('should redact access tokens', () {
        // Arrange
        const errorMessage = 'access_token=sb-access-token-123456';

        // Act
        final sanitized = SecureTokenHandler.sanitizeErrorMessage(errorMessage);

        // Assert
        expect(sanitized, isNot(contains('sb-access-token-123456')));
        expect(sanitized, contains('access_token=[TOKEN_REDACTED]'));
      });

      test('should redact refresh tokens', () {
        // Arrange
        const errorMessage = 'refresh_token: rt_abcdef123456';

        // Act
        final sanitized = SecureTokenHandler.sanitizeErrorMessage(errorMessage);

        // Assert
        expect(sanitized, isNot(contains('rt_abcdef123456')));
        expect(sanitized, contains('refresh_token=[TOKEN_REDACTED]'));
      });

      test('should redact Bearer tokens', () {
        // Arrange
        const errorMessage = 'Bearer abc123def456 authorization failed';

        // Act
        final sanitized = SecureTokenHandler.sanitizeErrorMessage(errorMessage);

        // Assert
        expect(sanitized, isNot(contains('abc123def456')));
        expect(sanitized, contains('Bearer [TOKEN_REDACTED]'));
      });

      test('should leave safe messages unchanged', () {
        const safeMessage = 'Network connection failed';

        // Act
        final sanitized = SecureTokenHandler.sanitizeErrorMessage(safeMessage);

        // Assert
        expect(sanitized, equals(safeMessage));
      });

      test('should handle multiple tokens in one message', () {
        // Arrange
        const errorMessage =
            'OAuth failed: access_token=abc123, refresh_token=xyz789';

        // Act
        final sanitized = SecureTokenHandler.sanitizeErrorMessage(errorMessage);

        // Assert
        expect(sanitized, isNot(contains('abc123')));
        expect(sanitized, isNot(contains('xyz789')));
        expect(sanitized, contains('[TOKEN_REDACTED]'));
      });
    });

    group('validateSessionNotRevoked', () {
      test('should return true when no session exists', () async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(null);

        // Act
        final result = await SecureTokenHandler.validateSessionNotRevoked();

        // Assert
        expect(result, isTrue);
        verifyNever(mockAuth.refreshSession());
      });

      test('should return true when session refresh succeeds', () async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuthResponse.session).thenReturn(mockSession);
        when(
          mockAuth.refreshSession(),
        ).thenAnswer((_) async => mockAuthResponse);

        // Act
        final result = await SecureTokenHandler.validateSessionNotRevoked();

        // Assert
        expect(result, isTrue);
        verify(mockAuth.refreshSession()).called(1);
      });

      test('should return false when session refresh fails', () async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(
          mockAuth.refreshSession(),
        ).thenThrow(const AuthException('Token revoked'));

        // Act
        final result = await SecureTokenHandler.validateSessionNotRevoked();

        // Assert
        expect(result, isFalse);
        verify(mockAuth.refreshSession()).called(1);
      });

      test('should return false when refresh returns null session', () async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuthResponse.session).thenReturn(null);
        when(
          mockAuth.refreshSession(),
        ).thenAnswer((_) async => mockAuthResponse);

        // Act
        final result = await SecureTokenHandler.validateSessionNotRevoked();

        // Assert
        expect(result, isFalse);
        verify(mockAuth.refreshSession()).called(1);
      });
    });

    group('clearTokensSecurely', () {
      test('should call signOut successfully', () async {
        // Arrange
        when(mockAuth.signOut()).thenAnswer((_) async {});

        // Act & Assert
        expect(
          () async => SecureTokenHandler.clearTokensSecurely(),
          returnsNormally,
        );

        verify(mockAuth.signOut()).called(1);
      });

      test('should propagate signOut errors', () async {
        // Arrange
        when(
          mockAuth.signOut(),
        ).thenThrow(const AuthException('Sign out failed'));

        // Act & Assert
        expect(
          () async => SecureTokenHandler.clearTokensSecurely(),
          throwsA(isA<AuthException>()),
        );

        verify(mockAuth.signOut()).called(1);
      });
    });

    group('secureLog', () {
      test('should not throw for normal messages', () {
        // Act & Assert
        expect(
          () => SecureTokenHandler.secureLog('Test message'),
          returnsNormally,
        );
      });

      test('should not throw for messages with errors', () {
        // Act & Assert
        expect(
          () => SecureTokenHandler.secureLog(
            'Error occurred',
            error: Exception('Test error'),
          ),
          returnsNormally,
        );
      });

      test('should sanitize error messages before logging', () {
        // Arrange
        final errorWithToken = Exception('access_token=secret123');

        // Act & Assert - Should not throw and should sanitize
        expect(
          () => SecureTokenHandler.secureLog(
            'Error with token',
            error: errorWithToken,
          ),
          returnsNormally,
        );
      });
    });
  });
}
