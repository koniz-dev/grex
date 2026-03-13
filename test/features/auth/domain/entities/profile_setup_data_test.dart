import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/profile_setup_data.dart';
import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';

void main() {
  group('ProfileSetupData', () {
    const testDisplayName = 'John Doe';
    const testCurrency = 'VND';
    const testLanguage = 'vi';
    const testProvider = SocialAuthProvider.google;

    group('constructor', () {
      test('creates instance with required fields', () {
        const data = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
        );

        expect(data.displayName, testDisplayName);
        expect(data.preferredCurrency, testCurrency);
        expect(data.languageCode, testLanguage);
        expect(data.socialProvider, isNull);
      });

      test('creates instance with optional socialProvider', () {
        const data = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
          socialProvider: testProvider,
        );

        expect(data.socialProvider, testProvider);
      });
    });

    group('toJson', () {
      test('converts to JSON without socialProvider', () {
        const data = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
        );

        final json = data.toJson();

        expect(json['display_name'], testDisplayName);
        expect(json['preferred_currency'], testCurrency);
        expect(json['language_code'], testLanguage);
        expect(json.containsKey('social_provider'), isFalse);
      });

      test('converts to JSON with socialProvider', () {
        const data = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
          socialProvider: testProvider,
        );

        final json = data.toJson();

        expect(json['display_name'], testDisplayName);
        expect(json['preferred_currency'], testCurrency);
        expect(json['language_code'], testLanguage);
        expect(json['social_provider'], 'google');
      });
    });

    group('fromJson', () {
      test('creates instance from JSON without socialProvider', () {
        final json = {
          'display_name': testDisplayName,
          'preferred_currency': testCurrency,
          'language_code': testLanguage,
        };

        final data = ProfileSetupData.fromJson(json);

        expect(data.displayName, testDisplayName);
        expect(data.preferredCurrency, testCurrency);
        expect(data.languageCode, testLanguage);
        expect(data.socialProvider, isNull);
      });

      test('creates instance from JSON with socialProvider', () {
        final json = {
          'display_name': testDisplayName,
          'preferred_currency': testCurrency,
          'language_code': testLanguage,
          'social_provider': 'google',
        };

        final data = ProfileSetupData.fromJson(json);

        expect(data.displayName, testDisplayName);
        expect(data.preferredCurrency, testCurrency);
        expect(data.languageCode, testLanguage);
        expect(data.socialProvider, SocialAuthProvider.google);
      });
    });

    group('copyWith', () {
      test('creates copy with updated displayName', () {
        const original = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
        );

        final copy = original.copyWith(displayName: 'Jane Doe');

        expect(copy.displayName, 'Jane Doe');
        expect(copy.preferredCurrency, testCurrency);
        expect(copy.languageCode, testLanguage);
      });

      test('creates copy with updated preferredCurrency', () {
        const original = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
        );

        final copy = original.copyWith(preferredCurrency: 'USD');

        expect(copy.displayName, testDisplayName);
        expect(copy.preferredCurrency, 'USD');
        expect(copy.languageCode, testLanguage);
      });

      test('creates copy with updated languageCode', () {
        const original = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
        );

        final copy = original.copyWith(languageCode: 'en');

        expect(copy.displayName, testDisplayName);
        expect(copy.preferredCurrency, testCurrency);
        expect(copy.languageCode, 'en');
      });

      test('creates copy with updated socialProvider', () {
        const original = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
        );

        final copy = original.copyWith(
          socialProvider: SocialAuthProvider.apple,
        );

        expect(copy.displayName, testDisplayName);
        expect(copy.socialProvider, SocialAuthProvider.apple);
      });
    });

    group('validateDisplayName', () {
      test('returns null for valid display name', () {
        expect(ProfileSetupData.validateDisplayName('John Doe'), isNull);
        expect(ProfileSetupData.validateDisplayName('AB'), isNull);
        expect(ProfileSetupData.validateDisplayName('A' * 50), isNull);
      });

      test('returns error for null display name', () {
        final error = ProfileSetupData.validateDisplayName(null);
        expect(error, 'Display name is required');
      });

      test('returns error for empty display name', () {
        final error = ProfileSetupData.validateDisplayName('');
        expect(error, 'Display name is required');
      });

      test('returns error for whitespace-only display name', () {
        final error = ProfileSetupData.validateDisplayName('   ');
        expect(error, 'Display name is required');
      });

      test('returns error for display name less than 2 characters', () {
        final error = ProfileSetupData.validateDisplayName('A');
        expect(error, 'Display name must be at least 2 characters');
      });

      test('returns error for display name more than 50 characters', () {
        final error = ProfileSetupData.validateDisplayName('A' * 51);
        expect(error, 'Display name must be less than 50 characters');
      });

      test('trims whitespace before validation', () {
        expect(ProfileSetupData.validateDisplayName('  John Doe  '), isNull);
        expect(
          ProfileSetupData.validateDisplayName('  A  '),
          'Display name must be at least 2 characters',
        );
      });
    });

    group('validateCurrency', () {
      test('returns null for valid currency', () {
        expect(ProfileSetupData.validateCurrency('VND'), isNull);
        expect(ProfileSetupData.validateCurrency('USD'), isNull);
        expect(ProfileSetupData.validateCurrency('EUR'), isNull);
      });

      test('returns error for null currency', () {
        final error = ProfileSetupData.validateCurrency(null);
        expect(error, 'Please select a currency');
      });

      test('returns error for empty currency', () {
        final error = ProfileSetupData.validateCurrency('');
        expect(error, 'Please select a currency');
      });
    });

    group('validateLanguage', () {
      test('returns null for valid language', () {
        expect(ProfileSetupData.validateLanguage('vi'), isNull);
        expect(ProfileSetupData.validateLanguage('en'), isNull);
        expect(ProfileSetupData.validateLanguage('es'), isNull);
      });

      test('returns error for null language', () {
        final error = ProfileSetupData.validateLanguage(null);
        expect(error, 'Please select a language');
      });

      test('returns error for empty language', () {
        final error = ProfileSetupData.validateLanguage('');
        expect(error, 'Please select a language');
      });
    });

    group('validate', () {
      test('returns empty map for valid data', () {
        const data = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
        );

        final errors = data.validate();

        expect(errors, isEmpty);
      });

      test('returns error for invalid display name', () {
        const data = ProfileSetupData(
          displayName: 'A',
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
        );

        final errors = data.validate();

        expect(errors['displayName'], isNotNull);
        expect(errors['preferredCurrency'], isNull);
        expect(errors['languageCode'], isNull);
      });

      test('returns error for invalid currency', () {
        const data = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: '',
          languageCode: testLanguage,
        );

        final errors = data.validate();

        expect(errors['displayName'], isNull);
        expect(errors['preferredCurrency'], isNotNull);
        expect(errors['languageCode'], isNull);
      });

      test('returns error for invalid language', () {
        const data = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: testCurrency,
          languageCode: '',
        );

        final errors = data.validate();

        expect(errors['displayName'], isNull);
        expect(errors['preferredCurrency'], isNull);
        expect(errors['languageCode'], isNotNull);
      });

      test('returns multiple errors for multiple invalid fields', () {
        const data = ProfileSetupData(
          displayName: '',
          preferredCurrency: '',
          languageCode: '',
        );

        final errors = data.validate();

        expect(errors['displayName'], isNotNull);
        expect(errors['preferredCurrency'], isNotNull);
        expect(errors['languageCode'], isNotNull);
        expect(errors.length, 3);
      });
    });

    group('isValid', () {
      test('returns true for valid data', () {
        const data = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
        );

        expect(data.isValid, isTrue);
      });

      test('returns false for invalid display name', () {
        const data = ProfileSetupData(
          displayName: 'A',
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
        );

        expect(data.isValid, isFalse);
      });

      test('returns false for invalid currency', () {
        const data = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: '',
          languageCode: testLanguage,
        );

        expect(data.isValid, isFalse);
      });

      test('returns false for invalid language', () {
        const data = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: testCurrency,
          languageCode: '',
        );

        expect(data.isValid, isFalse);
      });
    });

    group('equality', () {
      test('two instances with same values are equal', () {
        const data1 = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
          socialProvider: testProvider,
        );

        const data2 = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
          socialProvider: testProvider,
        );

        expect(data1, equals(data2));
      });

      test('two instances with different values are not equal', () {
        const data1 = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
        );

        const data2 = ProfileSetupData(
          displayName: 'Jane Doe',
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
        );

        expect(data1, isNot(equals(data2)));
      });
    });

    group('toString', () {
      test('returns string representation', () {
        const data = ProfileSetupData(
          displayName: testDisplayName,
          preferredCurrency: testCurrency,
          languageCode: testLanguage,
          socialProvider: testProvider,
        );

        final string = data.toString();

        expect(string, contains('ProfileSetupData'));
        expect(string, contains(testDisplayName));
        expect(string, contains(testCurrency));
        expect(string, contains(testLanguage));
        expect(string, contains('google'));
      });
    });
  });
}
