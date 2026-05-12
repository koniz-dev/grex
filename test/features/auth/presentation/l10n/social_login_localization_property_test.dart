import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/l10n/app_localizations.dart';

/// Property 34: Social Login UI Localized Correctly
///
/// This property test validates that all social login strings exist in each
/// supported locale and that placeholder replacement works correctly.
///
/// **Validates Requirements:**
/// - 11.1: English localization strings
/// - 11.2: Social login button text
/// - 11.3: Profile setup screen text
/// - 11.4: Account linking dialog text
/// - 11.5: Error message text
/// - 11.6: Multi-language support
void main() {
  group('Property 34: Social Login UI Localized Correctly', () {
    // All supported locales
    final supportedLocales = [
      const Locale('en'),
      const Locale('vi'),
      const Locale('es'),
      const Locale('ar'),
    ];

    // Social login strings that must exist in all locales
    final socialLoginStrings = [
      'continueWithGoogle',
      'continueWithApple',
      'or',
      'completeYourProfile',
      'profileSetupDescription',
      'linkYourAccount',
      'linkAccounts',
      'createNewAccount',
      'socialAuthFailed',
      'socialAuthNetworkError',
      'socialAuthTimeout',
      'accountLinkingError',
      'cancelProfileSetup',
      'cancelProfileSetupMessage',
      'continueSetup',
      'signInWithEmail',
      'linkAccountBenefit',
    ];

    // Parameterized strings that need placeholder testing
    final parameterizedStrings = {
      'accountExistsMessage': ['email'],
      'linkAccountQuestion': ['provider'],
    };

    test('should have all social login strings in all supported locales', () async {
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final locale in supportedLocales) {
          // Create localization for this locale
          final localizations = await AppLocalizations.delegate.load(locale);

          // Test all basic social login strings
          for (final stringKey in socialLoginStrings) {
            final value = _getStringValue(localizations, stringKey);

            expect(
              value,
              isNotNull,
              reason:
                  'String "$stringKey" should exist in locale '
                  '${locale.languageCode}',
            );

            expect(
              value!.trim(),
              isNotEmpty,
              reason:
                  'String "$stringKey" should not be empty in locale '
                  '${locale.languageCode}',
            );
          }

          // Test parameterized strings
          for (final entry in parameterizedStrings.entries) {
            final stringKey = entry.key;
            final parameters = entry.value;

            final value = _getParameterizedStringValue(
              localizations,
              stringKey,
              parameters,
            );

            expect(
              value,
              isNotNull,
              reason:
                  'Parameterized string "$stringKey" should exist in locale ${locale.languageCode}',
            );

            expect(
              value!.trim(),
              isNotEmpty,
              reason:
                  'Parameterized string "$stringKey" should not be empty in locale ${locale.languageCode}',
            );

            // Verify placeholder replacement worked
            for (final param in parameters) {
              expect(
                value.contains('{$param}'),
                isFalse,
                reason:
                    'Placeholder {$param} should be replaced in "$stringKey" for locale ${locale.languageCode}',
              );
            }
          }
        }
      }
    });

    test('should have culturally appropriate translations', () async {
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final locale in supportedLocales) {
          final localizations = await AppLocalizations.delegate.load(locale);

          // Test that translations are not just English
          if (locale.languageCode != 'en') {
            final englishLocalizations = await AppLocalizations.delegate.load(
              const Locale('en'),
            );

            // Check a few key strings to ensure they're actually translated
            final keyStringsToCheck = [
              'continueWithGoogle',
              'continueWithApple',
              'completeYourProfile',
              'linkYourAccount',
            ];

            for (final stringKey in keyStringsToCheck) {
              final localizedValue = _getStringValue(localizations, stringKey);
              final englishValue = _getStringValue(
                englishLocalizations,
                stringKey,
              );

              // For non-English locales, the translation should be different from English
              // (except for proper nouns like "Google" and "Apple")
              if (!stringKey.contains('Google') &&
                  !stringKey.contains('Apple')) {
                expect(
                  localizedValue,
                  isNot(equals(englishValue)),
                  reason:
                      'String "$stringKey" should be translated in locale ${locale.languageCode}',
                );
              }
            }
          }
        }
      }
    });

    test('should handle placeholder replacement correctly', () async {
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final locale in supportedLocales) {
          final localizations = await AppLocalizations.delegate.load(locale);

          // Test accountExistsMessage with email placeholder
          final testEmail = 'test$iteration@example.com';
          final accountMessage = _getParameterizedStringValue(
            localizations,
            'accountExistsMessage',
            ['email'],
            {'email': testEmail},
          );

          expect(accountMessage, contains(testEmail));
          expect(accountMessage, isNot(contains('{email}')));

          // Test linkAccountQuestion with provider placeholder
          final testProvider = iteration.isEven ? 'Google' : 'Apple';
          final linkMessage = _getParameterizedStringValue(
            localizations,
            'linkAccountQuestion',
            ['provider'],
            {'provider': testProvider},
          );

          expect(linkMessage, contains(testProvider));
          expect(linkMessage, isNot(contains('{provider}')));
        }
      }
    });

    test('should maintain consistent string lengths across locales', () async {
      for (var iteration = 0; iteration < 100; iteration++) {
        final stringLengths = <String, Map<String, int>>{};

        // Collect string lengths for each locale
        for (final locale in supportedLocales) {
          final localizations = await AppLocalizations.delegate.load(locale);

          for (final stringKey in socialLoginStrings) {
            final value = _getStringValue(localizations, stringKey);
            if (value != null) {
              stringLengths.putIfAbsent(stringKey, () => {});
              stringLengths[stringKey]![locale.languageCode] = value.length;
            }
          }
        }

        // Check that no translation is excessively longer than others
        // (which might indicate UI layout issues). Skip very short strings
        // (1-2 chars) since short particles like "or" / "หรือ" naturally
        // exceed a 3x ratio with no UI impact.
        for (final entry in stringLengths.entries) {
          final lengths = entry.value.values.toList();
          if (lengths.isNotEmpty) {
            final minLength = lengths.reduce((a, b) => a < b ? a : b);
            final maxLength = lengths.reduce((a, b) => a > b ? a : b);

            if (minLength < 3) continue;

            // Allow up to 3x length difference (reasonable for different languages)
            expect(
              maxLength <= minLength * 3,
              isTrue,
              reason:
                  'String "${entry.key}" has excessive length variation across locales: min=$minLength, max=$maxLength',
            );
          }
        }
      }
    });
  });
}

