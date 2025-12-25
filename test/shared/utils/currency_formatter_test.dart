import 'package:flutter_test/flutter_test.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    group('format', () {
      test('should format VND currency correctly', () {
        final result = CurrencyFormatter.format(
          amount: 150000,
          currencyCode: 'VND',
        );

        expect(result, contains('₫'));
        expect(result, contains('150'));
      });

      test('should format USD currency correctly', () {
        final result = CurrencyFormatter.format(
          amount: 150.50,
          currencyCode: 'USD',
        );

        expect(result, contains(r'$'));
        expect(result, contains('150.50'));
      });

      test('should handle zero amounts', () {
        final result = CurrencyFormatter.format(
          amount: 0,
          currencyCode: 'USD',
        );

        expect(result, contains('0'));
      });
    });

    group('formatAmount', () {
      test('should format amount without currency symbol', () {
        final result = CurrencyFormatter.formatAmount(
          amount: 150.50,
          currencyCode: 'USD',
        );

        expect(result, isNot(contains(r'$')));
        expect(result, contains('150.50'));
      });

      test('should respect currency decimal rules', () {
        final vndResult = CurrencyFormatter.formatAmount(
          amount: 150000,
          currencyCode: 'VND',
        );

        final usdResult = CurrencyFormatter.formatAmount(
          amount: 150.50,
          currencyCode: 'USD',
        );

        // VND should not have decimal places, USD should have them
        expect(vndResult, isNot(contains('.50')));
        expect(usdResult, contains('.50'));
      });
    });

    group('formatCompact', () {
      test('should format large amounts compactly', () {
        final result = CurrencyFormatter.formatCompact(
          amount: 1500000,
          currencyCode: 'USD',
        );

        expect(result, anyOf(contains('M'), contains('K')));
      });
    });

    group('formatBalance', () {
      test('should show positive balance with + sign', () {
        final result = CurrencyFormatter.formatBalance(
          amount: 150,
          currencyCode: 'USD',
        );

        expect(result, startsWith('+'));
      });

      test('should show negative balance with - sign', () {
        final result = CurrencyFormatter.formatBalance(
          amount: -150,
          currencyCode: 'USD',
        );

        expect(result, startsWith('-'));
      });

      test('should not show sign when showSign is false', () {
        final positiveResult = CurrencyFormatter.formatBalance(
          amount: 150,
          currencyCode: 'USD',
          showSign: false,
        );

        final negativeResult = CurrencyFormatter.formatBalance(
          amount: -150,
          currencyCode: 'USD',
          showSign: false,
        );

        expect(positiveResult, isNot(startsWith('+')));
        expect(negativeResult, isNot(startsWith('-')));
      });
    });

    group('parseAmount', () {
      test('should parse formatted currency back to amount', () {
        const originalAmount = 150.50;
        final formatted = CurrencyFormatter.format(
          amount: originalAmount,
          currencyCode: 'USD',
        );

        final parsed = CurrencyFormatter.parseAmount(
          formattedAmount: formatted,
          currencyCode: 'USD',
        );

        expect(parsed, isNotNull);
        expect(parsed, closeTo(originalAmount, 0.01));
      });

      test('should handle invalid input gracefully', () {
        final parsed = CurrencyFormatter.parseAmount(
          formattedAmount: 'invalid',
          currencyCode: 'USD',
        );

        expect(parsed, isNull);
      });
    });

    group('currency validation', () {
      test('should validate supported currencies', () {
        expect(CurrencyFormatter.isValidCurrencyCode('USD'), isTrue);
        expect(CurrencyFormatter.isValidCurrencyCode('VND'), isTrue);
        expect(CurrencyFormatter.isValidCurrencyCode('EUR'), isTrue);
        expect(CurrencyFormatter.isValidCurrencyCode('INVALID'), isFalse);
      });

      test('should be case insensitive', () {
        expect(CurrencyFormatter.isValidCurrencyCode('usd'), isTrue);
        expect(CurrencyFormatter.isValidCurrencyCode('Vnd'), isTrue);
      });
    });

    group('currency compatibility', () {
      test('should detect compatible currencies', () {
        expect(
          CurrencyFormatter.areCurrenciesCompatible('USD', 'USD'),
          isTrue,
        );
        expect(
          CurrencyFormatter.areCurrenciesCompatible('USD', 'VND'),
          isFalse,
        );
      });

      test('should be case insensitive for compatibility', () {
        expect(
          CurrencyFormatter.areCurrenciesCompatible('USD', 'usd'),
          isTrue,
        );
        expect(
          CurrencyFormatter.areCurrenciesCompatible('VND', 'vnd'),
          isTrue,
        );
      });
    });

    group('currency properties', () {
      test('should return correct decimal digits', () {
        expect(CurrencyFormatter.getCurrencyPrecision('USD'), equals(2));
        expect(CurrencyFormatter.getCurrencyPrecision('VND'), equals(0));
        expect(CurrencyFormatter.getCurrencyPrecision('JPY'), equals(0));
      });

      test('should identify currencies that use decimals', () {
        expect(CurrencyFormatter.currencyUsesDecimals('USD'), isTrue);
        expect(CurrencyFormatter.currencyUsesDecimals('VND'), isFalse);
        expect(CurrencyFormatter.currencyUsesDecimals('JPY'), isFalse);
      });
    });

    group('amount validation', () {
      test('should validate amount strings', () {
        expect(CurrencyFormatter.isValidAmount('150.50', 'USD'), isTrue);
        expect(CurrencyFormatter.isValidAmount('150000', 'VND'), isTrue);
        expect(CurrencyFormatter.isValidAmount('', 'USD'), isFalse);
        expect(CurrencyFormatter.isValidAmount('invalid', 'USD'), isFalse);
        expect(CurrencyFormatter.isValidAmount('-50', 'USD'), isFalse);
      });
    });

    group('rounding', () {
      test('should round to currency precision', () {
        final usdRounded = CurrencyFormatter.roundToCurrencyPrecision(
          150.555,
          'USD',
        );
        final vndRounded = CurrencyFormatter.roundToCurrencyPrecision(
          150000.7,
          'VND',
        );

        expect(usdRounded, equals(150.56));
        expect(vndRounded, equals(150001.0));
      });
    });

    group('display names', () {
      test('should return correct display names', () {
        expect(
          CurrencyFormatter.getCurrencyDisplayName('USD'),
          equals('US Dollar'),
        );
        expect(
          CurrencyFormatter.getCurrencyDisplayName('VND'),
          equals('Vietnamese Dong'),
        );
        expect(
          CurrencyFormatter.getCurrencyDisplayName('UNKNOWN'),
          equals('UNKNOWN'),
        );
      });
    });

    group('supported currencies', () {
      test('should return list of supported currencies', () {
        final currencies = CurrencyFormatter.getSupportedCurrencies();

        expect(currencies, isNotEmpty);
        expect(currencies, contains('USD'));
        expect(currencies, contains('VND'));
        expect(currencies, contains('EUR'));
      });
    });

    group('input formatting', () {
      test('should format for input fields', () {
        final usdInput = CurrencyFormatter.formatForInput(
          amount: 150.50,
          currencyCode: 'USD',
        );

        final vndInput = CurrencyFormatter.formatForInput(
          amount: 150000,
          currencyCode: 'VND',
        );

        expect(usdInput, equals('150.50'));
        expect(vndInput, equals('150000'));
      });
    });

    group('warning messages', () {
      test('should generate currency mismatch warnings', () {
        final warning = CurrencyFormatter.getCurrencyMismatchWarning(
          'USD',
          'VND',
        );

        expect(warning, contains('USD'));
        expect(warning, contains('VND'));
        expect(warning, contains('mismatch'));
      });
    });
  });
}
