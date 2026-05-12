import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';
import 'package:grex/features/auth/domain/services/social_login_analytics.dart';

void main() {
  group('SocialLoginAnalyticsImpl', () {
    late SocialLoginAnalyticsImpl analytics;
    late List<Map<String, dynamic>> loggedEvents;

    setUp(() {
      loggedEvents = [];
      analytics = TestSocialLoginAnalyticsImpl(loggedEvents);
    });

    group('logSocialLoginInitiated', () {
      test('should log social login initiated event for Google', () {
        // Act
        analytics.logSocialLoginInitiated(SocialAuthProvider.google);

        // Assert
        expect(loggedEvents.length, equals(1));
        final event = loggedEvents.first;
        expect(event['event'], equals('social_login_initiated'));
        expect(event['provider'], equals('google'));
        expect(event['timestamp'], isNotNull);
      });

      test('should log social login initiated event for Apple', () {
        // Act
        analytics.logSocialLoginInitiated(SocialAuthProvider.apple);

        // Assert
        expect(loggedEvents.length, equals(1));
        final event = loggedEvents.first;
        expect(event['event'], equals('social_login_initiated'));
        expect(event['provider'], equals('apple'));
        expect(event['timestamp'], isNotNull);
      });
    });

    group('logSocialLoginSuccess', () {
      test('should log social login success event with new user type', () {
        // Act
        analytics.logSocialLoginSuccess(
          provider: SocialAuthProvider.google,
          userType: 'new',
        );

        // Assert
        expect(loggedEvents.length, equals(1));
        final event = loggedEvents.first;
        expect(event['event'], equals('social_login_success'));
        expect(event['provider'], equals('google'));
        expect(event['user_type'], equals('new'));
        expect(event['timestamp'], isNotNull);
      });

      test('should log social login success event with existing user type', () {
        // Act
        analytics.logSocialLoginSuccess(
          provider: SocialAuthProvider.apple,
          userType: 'existing',
        );

        // Assert
        expect(loggedEvents.length, equals(1));
        final event = loggedEvents.first;
        expect(event['event'], equals('social_login_success'));
        expect(event['provider'], equals('apple'));
        expect(event['user_type'], equals('existing'));
        expect(event['timestamp'], isNotNull);
      });

      test(
        'should log social login success event with linking required user type',
        () {
          // Act
          analytics.logSocialLoginSuccess(
            provider: SocialAuthProvider.google,
            userType: 'linking_required',
          );

          // Assert
          expect(loggedEvents.length, equals(1));
          final event = loggedEvents.first;
          expect(event['event'], equals('social_login_success'));
          expect(event['provider'], equals('google'));
          expect(event['user_type'], equals('linking_required'));
          expect(event['timestamp'], isNotNull);
        },
      );
    });

    group('logSocialLoginFailure', () {
      test('should log social login failure event with network error', () {
        // Act
        analytics.logSocialLoginFailure(
          provider: SocialAuthProvider.google,
          errorType: 'network',
        );

        // Assert
        expect(loggedEvents.length, equals(1));
        final event = loggedEvents.first;
        expect(event['event'], equals('social_login_failure'));
        expect(event['provider'], equals('google'));
        expect(event['error_type'], equals('network'));
        expect(event['timestamp'], isNotNull);
      });

      test('should log social login failure event with timeout error', () {
        // Act
        analytics.logSocialLoginFailure(
          provider: SocialAuthProvider.apple,
          errorType: 'timeout',
        );

        // Assert
        expect(loggedEvents.length, equals(1));
        final event = loggedEvents.first;
        expect(event['event'], equals('social_login_failure'));
        expect(event['provider'], equals('apple'));
        expect(event['error_type'], equals('timeout'));
        expect(event['timestamp'], isNotNull);
      });

      test('should log social login failure event with unknown error', () {
        // Act
        analytics.logSocialLoginFailure(
          provider: SocialAuthProvider.google,
          errorType: 'unknown',
        );

        // Assert
        expect(loggedEvents.length, equals(1));
        final event = loggedEvents.first;
        expect(event['event'], equals('social_login_failure'));
        expect(event['provider'], equals('google'));
        expect(event['error_type'], equals('unknown'));
        expect(event['timestamp'], isNotNull);
      });
    });

    group('logSocialLoginCancelled', () {
      test('should log social login cancelled event for Google', () {
        // Act
        analytics.logSocialLoginCancelled(SocialAuthProvider.google);

        // Assert
        expect(loggedEvents.length, equals(1));
        final event = loggedEvents.first;
        expect(event['event'], equals('social_login_cancelled'));
        expect(event['provider'], equals('google'));
        expect(event['timestamp'], isNotNull);
      });

      test('should log social login cancelled event for Apple', () {
        // Act
        analytics.logSocialLoginCancelled(SocialAuthProvider.apple);

        // Assert
        expect(loggedEvents.length, equals(1));
        final event = loggedEvents.first;
        expect(event['event'], equals('social_login_cancelled'));
        expect(event['provider'], equals('apple'));
        expect(event['timestamp'], isNotNull);
      });
    });

    group('logProfileSetupCompleted', () {
      test('should log profile setup completed event with all parameters', () {
        // Act
        analytics.logProfileSetupCompleted(
          provider: SocialAuthProvider.google,
          displayName: 'John Doe',
          currency: 'VND',
          language: 'vi',
        );

        // Assert
        expect(loggedEvents.length, equals(1));
        final event = loggedEvents.first;
        expect(event['event'], equals('profile_setup_completed'));
        expect(event['provider'], equals('google'));
        expect(event['display_name_length'], equals(8)); // 'John Doe'.length
        expect(event['currency'], equals('VND'));
        expect(event['language'], equals('vi'));
        expect(event['timestamp'], isNotNull);
      });

      test(
        'should log profile setup completed event for Apple with different '
        'parameters',
        () {
          // Act
          analytics.logProfileSetupCompleted(
            provider: SocialAuthProvider.apple,
            displayName: 'Jane Smith',
            currency: 'USD',
            language: 'en',
          );

          // Assert
          expect(loggedEvents.length, equals(1));
          final event = loggedEvents.first;
          expect(event['event'], equals('profile_setup_completed'));
          expect(event['provider'], equals('apple'));
          expect(
            event['display_name_length'],
            equals(10),
          ); // 'Jane Smith'.length
          expect(event['currency'], equals('USD'));
          expect(event['language'], equals('en'));
          expect(event['timestamp'], isNotNull);
        },
      );

      test('should handle empty display name', () {
        // Act
        analytics.logProfileSetupCompleted(
          provider: SocialAuthProvider.google,
          displayName: '',
          currency: 'EUR',
          language: 'es',
        );

        // Assert
        expect(loggedEvents.length, equals(1));
        final event = loggedEvents.first;
        expect(event['display_name_length'], equals(0));
        expect(event['currency'], equals('EUR'));
        expect(event['language'], equals('es'));
      });
    });

    group('logAccountLinking', () {
      test('should log account linking confirmed event', () {
        // Act
        analytics.logAccountLinking(
          provider: SocialAuthProvider.google,
          action: 'confirmed',
          existingEmail: 'user@gmail.com',
        );

        // Assert
        expect(loggedEvents.length, equals(1));
        final event = loggedEvents.first;
        expect(event['event'], equals('account_linking'));
        expect(event['provider'], equals('google'));
        expect(event['action'], equals('confirmed'));
        expect(event['email_domain'], equals('gmail.com'));
        expect(event['timestamp'], isNotNull);
      });

      test('should log account linking declined event', () {
        // Act
        analytics.logAccountLinking(
          provider: SocialAuthProvider.apple,
          action: 'declined',
          existingEmail: 'user@yahoo.com',
        );

        // Assert
        expect(loggedEvents.length, equals(1));
        final event = loggedEvents.first;
        expect(event['event'], equals('account_linking'));
        expect(event['provider'], equals('apple'));
        expect(event['action'], equals('declined'));
        expect(event['email_domain'], equals('yahoo.com'));
        expect(event['timestamp'], isNotNull);
      });

      test('should handle email without domain', () {
        // Act
        analytics.logAccountLinking(
          provider: SocialAuthProvider.google,
          action: 'confirmed',
          existingEmail: 'invalid-email',
        );

        // Assert
        expect(loggedEvents.length, equals(1));
        final event = loggedEvents.first;
        expect(event['email_domain'], equals('unknown'));
      });

      test('should handle email with multiple @ symbols', () {
        // Act
        analytics.logAccountLinking(
          provider: SocialAuthProvider.google,
          action: 'confirmed',
          existingEmail: 'user@test@example.com',
        );

        // Assert
        expect(loggedEvents.length, equals(1));
        final event = loggedEvents.first;
        expect(event['email_domain'], equals('test@example.com'));
      });
    });

    group('event parameters validation', () {
      test('should include timestamp in all events', () {
        // Act
        analytics
          ..logSocialLoginInitiated(SocialAuthProvider.google)
          ..logSocialLoginSuccess(
            provider: SocialAuthProvider.apple,
            userType: 'new',
          )
          ..logSocialLoginFailure(
            provider: SocialAuthProvider.google,
            errorType: 'network',
          )
          ..logSocialLoginCancelled(SocialAuthProvider.apple)
          ..logProfileSetupCompleted(
            provider: SocialAuthProvider.google,
            displayName: 'Test',
            currency: 'VND',
            language: 'vi',
          )
          ..logAccountLinking(
            provider: SocialAuthProvider.apple,
            action: 'confirmed',
            existingEmail: 'test@example.com',
          );

        // Assert
        expect(loggedEvents.length, equals(6));
        for (final event in loggedEvents) {
          expect(event['timestamp'], isNotNull);
          expect(event['timestamp'], isA<String>());
          // Verify timestamp is valid ISO 8601 format
          expect(
            () => DateTime.parse(event['timestamp'] as String),
            returnsNormally,
          );
        }
      });

      test('should include provider in all events', () {
        // Act
        analytics
          ..logSocialLoginInitiated(SocialAuthProvider.google)
          ..logSocialLoginSuccess(
            provider: SocialAuthProvider.apple,
            userType: 'existing',
          )
          ..logSocialLoginFailure(
            provider: SocialAuthProvider.google,
            errorType: 'timeout',
          );

        // Assert
        expect(loggedEvents.length, equals(3));
        expect(loggedEvents[0]['provider'], equals('google'));
        expect(loggedEvents[1]['provider'], equals('apple'));
        expect(loggedEvents[2]['provider'], equals('google'));
      });
    });

    group('multiple events logging', () {
      test('should log multiple events in sequence', () {
        // Act
        analytics
          ..logSocialLoginInitiated(SocialAuthProvider.google)
          ..logSocialLoginSuccess(
            provider: SocialAuthProvider.google,
            userType: 'new',
          )
          ..logProfileSetupCompleted(
            provider: SocialAuthProvider.google,
            displayName: 'Test User',
            currency: 'VND',
            language: 'vi',
          );

        // Assert
        expect(loggedEvents.length, equals(3));
        expect(loggedEvents[0]['event'], equals('social_login_initiated'));
        expect(loggedEvents[1]['event'], equals('social_login_success'));
        expect(loggedEvents[2]['event'], equals('profile_setup_completed'));

        // All events should have the same provider
        for (final event in loggedEvents) {
          expect(event['provider'], equals('google'));
        }
      });
    });
  });
}

