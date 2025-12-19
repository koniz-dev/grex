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
  });
}
