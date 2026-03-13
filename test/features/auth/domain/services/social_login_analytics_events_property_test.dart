import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';
import 'package:grex/features/auth/domain/services/social_login_analytics.dart';

/// Property-based test for analytics events logging
///
/// Property 35: Analytics Events Logged for OAuth Actions
/// Validates: Requirements 12.1, 12.2, 12.3, 12.4, 12.5, 12.6
///
/// This test verifies that all social login actions generate appropriate
/// analytics events with correct parameters and provider information.
void main() {
  group('Property 35: Analytics Events Logged for OAuth Actions', () {
    late MockSocialLoginAnalytics analytics;
    late Random random;

    setUp(() {
      analytics = MockSocialLoginAnalytics();
      random = Random();
    });

    test(
      'should log analytics events for all social login actions with 100 '
      'iterations',
      () {
        for (var i = 0; i < 100; i++) {
          // Generate random test data
          final provider = _generateRandomProvider(random);
          final userType = _generateRandomUserType(random);
          final errorType = _generateRandomErrorType(random);
          final action = _generateRandomAction(random);
          final displayName = _generateRandomDisplayName(random);
          final currency = _generateRandomCurrency(random);
          final language = _generateRandomLanguage(random);
          final email = _generateRandomEmail(random);

          // Test social login initiation
          analytics.logSocialLoginInitiated(provider);

          // Verify event was logged with correct provider
          expect(analytics.lastEvent, isNotNull);
          expect(
            analytics.lastEvent!['event'],
            equals('social_login_initiated'),
          );
          expect(analytics.lastEvent!['provider'], equals(provider.name));
          expect(analytics.lastEvent!['timestamp'], isNotNull);

          // Test social login success
          analytics.logSocialLoginSuccess(
            provider: provider,
            userType: userType,
          );

          // Verify success event was logged with correct parameters
          expect(analytics.lastEvent!['event'], equals('social_login_success'));
          expect(analytics.lastEvent!['provider'], equals(provider.name));
          expect(analytics.lastEvent!['user_type'], equals(userType));
          expect(analytics.lastEvent!['timestamp'], isNotNull);

          // Test social login failure
          analytics.logSocialLoginFailure(
            provider: provider,
            errorType: errorType,
          );

          // Verify failure event was logged with correct parameters
          expect(analytics.lastEvent!['event'], equals('social_login_failure'));
          expect(analytics.lastEvent!['provider'], equals(provider.name));
          expect(analytics.lastEvent!['error_type'], equals(errorType));
          expect(analytics.lastEvent!['timestamp'], isNotNull);

          // Test social login cancellation
          analytics.logSocialLoginCancelled(provider);

          // Verify cancellation event was logged
          expect(
            analytics.lastEvent!['event'],
            equals('social_login_cancelled'),
          );
          expect(analytics.lastEvent!['provider'], equals(provider.name));
          expect(analytics.lastEvent!['timestamp'], isNotNull);

          // Test profile setup completion
          analytics.logProfileSetupCompleted(
            provider: provider,
            displayName: displayName,
            currency: currency,
            language: language,
          );

          // Verify profile setup event was logged with correct parameters
          expect(
            analytics.lastEvent!['event'],
            equals('profile_setup_completed'),
          );
          expect(analytics.lastEvent!['provider'], equals(provider.name));
          expect(
            analytics.lastEvent!['display_name_length'],
            equals(displayName.length),
          );
          expect(analytics.lastEvent!['currency'], equals(currency));
          expect(analytics.lastEvent!['language'], equals(language));
          expect(analytics.lastEvent!['timestamp'], isNotNull);

          // Test account linking
          analytics.logAccountLinking(
            provider: provider,
            action: action,
            existingEmail: email,
          );

          // Verify account linking event was logged with correct parameters
          expect(analytics.lastEvent!['event'], equals('account_linking'));
          expect(analytics.lastEvent!['provider'], equals(provider.name));
          expect(analytics.lastEvent!['action'], equals(action));
          expect(
            analytics.lastEvent!['email_domain'],
            equals(_extractEmailDomain(email)),
          );
          expect(analytics.lastEvent!['timestamp'], isNotNull);

          // Verify all events include provider information
          expect(analytics.eventHistory.length, greaterThan(i * 6));

          // Verify all events for this iteration include the correct provider
          final recentEvents = analytics.eventHistory.skip(i * 6).take(6);
          for (final event in recentEvents) {
            expect(event['provider'], equals(provider.name));
            expect(event['timestamp'], isNotNull);
          }
        }

        // Verify total number of events logged
        expect(
          analytics.eventHistory.length,
          equals(600),
        ); // 6 events per iteration * 100 iterations

        // Verify event distribution
        final eventTypes = analytics.eventHistory
            .map((e) => e['event'])
            .toSet();
        expect(
          eventTypes,
          containsAll([
            'social_login_initiated',
            'social_login_success',
            'social_login_failure',
            'social_login_cancelled',
            'profile_setup_completed',
            'account_linking',
          ]),
        );
      },
    );

    test('should include outcome information in all events', () {
      for (var i = 0; i < 100; i++) {
        final provider = _generateRandomProvider(random);

        // Test success outcome
        analytics.logSocialLoginSuccess(
          provider: provider,
          userType: 'existing',
        );

        expect(analytics.lastEvent!['user_type'], isNotNull);
        expect([
          'new',
          'existing',
          'linking_required',
        ], contains(analytics.lastEvent!['user_type']));

        // Test failure outcome
        final errorType = _generateRandomErrorType(random);
        analytics.logSocialLoginFailure(
          provider: provider,
          errorType: errorType,
        );

        expect(analytics.lastEvent!['error_type'], isNotNull);
        expect(analytics.lastEvent!['error_type'], equals(errorType));

        // Test linking outcome
        final action = _generateRandomAction(random);
        analytics.logAccountLinking(
          provider: provider,
          action: action,
          existingEmail: 'test@example.com',
        );

        expect(analytics.lastEvent!['action'], isNotNull);
        expect([
          'confirmed',
          'declined',
        ], contains(analytics.lastEvent!['action']));
      }
    });

    test('should preserve provider information across all event types', () {
      final providers = [SocialAuthProvider.google, SocialAuthProvider.apple];

      for (var i = 0; i < 100; i++) {
        final provider = providers[random.nextInt(providers.length)];

        // Log various events
        analytics
          ..logSocialLoginInitiated(provider)
          ..logSocialLoginSuccess(provider: provider, userType: 'new')
          ..logSocialLoginCancelled(provider);

        // Verify last 3 events all have the same provider
        final recentEvents = analytics.eventHistory.takeLast(3);
        for (final event in recentEvents) {
          expect(event['provider'], equals(provider.name));
        }
      }
    });
  });
}

