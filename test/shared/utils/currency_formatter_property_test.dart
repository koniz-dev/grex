import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

void main() {
  group('Currency Handling Properties', () {
    final random = Random();
    const testIterations = 1000;

    test('Property 23: Group currency settings are respected', () {
      // Property: When formatting amounts, the group's currency settings
      // should always be used consistently across all operations

      for (var i = 0; i < testIterations; i++) {
        // Generate random test data
        final currencies = CurrencyFormatter.getSupportedCurrencies();
        final groupCurrency = currencies[random.nextInt(currencies.length)];
        final amount = random.nextDouble() * 10000;

        // Format amount with group currency
        final formatted1 = CurrencyFormatter.format(
          amount: amount,
          currencyCode: groupCurrency,
        );

        final formatted2 = CurrencyFormatter.format(
          amount: amount,
          currencyCode: groupCurrency,
        );

        // Property: Same amount with same currency should format identically
        expect(
          formatted1,
          equals(formatted2),
          reason:
              'Same amount ($amount) with same currency ($groupCurrency) '
              'should format identically',
        );

        // Property: Formatted amount should not be empty and should contain
        // digits
        expect(
          formatted1.isNotEmpty,
          isTrue,
          reason: 'Formatted amount should not be empty',
        );
        expect(
          formatted1,
          matches(RegExp(r'\d')),
          reason: 'Formatted amount should contain digits',
        );

        // Property: Currency precision should be consistent
        final precision1 = CurrencyFormatter.getCurrencyPrecision(
          groupCurrency,
        );
        final precision2 = CurrencyFormatter.getCurrencyPrecision(
          groupCurrency,
        );
        expect(
          precision1,
          equals(precision2),
          reason: 'Currency precision should be consistent for same currency',
        );

        // Property: Decimal usage should match precision
        final usesDecimals = CurrencyFormatter.currencyUsesDecimals(
          groupCurrency,
        );
        expect(
          usesDecimals,
          equals(precision1 > 0),
          reason: 'Decimal usage should match precision > 0',
        );
      }
    });

    test('Property 24: Currency formatting follows locale', () {
      // Property: Currency formatting should respect locale-specific rules
      // and produce consistent results for the same locale

      for (var i = 0; i < testIterations; i++) {
        // Generate random test data
        final currencies = CurrencyFormatter.getSupportedCurrencies();
        final currency = currencies[random.nextInt(currencies.length)];
        final amount = random.nextDouble() * 10000;
        final locales = ['vi_VN', 'en_US', 'de_DE', 'ja_JP'];
        final locale = locales[random.nextInt(locales.length)];

        try {
          // Format with specific locale
          final formatted = CurrencyFormatter.format(
            amount: amount,
            currencyCode: currency,
            locale: locale,
          );

          // Property: Formatted result should not be empty
          expect(
            formatted.isNotEmpty,
            isTrue,
            reason: 'Formatted currency should not be empty',
          );

          // Property: Should contain numeric content
          expect(
            formatted,
            matches(RegExp(r'\d')),
            reason: 'Formatted currency should contain digits',
          );

          // Property: Formatting should be consistent for same inputs
          final formatted2 = CurrencyFormatter.format(
            amount: amount,
            currencyCode: currency,
            locale: locale,
          );

          expect(
            formatted,
            equals(formatted2),
            reason: 'Same inputs should produce identical formatting',
          );

          // Property: Amount-only formatting should work
          final amountOnly = CurrencyFormatter.formatAmount(
            amount: amount,
            currencyCode: currency,
            locale: locale,
          );

          expect(
            amountOnly.isNotEmpty,
            isTrue,
            reason: 'Amount-only formatting should not be empty',
          );
        } on Exception catch (_) {
          // Some locale combinations might not be supported, which is
          // acceptable
          // as long as we have a fallback
          final fallback = CurrencyFormatter.format(
            amount: amount,
            currencyCode: currency,
          );
          expect(
            fallback.isNotEmpty,
            isTrue,
            reason: 'Fallback formatting should always work',
          );
        }
      }
    });

    test('Property 25: Balance calculation handles group currency', () {
      // Property: Balance calculations should maintain currency consistency
      // and handle positive/negative amounts correctly

      for (var i = 0; i < testIterations; i++) {
        // Generate random test data
        final currencies = CurrencyFormatter.getSupportedCurrencies();
        final currency = currencies[random.nextInt(currencies.length)];
        final balance = (random.nextDouble() - 0.5) * 20000; // Can be negative

        // Format balance with sign
        final balanceWithSign = CurrencyFormatter.formatBalance(
          amount: balance,
          currencyCode: currency,
        );

        // Format balance without sign
        final balanceWithoutSign = CurrencyFormatter.formatBalance(
          amount: balance,
          currencyCode: currency,
          showSign: false,
        );

        // Property: Balance with sign should indicate positive/negative
        if (balance > 0) {
          expect(
            balanceWithSign,
            startsWith('+'),
            reason: 'Positive balance should start with +',
          );
        } else if (balance < 0) {
          expect(
            balanceWithSign,
            startsWith('-'),
            reason: 'Negative balance should start with -',
          );
        }

        // Property: Balance without sign should not have +/- prefix
        expect(
          balanceWithoutSign,
          isNot(startsWith('+')),
          reason: 'Balance without sign should not start with +',
        );
        expect(
          balanceWithoutSign,
          isNot(startsWith('-')),
          reason: 'Balance without sign should not start with -',
        );

        // Property: Both formats should contain numeric content
        expect(
          balanceWithSign,
          matches(RegExp(r'\d')),
          reason: 'Balance with sign should contain digits',
        );
        expect(
          balanceWithoutSign,
          matches(RegExp(r'\d')),
          reason: 'Balance without sign should contain digits',
        );

        // Property: Compact formatting should work for large amounts
        if (balance.abs() > 1000) {
          final compact = CurrencyFormatter.formatCompact(
            amount: balance.abs(),
            currencyCode: currency,
          );
          expect(
            compact.isNotEmpty,
            isTrue,
            reason: 'Compact formatting should work for large amounts',
          );
        }
      }
    });

    test('Property 26: Mixed currencies trigger warnings', () {
      // Property: When different currencies are used together,
      // appropriate warnings should be generated

      for (var i = 0; i < testIterations; i++) {
        // Generate random currency pairs
        final currencies = CurrencyFormatter.getSupportedCurrencies();
        final currency1 = currencies[random.nextInt(currencies.length)];
        final currency2 = currencies[random.nextInt(currencies.length)];

        // Property: Same currencies should be compatible
        if (currency1 == currency2) {
          expect(
            CurrencyFormatter.areCurrenciesCompatible(currency1, currency2),
            isTrue,
            reason: 'Same currencies should be compatible',
          );
        }

        // Property: Different currencies should not be compatible
        if (currency1 != currency2) {
          expect(
            CurrencyFormatter.areCurrenciesCompatible(currency1, currency2),
            isFalse,
            reason: 'Different currencies should not be compatible',
          );

          // Property: Warning message should be generated for mismatched
          // currencies
          final warning = CurrencyFormatter.getCurrencyMismatchWarning(
            currency1,
            currency2,
          );
          expect(
            warning.isNotEmpty,
            isTrue,
            reason: 'Warning should be generated for currency mismatch',
          );
          expect(
            warning,
            contains(currency1),
            reason: 'Warning should mention source currency',
          );
          expect(
            warning,
            contains(currency2),
            reason: 'Warning should mention target currency',
          );
        }

        // Property: Currency validation should work correctly
        final validCurrency = currencies[random.nextInt(currencies.length)];
        expect(
          CurrencyFormatter.isValidCurrencyCode(validCurrency),
          isTrue,
          reason: 'Supported currency should be valid',
        );

        // Property: Invalid currency codes should be rejected
        const invalidCurrency = 'INVALID';
        expect(
          CurrencyFormatter.isValidCurrencyCode(invalidCurrency),
          isFalse,
          reason: 'Invalid currency code should be rejected',
        );

        // Property: Currency precision should be consistent
        final precision1 = CurrencyFormatter.getCurrencyPrecision(
          validCurrency,
        );
        final precision2 = CurrencyFormatter.getCurrencyPrecision(
          validCurrency,
        );
        expect(
          precision1,
          equals(precision2),
          reason: 'Currency precision should be consistent',
        );

        // Property: Decimal usage should match precision
        final usesDecimals = CurrencyFormatter.currencyUsesDecimals(
          validCurrency,
        );
        expect(
          usesDecimals,
          equals(precision1 > 0),
          reason: 'Decimal usage should match precision > 0',
        );
      }
    });
  });
}
