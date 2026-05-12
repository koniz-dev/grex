import 'package:flutter/foundation.dart';
import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';

/// Analytics service for tracking social login events
abstract class SocialLoginAnalytics {
  /// Log when social login is initiated
  void logSocialLoginInitiated(SocialAuthProvider provider);

  /// Log when social login succeeds
  void logSocialLoginSuccess({
    required SocialAuthProvider provider,
    required String userType, // 'new' or 'existing'
  });

  /// Log when social login fails
  void logSocialLoginFailure({
    required SocialAuthProvider provider,
    required String errorType,
  });

  /// Log when social login is cancelled by user
  void logSocialLoginCancelled(SocialAuthProvider provider);

  /// Log when profile setup is completed
  void logProfileSetupCompleted({
    required SocialAuthProvider provider,
    required String displayName,
    required String currency,
    required String language,
  });

  /// Log account linking actions
  void logAccountLinking({
    required SocialAuthProvider provider,
    required String action, // 'confirmed' or 'declined'
    required String existingEmail,
  });
}

/// Implementation of SocialLoginAnalytics
class SocialLoginAnalyticsImpl implements SocialLoginAnalytics {
  // In a real app, this would integrate with Firebase Analytics,
  // Mixpanel, or another analytics service

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
    _logEvent('account_linking', {
      'provider': provider.name,
      'action': action,
      'email_domain': _extractEmailDomain(existingEmail),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _logEvent(String eventName, Map<String, dynamic> parameters) {
    // In development, just print to console
    // In production, this would send to analytics service
    debugPrint('[ANALYTICS] $eventName: $parameters');
  }

  String _extractEmailDomain(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex < 0 || atIndex == email.length - 1) {
      return 'unknown';
    }
    return email.substring(atIndex + 1);
  }
}
