import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';

/// Service for validating OAuth scope configurations
class OAuthScopeValidator {
  /// Validates that only necessary scopes are requested for the given provider
  static bool validateScopes(
    SocialAuthProvider provider,
    List<String> requestedScopes,
  ) {
    final allowedScopes = _getAllowedScopes(provider);

    // Check that all requested scopes are in the allowed list
    for (final scope in requestedScopes) {
      if (!allowedScopes.contains(scope)) {
        return false;
      }
    }

    // Check that required scopes are present
    final requiredScopes = _getRequiredScopes(provider);
    for (final scope in requiredScopes) {
      if (!requestedScopes.contains(scope)) {
        return false;
      }
    }

    return true;
  }

  /// Gets the allowed scopes for a provider
  static List<String> getAllowedScopes(SocialAuthProvider provider) {
    return _getAllowedScopes(provider);
  }

  /// Gets the required scopes for a provider
  static List<String> getRequiredScopes(SocialAuthProvider provider) {
    return _getRequiredScopes(provider);
  }

  /// Documents the scope requirements for each provider
  static String getScopeDocumentation(SocialAuthProvider provider) {
    switch (provider) {
      case SocialAuthProvider.google:
        return '''
Google OAuth Scopes:
- email: Required to get user's email address for account identification
- profile: Required to get user's display name and basic profile information
- openid: Automatically included by Google for OpenID Connect

Security Note: We only request the minimum scopes necessary for authentication
and basic profile setup. No additional permissions are requested.
''';
      case SocialAuthProvider.apple:
        return '''
Apple Sign In Scopes:
- email: Required to get user's email address (may be hidden by Apple)
- name: Required to get user's display name (only provided on first sign-in)

Security Note: Apple Sign In automatically provides minimal scopes.
Users can choose to hide their email address, in which case Apple provides
a private relay email address.
''';
    }
  }

  static List<String> _getAllowedScopes(SocialAuthProvider provider) {
    switch (provider) {
      case SocialAuthProvider.google:
        return ['email', 'profile', 'openid'];
      case SocialAuthProvider.apple:
        return ['email', 'name'];
    }
  }

  static List<String> _getRequiredScopes(SocialAuthProvider provider) {
    switch (provider) {
      case SocialAuthProvider.google:
        return ['email', 'profile'];
      case SocialAuthProvider.apple:
        return ['email'];
    }
  }
}
