import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/data/services/nonce_generator_impl.dart';
import 'package:grex/features/auth/domain/services/nonce_generator.dart';

void main() {
  group('NonceGeneratorImpl', () {
    late NonceGenerator nonceGenerator;

    setUp(() {
      nonceGenerator = NonceGeneratorImpl();
    });

    test('should generate nonce with minimum 32 characters', () async {
      // Act
      final result = await nonceGenerator.generateNonce();

      // Assert
      expect(result.plainNonce.length, greaterThanOrEqualTo(32));
      expect(result.hashedNonce.length, greaterThan(0));
    });

    test('should generate unique nonces', () async {
      // Act
      final result1 = await nonceGenerator.generateNonce();
      final result2 = await nonceGenerator.generateNonce();

      // Assert
      expect(result1.plainNonce, isNot(equals(result2.plainNonce)));
      expect(result1.hashedNonce, isNot(equals(result2.hashedNonce)));
    });

    test('should validate correct nonce format', () {
      // Arrange
      const validNonce = 'abcdefghijklmnopqrstuvwxyz123456';

      // Act
      final isValid = nonceGenerator.validateNonce(validNonce);

      // Assert
      expect(isValid, isTrue);
    });

    test('should reject nonce shorter than 32 characters', () {
      // Arrange
      const shortNonce = 'short';

      // Act
      final isValid = nonceGenerator.validateNonce(shortNonce);

      // Assert
      expect(isValid, isFalse);
    });

    test('should reject nonce with invalid characters', () {
      // Arrange
      const invalidNonce = r'abcdefghijklmnopqrstuvwxyz!@#$%^';

      // Act
      final isValid = nonceGenerator.validateNonce(invalidNonce);

      // Assert
      expect(isValid, isFalse);
    });

    test('should clear used nonces', () async {
      // Arrange
      await nonceGenerator.generateNonce();
      await nonceGenerator.generateNonce();

      // Act
      nonceGenerator.clearUsedNonces();

      // Assert - Should not throw when generating after clear
      expect(
        () async => nonceGenerator.generateNonce(),
        returnsNormally,
      );
    });

    test('should generate nonce with custom length', () async {
      // Act
      final result = await nonceGenerator.generateNonce(length: 64);

      // Assert
      expect(result.plainNonce.length, greaterThanOrEqualTo(64));
    });

    test('should throw error for length less than 32', () async {
      // Act & Assert
      expect(
        () async => nonceGenerator.generateNonce(length: 16),
        throwsArgumentError,
      );
    });
  });
}
