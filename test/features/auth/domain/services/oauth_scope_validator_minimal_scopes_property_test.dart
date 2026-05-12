import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';
import 'package:grex/features/auth/domain/services/oauth_scope_validator.dart';

void main() {
  group('OAuth Scope Validator - Minimal Scopes Property Tests', () {
    test(
      'Property 30: OAuth Requests Use Minimal Scopes - Google Provider',
      () {
        // Test with 100+ iterations for Google provider
        for (var i = 0; i < 100; i++) {
          // Arrange
          const provider = SocialAuthProvider.google;
          final requiredScopes = OAuthScopeValidator.getRequiredScopes(
            provider,
          );
          final allowedScopes = OAuthScopeValidator.getAllowedScopes(provider);

          // Act & Assert
          // Verify only email and profile scopes are required
          expect(
            requiredScopes,
            containsAll(['email', 'profile']),
            reason: 'Google should require email and profile scopes',
          );

          // Verify no additional scopes beyond allowed ones
          expect(
            requiredScopes.every(allowedScopes.contains),
            isTrue,
            reason: 'All required scopes should be in allowed scopes list',
          );

          // Verify minimal scope set (only necessary scopes)
          expect(
            requiredScopes.length,
            lessThanOrEqualTo(
              3,
            ), // email, profile, openid (auto-added by Google)
            reason: 'Google should use minimal scopes',
          );

          // Verify validation passes for required scopes
          expect(
            OAuthScopeValidator.validateScopes(provider, requiredScopes),
            isTrue,
            reason: 'Required scopes should pass validation',
          );

          // Verify validation fails for excessive scopes
          final excessiveScopes = [...requiredScopes, 'calendar', 'drive'];
          expect(
            OAuthScopeValidator.validateScopes(provider, excessiveScopes),
            isFalse,
            reason: 'Excessive scopes should fail validation',
          );
        }
      },
    );

    test(
      'Property 30: OAuth Requests Use Minimal Scopes - Apple Provider',
      () {
        // Test with 100+ iterations for Apple provider
        for (var i = 0; i < 100; i++) {
          // Arrange
          const provider = SocialAuthProvider.apple;
          final requiredScopes = OAuthScopeValidator.getRequiredScopes(
            provider,
          );
          final allowedScopes = OAuthScopeValidator.getAllowedScopes(provider);

          // Act & Assert
          // Verify only email scope is required (name is optional)
          expect(
            requiredScopes,
            contains('email'),
            reason: 'Apple should require email scope',
          );

          // Verify no additional scopes beyond allowed ones
          expect(
            requiredScopes.every(allowedScopes.contains),
            isTrue,
            reason: 'All required scopes should be in allowed scopes list',
          );

          // Verify minimal scope set
          expect(
            requiredScopes.length,
            lessThanOrEqualTo(2), // email, name
            reason: 'Apple should use minimal scopes',
          );

          // Verify validation passes for required scopes
          expect(
            OAuthScopeValidator.validateScopes(provider, requiredScopes),
            isTrue,
            reason: 'Required scopes should pass validation',
          );

          // Verify validation fails for excessive scopes
          final excessiveScopes = [...requiredScopes, 'contacts', 'photos'];
          expect(
            OAuthScopeValidator.validateScopes(provider, excessiveScopes),
            isFalse,
            reason: 'Excessive scopes should fail validation',
          );
        }
      },
    );

    test(
      'Property 30: OAuth Scope Documentation Completeness',
      () {
        // Test with 100+ iterations
        for (var i = 0; i < 100; i++) {
          for (final provider in SocialAuthProvider.values) {
            // Arrange & Act
            final documentation = OAuthScopeValidator.getScopeDocumentation(
              provider,
            );
            final requiredScopes = OAuthScopeValidator.getRequiredScopes(
              provider,
            );
            final allowedScopes = OAuthScopeValidator.getAllowedScopes(
              provider,
            );

            // Assert
            // Verify documentation exists and is non-empty
            expect(
              documentation.trim(),
              isNotEmpty,
              reason: 'Documentation should exist for ${provider.name}',
            );

            // Verify documentation mentions security
            expect(
              documentation.toLowerCase(),
              contains('security'),
              reason:
                  'Documentation should mention security for ${provider.name}',
            );

            // Verify documentation mentions minimal scopes
            expect(
              documentation.toLowerCase(),
              anyOf([
                contains('minimal'),
                contains('minimum'),
                contains('necessary'),
                contains('required'),
              ]),
              reason:
                  'Documentation should mention minimal scopes for '
                  '${provider.name}',
            );

            // Verify all required scopes are documented
            for (final scope in requiredScopes) {
              expect(
                documentation.toLowerCase(),
                contains(scope.toLowerCase()),
                reason:
                    'Documentation should mention scope "$scope" for '
                    '${provider.name}',
              );
            }

            // Verify allowed scopes are reasonable
            expect(
              allowedScopes.length,
              lessThanOrEqualTo(5),
              reason: 'Should not allow too many scopes for ${provider.name}',
            );
          }
        }
      },
    );

    test(
      'Property 30: Scope Validation Edge Cases',
      () {
        // Test with 100+ iterations
        for (var i = 0; i < 100; i++) {
          for (final provider in SocialAuthProvider.values) {
            // Test empty scopes
            expect(
              OAuthScopeValidator.validateScopes(provider, []),
              isFalse,
              reason:
                  'Empty scopes should fail validation for ${provider.name}',
            );

            // Test null/invalid scopes
            expect(
              OAuthScopeValidator.validateScopes(provider, ['invalid_scope']),
              isFalse,
              reason:
                  'Invalid scopes should fail validation for ${provider.name}',
            );

            // Test case sensitivity
            final requiredScopes = OAuthScopeValidator.getRequiredScopes(
              provider,
            );
            final uppercaseScopes = requiredScopes
                .map((s) => s.toUpperCase())
                .toList();
            expect(
              OAuthScopeValidator.validateScopes(provider, uppercaseScopes),
              isFalse,
              reason:
                  'Uppercase scopes should fail validation for '
                  '${provider.name}',
            );

            // Test duplicate scopes
            final duplicateScopes = [...requiredScopes, ...requiredScopes];
            expect(
              OAuthScopeValidator.validateScopes(provider, duplicateScopes),
              isTrue,
              reason:
                  'Duplicate valid scopes should still pass for '
                  '${provider.name}',
            );
          }
        }
      },
    );
  });
}
