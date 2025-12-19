import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/validators/validators.dart';

void main() {
  group('InputValidators', () {
    group('Property Test 2: Input validation rejects invalid data', () {
      test('should reject various invalid email formats', () {
        final invalidEmails = [
          '', // Empty
          ' ', // Whitespace only
          'invalid', // No @ symbol
          '@domain.com', // No local part
          'user@', // No domain
          'user name@domain.com', // Space in local part
          'user@domain .com', // Space in domain
          'a' * 255 + '@domain.com', // Too long
          'user@${'a' * 250}.com', // Domain too long
        ];

        for (final email in invalidEmails) {
          final result = InputValidators.validateEmail(email);
          expect(result, isNotNull, reason: 'Should reject email: "$email"');
        }
      });

      test('should accept valid email formats', () {
        final validEmails = [
          'user@domain.com',
          'test.email@example.org',
          'user+tag@domain.co.uk',
          'firstname.lastname@company.com',
          'user123@test-domain.com',
          'a@b.co',
        ];

        for (final email in validEmails) {
          final result = InputValidators.validateEmail(email);
          expect(result, isNull, reason: 'Should accept email: "$email"');
        }
      });

      test('should reject weak passwords', () {
        final weakPasswords = [
          '', // Empty
          '123', // Too short
          'password', // No uppercase, numbers, special chars
          'PASSWORD', // No lowercase, numbers, special chars
          '12345678', // No letters, special chars
          'Password1', // No special chars
          'Password!', // No numbers
          'password1!', // No uppercase
          'PASSWORD1!', // No lowercase
          'a' * 129, // Too long
        ];

        for (final password in weakPasswords) {
          final result = InputValidators.validatePassword(password);
          expect(
            result,
            isNotNull,
            reason: 'Should reject password: "$password"',
          );
        }
      });

      test('should accept strong passwords', () {
        final strongPasswords = [
          'Password1!',
          'MyStr0ng@Pass',
          'C0mplex#Password',
          r'Secure123$',
          'Valid8@Password',
        ];

        for (final password in strongPasswords) {
          final result = InputValidators.validatePassword(password);
          expect(result, isNull, reason: 'Should accept password: "$password"');
        }
      });

      test('should reject invalid display names', () {
        final invalidNames = [
          '', // Empty
          ' ', // Whitespace only
          'a', // Too short
          'a' * 51, // Too long
          'user@name', // Invalid characters
          'user<script>', // Invalid characters
        ];

        for (final name in invalidNames) {
          final result = InputValidators.validateDisplayName(name);
          expect(result, isNotNull, reason: 'Should reject name: "$name"');
        }
      });

      test('should accept valid display names', () {
        final validNames = [
          'John Doe',
          'Jane_Smith',
          'User123',
          'Test-User',
          'Name.With.Dots',
          'Simple Name',
        ];

        for (final name in validNames) {
          final result = InputValidators.validateDisplayName(name);
          expect(result, isNull, reason: 'Should accept name: "$name"');
        }
      });

      test('should reject invalid currency codes', () {
        final invalidCodes = [
          '', // Empty
          'US', // Too short
          'USDD', // Too long
          'us1', // Contains number
          'us@', // Contains special char
          'XXX', // Unsupported currency
        ];

        for (final code in invalidCodes) {
          final result = InputValidators.validateCurrencyCode(code);
          expect(result, isNotNull, reason: 'Should reject currency: "$code"');
        }
      });

      test('should accept valid currency codes', () {
        final validCodes = [
          'VND',
          'USD',
          'EUR',
          'GBP',
          'JPY',
          'KRW',
        ];

        for (final code in validCodes) {
          final result = InputValidators.validateCurrencyCode(code);
          expect(result, isNull, reason: 'Should accept currency: "$code"');
        }
      });

      test('should reject invalid language codes', () {
        final invalidCodes = [
          '', // Empty
          'v', // Too short
          'vii', // Too long
          'V1', // Contains number
          'v@', // Contains special char
          'xx', // Unsupported language
        ];

        for (final code in invalidCodes) {
          final result = InputValidators.validateLanguageCode(code);
          expect(result, isNotNull, reason: 'Should reject language: "$code"');
        }
      });

      test('should accept valid language codes', () {
        final validCodes = [
          'vi',
          'en',
          'zh',
          'ja',
          'ko',
          'th',
        ];

        for (final code in validCodes) {
          final result = InputValidators.validateLanguageCode(code);
          expect(result, isNull, reason: 'Should accept language: "$code"');
        }
      });
    });

    group('validateEmail', () {
      test('should return error for null email', () {
        final result = InputValidators.validateEmail(null);
        expect(result, equals('Email is required'));
      });

      test('should return error for empty email', () {
        final result = InputValidators.validateEmail('');
        expect(result, equals('Email is required'));
      });

      test('should return error for email without @', () {
        final result = InputValidators.validateEmail('invalidemail');
        expect(result, equals('Please enter a valid email address'));
      });

      test('should return null for valid email', () {
        final result = InputValidators.validateEmail('test@example.com');
        expect(result, isNull);
      });

      test('should handle email with spaces by trimming', () {
        final result = InputValidators.validateEmail('  test@example.com  ');
        expect(result, isNull);
      });
    });

    group('validatePassword', () {
      test('should return error for null password', () {
        final result = InputValidators.validatePassword(null);
        expect(result, equals('Password is required'));
      });

      test('should return error for short password', () {
        final result = InputValidators.validatePassword('123');
        expect(result, equals('Password must be at least 8 characters long'));
      });

      test('should return error for password without uppercase', () {
        final result = InputValidators.validatePassword('password1!');
        expect(
          result,
          equals('Password must contain at least one uppercase letter'),
        );
      });

      test('should return null for strong password', () {
        final result = InputValidators.validatePassword('StrongPass1!');
        expect(result, isNull);
      });
    });

    group('validateDisplayName', () {
      test('should return error for null display name', () {
        final result = InputValidators.validateDisplayName(null);
        expect(result, equals('Display name is required'));
      });

      test('should return error for empty display name', () {
        final result = InputValidators.validateDisplayName('');
        expect(result, equals('Display name is required'));
      });

      test('should return error for too long display name', () {
        final longName = 'a' * 51;
        final result = InputValidators.validateDisplayName(longName);
        expect(result, equals('Display name must be 50 characters or less'));
      });

      test('should return null for valid display name', () {
        final result = InputValidators.validateDisplayName('John Doe');
        expect(result, isNull);
      });
    });

    group('validateCurrencyCode', () {
      test('should return error for null currency code', () {
        final result = InputValidators.validateCurrencyCode(null);
        expect(result, equals('Currency code is required'));
      });

      test('should return error for wrong length', () {
        final result = InputValidators.validateCurrencyCode('US');
        expect(result, equals('Currency code must be exactly 3 characters'));
      });

      test('should return error for unsupported currency', () {
        final result = InputValidators.validateCurrencyCode('XXX');
        expect(result, equals('Currency code is not supported'));
      });

      test('should return null for valid currency', () {
        final result = InputValidators.validateCurrencyCode('VND');
        expect(result, isNull);
      });

      test('should handle lowercase by converting to uppercase', () {
        final result = InputValidators.validateCurrencyCode('usd');
        expect(result, isNull);
      });
    });

    group('validateLanguageCode', () {
      test('should return error for null language code', () {
        final result = InputValidators.validateLanguageCode(null);
        expect(result, equals('Language code is required'));
      });

      test('should return error for wrong length', () {
        final result = InputValidators.validateLanguageCode('eng');
        expect(result, equals('Language code must be exactly 2 characters'));
      });

      test('should return error for unsupported language', () {
        final result = InputValidators.validateLanguageCode('xx');
        expect(result, equals('Language code is not supported'));
      });

      test('should return null for valid language', () {
        final result = InputValidators.validateLanguageCode('vi');
        expect(result, isNull);
      });

      test('should handle uppercase by converting to lowercase', () {
        final result = InputValidators.validateLanguageCode('EN');
        expect(result, isNull);
      });
    });

    group('validatePasswordConfirmation', () {
      test('should return error for null confirmation', () {
        final result = InputValidators.validatePasswordConfirmation(
          'password',
          null,
        );
        expect(result, equals('Password confirmation is required'));
      });

      test('should return error for mismatched passwords', () {
        final result = InputValidators.validatePasswordConfirmation(
          'password1',
          'password2',
        );
        expect(result, equals('Passwords do not match'));
      });

      test('should return null for matching passwords', () {
        final result = InputValidators.validatePasswordConfirmation(
          'password',
          'password',
        );
        expect(result, isNull);
      });
    });

    group('utility methods', () {
      test(
        'isEmptyOrWhitespace should detect empty and whitespace strings',
        () {
          expect(InputValidators.isEmptyOrWhitespace(null), isTrue);
          expect(InputValidators.isEmptyOrWhitespace(''), isTrue);
          expect(InputValidators.isEmptyOrWhitespace('   '), isTrue);
          expect(InputValidators.isEmptyOrWhitespace('text'), isFalse);
          expect(InputValidators.isEmptyOrWhitespace(' text '), isFalse);
        },
      );

      test('sanitizeInput should trim and remove null bytes', () {
        expect(InputValidators.sanitizeInput(null), equals(''));
        expect(InputValidators.sanitizeInput('  text  '), equals('text'));
        expect(
          InputValidators.sanitizeInput('text\x00with\x00nulls'),
          equals('textwithnulls'),
        );
      });
    });
  });
}