/// Helper function to get string value using reflection-like approach
String? _getStringValue(AppLocalizations localizations, String key) {
  try {
    switch (key) {
      case 'continueWithGoogle':
        return localizations.continueWithGoogle;
      case 'continueWithApple':
        return localizations.continueWithApple;
      case 'or':
        return localizations.or;
      case 'completeYourProfile':
        return localizations.completeYourProfile;
      case 'profileSetupDescription':
        return localizations.profileSetupDescription;
      case 'linkYourAccount':
        return localizations.linkYourAccount;
      case 'linkAccounts':
        return localizations.linkAccounts;
      case 'createNewAccount':
        return localizations.createNewAccount;
      case 'socialAuthFailed':
        return localizations.socialAuthFailed;
      case 'socialAuthNetworkError':
        return localizations.socialAuthNetworkError;
      case 'socialAuthTimeout':
        return localizations.socialAuthTimeout;
      case 'accountLinkingError':
        return localizations.accountLinkingError;
      case 'cancelProfileSetup':
        return localizations.cancelProfileSetup;
      case 'cancelProfileSetupMessage':
        return localizations.cancelProfileSetupMessage;
      case 'continueSetup':
        return localizations.continueSetup;
      case 'signInWithEmail':
        return localizations.signInWithEmail;
      case 'linkAccountBenefit':
        return localizations.linkAccountBenefit;
      default:
        return null;
    }
  } on Exception catch (_) {
    return null;
  }
}

/// Helper function to get parameterized string value
String? _getParameterizedStringValue(
  AppLocalizations localizations,
  String key,
  List<String> parameterNames, [
  Map<String, String>? parameterValues,
]) {
  try {
    switch (key) {
      case 'accountExistsMessage':
        final email = parameterValues?['email'] ?? 'test@example.com';
        return localizations.accountExistsMessage(email);
      case 'linkAccountQuestion':
        final provider = parameterValues?['provider'] ?? 'Google';
        return localizations.linkAccountQuestion(provider);
      default:
        return null;
    }
  } on Exception catch (_) {
    return null;
  }
}
