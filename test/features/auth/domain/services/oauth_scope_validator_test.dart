import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';
import 'package:grex/features/auth/domain/services/oauth_scope_validator.dart';

void main() {
  group('OAuthScopeValidator', () {
    group('validateScopes', () {
      test('should return true for valid Google scopes', () {
        // Arrange
        const provider = SocialAuthProvider.google;
        final validScopes = ['email', 'profile'];

        // Act
        final result = OAuthScopeValidator.validateScopes(
          provider,
          validScopes,
        );

        // Assert
        expect(result, isTrue);
      });

      test('should return true for valid Apple scopes', () {
        // Arrange
        const provider = SocialAuthProvider.apple;
        final validScopes = ['email', 'name'];

        // Act
        final result = OAuthScopeValidator.validateScopes(
          provider,
          validScopes,
        );

        // Assert
        expect(result, isTrue);
      });

      test('should return false for invalid Google scopes', () {
        // Arrange
        const provider = SocialAuthProvider.google;
        final invalidScopes = ['email', 'profile', 'calendar', 'drive'];

        // Act
        final result = OAuthScopeValidator.validateScopes(
          provider,
          invalidScopes,
        );

        // Assert
        expect(result, isFalse);
      });

      test('should return false for invalid Apple scopes', () {
        // Arrange
        const provider = SocialAuthProvider.apple;
        final invalidScopes = ['email', 'name', 'contacts', 'photos'];

        // Act
        final result = OAuthScopeValidator.validateScopes(
          provider,
          invalidScopes,
        );

        // Assert
        expect(result, isFalse);
      });

      test('should return false for missing required Google scopes', () {
        // Arrange
        const provider = SocialAuthProvider.google;
        final incompleteScopes = ['email']; // Missing 'profile'

        // Act
        final result = OAuthScopeValidator.validateScopes(
          provider,
          incompleteScopes,
        );

        // Assert
        expect(result, isFalse);
      });

      test('should return false for missing required Apple scopes', () {
        // Arrange
        const provider = SocialAuthProvider.apple;
        final incompleteScopes = ['name']; // Missing 'email'

        // Act
        final result = OAuthScopeValidator.validateScopes(
          provider,
          incompleteScopes,
        );

        // Assert
        expect(result, isFalse);
      });

      test('should return false for empty scopes', () {
        // Arrange
        const provider = SocialAuthProvider.google;
        final emptyScopes = <String>[];

        // Act
        final result = OAuthScopeValidator.validateScopes(
          provider,
          emptyScopes,
        );

        // Assert
        expect(result, isFalse);
      });
    });

    group('getAllowedScopes', () {
      test('should return correct allowed scopes for Google', () {
        // Arrange
        const provider = SocialAuthProvider.google;

        // Act
        final scopes = OAuthScopeValidator.getAllowedScopes(provider);

        // Assert
        expect(scopes, containsAll(['email', 'profile', 'openid']));
        expect(scopes.length, equals(3));
      });

      test('should return correct allowed scopes for Apple', () {
        // Arrange
        const provider = SocialAuthProvider.apple;

        // Act
        final scopes = OAuthScopeValidator.getAllowedScopes(provider);

        // Assert
        expect(scopes, containsAll(['email', 'name']));
        expect(scopes.length, equals(2));
      });
    });

    group('getRequiredScopes', () {
      test('should return correct required scopes for Google', () {
        // Arrange
        const provider = SocialAuthProvider.google;

        // Act
        final scopes = OAuthScopeValidator.getRequiredScopes(provider);

        // Assert
        expect(scopes, containsAll(['email', 'profile']));
        expect(scopes.length, equals(2));
      });

      test('should return correct required scopes for Apple', () {
        // Arrange
        const provider = SocialAuthProvider.apple;

        // Act
        final scopes = OAuthScopeValidator.getRequiredScopes(provider);

        // Assert
        expect(scopes, contains('email'));
        expect(scopes.length, equals(1));
      });
    });

    group('getScopeDocumentation', () {
      test('should return non-empty documentation for Google', () {
        // Arrange
        const provider = SocialAuthProvider.google;

        // Act
        final documentation = OAuthScopeValidator.getScopeDocumentation(
          provider,
        );

        // Assert
        expect(documentation, isNotEmpty);
        expect(documentation.toLowerCase(), contains('google'));
        expect(documentation.toLowerCase(), contains('email'));
        expect(documentation.toLowerCase(), contains('profile'));
        expect(documentation.toLowerCase(), contains('security'));
      });

      test('should return non-empty documentation for Apple', () {
        // Arrange
        const provider = SocialAuthProvider.apple;

        // Act
        final documentation = OAuthScopeValidator.getScopeDocumentation(
          provider,
        );

        // Assert
        expect(documentation, isNotEmpty);
        expect(documentation.toLowerCase(), contains('apple'));
        expect(documentation.toLowerCase(), contains('email'));
        expect(documentation.toLowerCase(), contains('name'));
        expect(documentation.toLowerCase(), contains('security'));
      });

      test('should mention minimal scopes in documentation', () {
        for (final provider in SocialAuthProvider.values) {
          // Act
          final documentation = OAuthScopeValidator.getScopeDocumentation(
            provider,
          );

          // Assert
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
        }
      });
    });
  });
}