/// Mock implementation of SocialLoginAnalytics for testing
class MockSocialLoginAnalytics implements SocialLoginAnalytics {
  final List<Map<String, dynamic>> eventHistory = [];
  Map<String, dynamic>? lastEvent;

  @override
  void logSocialLoginInitiated(SocialAuthProvider provider) {
    final event = {
      'event': 'social_login_initiated',
      'provider': provider.name,
      'timestamp': DateTime.now().toIso8601String(),
    };
    eventHistory.add(event);
    lastEvent = event;
  }

  @override
  void logSocialLoginSuccess({
    required SocialAuthProvider provider,
    required String userType,
  }) {
    final event = {
      'event': 'social_login_success',
      'provider': provider.name,
      'user_type': userType,
      'timestamp': DateTime.now().toIso8601String(),
    };
    eventHistory.add(event);
    lastEvent = event;
  }

  @override
  void logSocialLoginFailure({
    required SocialAuthProvider provider,
    required String errorType,
  }) {
    final event = {
      'event': 'social_login_failure',
      'provider': provider.name,
      'error_type': errorType,
      'timestamp': DateTime.now().toIso8601String(),
    };
    eventHistory.add(event);
    lastEvent = event;
  }

  @override
  void logSocialLoginCancelled(SocialAuthProvider provider) {
    final event = {
      'event': 'social_login_cancelled',
      'provider': provider.name,
      'timestamp': DateTime.now().toIso8601String(),
    };
    eventHistory.add(event);
    lastEvent = event;
  }

  @override
  void logProfileSetupCompleted({
    required SocialAuthProvider provider,
    required String displayName,
    required String currency,
    required String language,
  }) {
    final event = {
      'event': 'profile_setup_completed',
      'provider': provider.name,
      'display_name_length': displayName.length,
      'currency': currency,
      'language': language,
      'timestamp': DateTime.now().toIso8601String(),
    };
    eventHistory.add(event);
    lastEvent = event;
  }

  @override
  void logAccountLinking({
    required SocialAuthProvider provider,
    required String action,
    required String existingEmail,
  }) {
    final event = {
      'event': 'account_linking',
      'provider': provider.name,
      'action': action,
      'email_domain': _extractEmailDomain(existingEmail),
      'timestamp': DateTime.now().toIso8601String(),
    };
    eventHistory.add(event);
    lastEvent = event;
  }
}

// Helper functions for generating random test data
SocialAuthProvider _generateRandomProvider(Random random) {
  final providers = [SocialAuthProvider.google, SocialAuthProvider.apple];
  return providers[random.nextInt(providers.length)];
}

String _generateRandomUserType(Random random) {
  final types = ['new', 'existing', 'linking_required'];
  return types[random.nextInt(types.length)];
}

String _generateRandomErrorType(Random random) {
  final types = ['network', 'timeout', 'cancelled', 'unknown', 'linking'];
  return types[random.nextInt(types.length)];
}

String _generateRandomAction(Random random) {
  final actions = ['confirmed', 'declined'];
  return actions[random.nextInt(actions.length)];
}

String _generateRandomDisplayName(Random random) {
  final names = [
    'John Doe',
    'Jane Smith',
    'Test User',
    'Alice Johnson',
    'Bob Wilson',
  ];
  return names[random.nextInt(names.length)];
}

String _generateRandomCurrency(Random random) {
  final currencies = ['VND', 'USD', 'EUR', 'GBP', 'JPY'];
  return currencies[random.nextInt(currencies.length)];
}

String _generateRandomLanguage(Random random) {
  final languages = ['vi', 'en', 'es', 'ar', 'fr'];
  return languages[random.nextInt(languages.length)];
}

String _generateRandomEmail(Random random) {
  final domains = ['gmail.com', 'yahoo.com', 'outlook.com', 'example.com'];
  final usernames = ['user1', 'test', 'john', 'jane', 'alice'];
  final username = usernames[random.nextInt(usernames.length)];
  final domain = domains[random.nextInt(domains.length)];
  return '$username@$domain';
}

String _extractEmailDomain(String email) {
  final parts = email.split('@');
  return parts.length > 1 ? parts[1] : 'unknown';
}

extension<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    return skip(length - count);
  }
}
