import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/data/services/supabase_email_verification_service.dart';
import 'package:grex/features/auth/domain/services/email_verification_service.dart';

/// Unit tests for email verification service
///
/// Tests verification email sending, verification link processing,
/// user status updates, and unverified user access restrictions.
///
/// Requirements: 7.1, 7.2, 7.3, 7.4, 7.5
void main() {
  group('SupabaseEmailVerificationService', () {
    late EmailVerificationService verificationService;

    setUp(() {
      verificationService = const SupabaseEmailVerificationService();
    });

    group('processVerificationLink', () {
      test('should process valid verification link successfully', () {
        // Arrange
        const validLink =
            'https://app.grex.com/auth/confirm?token=abc123&email=test@example.com&type=signup';

        // Act
        final result = verificationService.processVerificationLink(validLink);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not fail for valid link'),
          (data) {
            expect(data.token, equals('abc123'));
            expect(data.email, equals('test@example.com'));
          },
        );
      });

      test('should reject link without token parameter', () {
        // Arrange
        const invalidLink =
            'https://app.grex.com/auth/confirm?email=test@example.com&type=signup';

        // Act
        final result = verificationService.processVerificationLink(invalidLink);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure.message, contains('token'));
          },
          (_) => fail('Should fail for link without token'),
        );
      });

      test('should reject link without email parameter', () {
        // Arrange
        const invalidLink =
            'https://app.grex.com/auth/confirm?token=abc123&type=signup';

        // Act
        final result = verificationService.processVerificationLink(invalidLink);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure.message, contains('email'));
          },
          (_) => fail('Should fail for link without email'),
        );
      });

      test('should reject link with invalid email format', () {
        // Arrange
        const invalidLink =
            'https://app.grex.com/auth/confirm?token=abc123&email=invalid-email&type=signup';

        // Act
        final result = verificationService.processVerificationLink(invalidLink);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure.message, contains('email format'));
          },
          (_) => fail('Should fail for invalid email format'),
        );
      });

      test('should reject link with wrong type parameter', () {
        // Arrange
        const invalidLink =
            'https://app.grex.com/auth/confirm?token=abc123&email=test@example.com&type=recovery';

        // Act
        final result = verificationService.processVerificationLink(invalidLink);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure.message, contains('type'));
          },
          (_) => fail('Should fail for wrong type'),
        );
      });

      test('should handle malformed URLs gracefully', () {
        // Arrange
        const malformedLink = 'not-a-valid-url';

        // Act
        final result = verificationService.processVerificationLink(
          malformedLink,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure.message, contains('process verification link'));
          },
          (_) => fail('Should fail for malformed URL'),
        );
      });
    });

    group('isVerificationLink', () {
      test('should identify valid verification links', () {
        // Arrange
        const validLinks = [
          'https://app.grex.com/auth/confirm?token=abc123&email=test@example.com&type=signup',
          'https://grex.com/auth/confirm?token=xyz789&email=user@test.com&type=signup',
          'http://localhost:3000/auth/confirm?token=def456&email=dev@local.com&type=signup',
        ];

        // Act & Assert
        for (final link in validLinks) {
          expect(
            verificationService.isVerificationLink(link),
            isTrue,
            reason: 'Should identify $link as verification link',
          );
        }
      });

      test('should reject invalid verification links', () {
        // Arrange
        const invalidLinks = [
          'https://app.grex.com/login',
          'https://app.grex.com/auth/confirm?token=abc123', // Missing email and type
          'https://app.grex.com/auth/confirm?email=test@example.com&type=signup', // Missing token
          'https://app.grex.com/other-path?token=abc123&email=test@example.com&type=signup',
          'not-a-url-at-all',
        ];

        // Act & Assert
        for (final link in invalidLinks) {
          expect(
            verificationService.isVerificationLink(link),
            isFalse,
            reason: 'Should reject $link as verification link',
          );
        }
      });
    });

    group('extractToken', () {
      test('should extract token from valid links', () {
        // Arrange
        const link =
            'https://app.grex.com/auth/confirm?token=abc123&email=test@example.com&type=signup';

        // Act
        final token = verificationService.extractToken(link);

        // Assert
        expect(token, equals('abc123'));
      });

      test('should return null for links without token', () {
        // Arrange
        const link =
            'https://app.grex.com/auth/confirm?email=test@example.com&type=signup';

        // Act
        final token = verificationService.extractToken(link);

        // Assert
        expect(token, isNull);
      });

      test('should handle malformed URLs gracefully', () {
        // Arrange
        const malformedLink = 'not-a-valid-url';

        // Act
        final token = verificationService.extractToken(malformedLink);

        // Assert
        expect(token, isNull);
      });
    });

    group('extractEmail', () {
      test('should extract email from valid links', () {
        // Arrange
        const link =
            'https://app.grex.com/auth/confirm?token=abc123&email=test@example.com&type=signup';

        // Act
        final email = verificationService.extractEmail(link);

        // Assert
        expect(email, equals('test@example.com'));
      });

      test('should return null for links without email', () {
        // Arrange
        const link =
            'https://app.grex.com/auth/confirm?token=abc123&type=signup';

        // Act
        final email = verificationService.extractEmail(link);

        // Assert
        expect(email, isNull);
      });

      test('should handle malformed URLs gracefully', () {
        // Arrange
        const malformedLink = 'not-a-valid-url';

        // Act
        final email = verificationService.extractEmail(malformedLink);

        // Assert
        expect(email, isNull);
      });
    });

    group('EmailVerificationData', () {
      test('should create verification data correctly', () {
        // Arrange
        const token = 'test-token-123';
        const email = 'test@example.com';

        // Act
        const data = EmailVerificationData(
          token: token,
          email: email,
        );

        // Assert
        expect(data.token, equals(token));
        expect(data.email, equals(email));
      });

      test('should implement equality correctly', () {
        // Arrange
        const data1 = EmailVerificationData(
          token: 'token123',
          email: 'test@example.com',
        );
        const data2 = EmailVerificationData(
          token: 'token123',
          email: 'test@example.com',
        );
        const data3 = EmailVerificationData(
          token: 'different-token',
          email: 'test@example.com',
        );

        // Act & Assert
        expect(data1, equals(data2));
        expect(data1, isNot(equals(data3)));
        expect(data1.hashCode, equals(data2.hashCode));
        expect(data1.hashCode, isNot(equals(data3.hashCode)));
      });

      test('should have meaningful toString', () {
        // Arrange
        const data = EmailVerificationData(
          token: 'token123',
          email: 'test@example.com',
        );

        // Act
        final stringRepresentation = data.toString();

        // Assert
        expect(stringRepresentation, contains('test@example.com'));
        expect(stringRepresentation, contains('EmailVerificationData'));
      });
    });

    group('Edge Cases', () {
      test('should handle empty token parameter', () {
        // Arrange
        const link =
            'https://app.grex.com/auth/confirm?token=&email=test@example.com&type=signup';

        // Act
        final result = verificationService.processVerificationLink(link);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure.message, contains('token'));
          },
          (_) => fail('Should fail for empty token'),
        );
      });

      test('should handle empty email parameter', () {
        // Arrange
        const link =
            'https://app.grex.com/auth/confirm?token=abc123&email=&type=signup';

        // Act
        final result = verificationService.processVerificationLink(link);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure.message, contains('email'));
          },
          (_) => fail('Should fail for empty email'),
        );
      });

      test('should handle URL with fragment', () {
        // Arrange
        const link =
            'https://app.grex.com/auth/confirm?token=abc123&email=test@example.com&type=signup#fragment';

        // Act
        final result = verificationService.processVerificationLink(link);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should handle URL with fragment'),
          (data) {
            expect(data.token, equals('abc123'));
            expect(data.email, equals('test@example.com'));
          },
        );
      });

      test('should handle URL with additional parameters', () {
        // Arrange
        const link =
            'https://app.grex.com/auth/confirm?token=abc123&email=test@example.com&type=signup&extra=param';

        // Act
        final result = verificationService.processVerificationLink(link);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should handle additional parameters'),
          (data) {
            expect(data.token, equals('abc123'));
            expect(data.email, equals('test@example.com'));
          },
        );
      });

      test('should handle case-sensitive email validation', () {
        // Arrange
        const link =
            'https://app.grex.com/auth/confirm?token=abc123&email=Test@Example.COM&type=signup';

        // Act
        final result = verificationService.processVerificationLink(link);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should handle case variations in email'),
          (data) {
            expect(data.email, equals('Test@Example.COM'));
          },
        );
      });
    });
  });
}