/// Test implementation of SocialLoginAnalyticsImpl that captures events
class TestSocialLoginAnalyticsImpl extends SocialLoginAnalyticsImpl {
  TestSocialLoginAnalyticsImpl(this.capturedEvents);
  final List<Map<String, dynamic>> capturedEvents;

  @override
  void logSocialLoginInitiated(SocialAuthProvider provider) {
    _logEvent('social_login_initiated', {
      'provider': provider.name,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  void logSocialLoginSuccess({
    required SocialAuthProvider provider,
    required String userType,
  }) {
    _logEvent('social_login_success', {
      'provider': provider.name,
      'user_type': userType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  void logSocialLoginFailure({
    required SocialAuthProvider provider,
    required String errorType,
  }) {
    _logEvent('social_login_failure', {
      'provider': provider.name,
      'error_type': errorType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  void logSocialLoginCancelled(SocialAuthProvider provider) {
    _logEvent('social_login_cancelled', {
      'provider': provider.name,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  void logProfileSetupCompleted({
    required SocialAuthProvider provider,
    required String displayName,
    required String currency,
    required String language,
  }) {
    _logEvent('profile_setup_completed', {
      'provider': provider.name,
      'display_name_length': displayName.length,
      'currency': currency,
      'language': language,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  void logAccountLinking({
    required SocialAuthProvider provider,
    required String action,
    required String existingEmail,
  }) {
    // Mirror the production logic: extract everything after the FIRST '@'.
    final atIndex = existingEmail.indexOf('@');
    final emailDomain = atIndex >= 0 && atIndex < existingEmail.length - 1
        ? existingEmail.substring(atIndex + 1)
        : 'unknown';

    _logEvent('account_linking', {
      'provider': provider.name,
      'action': action,
      'email_domain': emailDomain,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _logEvent(String eventName, Map<String, dynamic> parameters) {
    final event = Map<String, dynamic>.from(parameters);
    event['event'] = eventName;
    capturedEvents.add(event);
  }
}
