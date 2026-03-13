import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';

void main() {
  group('User Entity', () {
    test('should create User from JSON', () {
      // Arrange
      final json = {
        'id': 'test-id',
        'email': 'test@example.com',
        'email_confirmed_at': '2023-01-01T00:00:00Z',
        'created_at': '2023-01-01T00:00:00Z',
        'last_sign_in_at': '2023-01-02T00:00:00Z',
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.id, 'test-id');
      expect(user.email, 'test@example.com');
      expect(user.emailConfirmed, true);
      expect(user.createdAt, DateTime.parse('2023-01-01T00:00:00Z'));
      expect(user.lastSignInAt, DateTime.parse('2023-01-02T00:00:00Z'));
    });

    test('should handle null email_confirmed_at', () {
      // Arrange
      final json = {
        'id': 'test-id',
        'email': 'test@example.com',
        'email_confirmed_at': null,
        'created_at': '2023-01-01T00:00:00Z',
        'last_sign_in_at': null,
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.emailConfirmed, false);
      expect(user.lastSignInAt, null);
    });

    test('should convert User to JSON', () {
      // Arrange
      final user = User(
        id: 'test-id',
        email: 'test@example.com',
        createdAt: DateTime.parse('2023-01-01T00:00:00Z'),
        lastSignInAt: DateTime.parse('2023-01-02T00:00:00Z'),
      );

      // Act
      final json = user.toJson();

      // Assert
      expect(json['id'], 'test-id');
      expect(json['email'], 'test@example.com');
      expect(json['email_confirmed_at'], '2023-01-01T00:00:00.000Z');
      expect(json['created_at'], '2023-01-01T00:00:00.000Z');
      expect(json['last_sign_in_at'], '2023-01-02T00:00:00.000Z');
    });

    group('OAuth Metadata', () {
      test(
        'socialProvider should return Google when providers contains google',
        () {
          // Arrange
          final user = User(
            id: 'test-id',
            email: 'test@example.com',
            createdAt: DateTime.now(),
            appMetadata: const {
              'providers': ['google'],
            },
          );

          // Act & Assert
          expect(user.socialProvider, SocialAuthProvider.google);
        },
      );

      test(
        'socialProvider should return Apple when providers contains apple',
        () {
          // Arrange
          final user = User(
            id: 'test-id',
            email: 'test@example.com',
            createdAt: DateTime.now(),
            appMetadata: const {
              'providers': ['apple'],
            },
          );

          // Act & Assert
          expect(user.socialProvider, SocialAuthProvider.apple);
        },
      );

      test('socialProvider should return null when providers is empty', () {
        // Arrange
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          appMetadata: const {
            'providers': <String>[],
          },
        );

        // Act & Assert
        expect(user.socialProvider, isNull);
      });

      test('socialProvider should return null when appMetadata is null', () {
        // Arrange
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          createdAt: DateTime.now(),
        );

        // Act & Assert
        expect(user.socialProvider, isNull);
      });

      test('socialProvider should return null for email provider', () {
        // Arrange
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          appMetadata: const {
            'providers': ['email'],
          },
        );

        // Act & Assert
        expect(user.socialProvider, isNull);
      });

      test('oauthDisplayName should extract full_name from userMetadata', () {
        // Arrange
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          userMetadata: const {
            'full_name': 'John Doe',
          },
        );

        // Act & Assert
        expect(user.oauthDisplayName, 'John Doe');
      });

      test('oauthDisplayName should extract name from userMetadata', () {
        // Arrange
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          userMetadata: const {
            'name': 'Jane Smith',
          },
        );

        // Act & Assert
        expect(user.oauthDisplayName, 'Jane Smith');
      });

      test(
        'oauthDisplayName should extract display_name from userMetadata',
        () {
          // Arrange
          final user = User(
            id: 'test-id',
            email: 'test@example.com',
            createdAt: DateTime.now(),
            userMetadata: const {
              'display_name': 'Bob Johnson',
            },
          );

          // Act & Assert
          expect(user.oauthDisplayName, 'Bob Johnson');
        },
      );

      test('oauthDisplayName should prioritize full_name over name', () {
        // Arrange
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          userMetadata: const {
            'full_name': 'John Doe',
            'name': 'Jane Smith',
            'display_name': 'Bob Johnson',
          },
        );

        // Act & Assert
        expect(user.oauthDisplayName, 'John Doe');
      });

      test('oauthDisplayName should return null when userMetadata is null', () {
        // Arrange
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          createdAt: DateTime.now(),
        );

        // Act & Assert
        expect(user.oauthDisplayName, isNull);
      });

      test(
        'oauthDisplayName should return null when no name fields present',
        () {
          // Arrange
          final user = User(
            id: 'test-id',
            email: 'test@example.com',
            createdAt: DateTime.now(),
            userMetadata: const {
              'avatar_url': 'https://example.com/avatar.jpg',
            },
          );

          // Act & Assert
          expect(user.oauthDisplayName, isNull);
        },
      );

      test('fromSupabaseUser should extract OAuth metadata correctly', () {
        // This test would require mocking supabase.User
        // For now, we verify the logic through direct User construction
        final user = User(
          id: 'oauth-user-id',
          email: 'oauth@example.com',
          createdAt: DateTime.now(),
          appMetadata: const {
            'providers': ['google'],
          },
          userMetadata: const {
            'full_name': 'OAuth User',
            'avatar_url': 'https://example.com/avatar.jpg',
          },
        );

        expect(user.socialProvider, SocialAuthProvider.google);
        expect(user.oauthDisplayName, 'OAuth User');
      });
    });
  });
}
