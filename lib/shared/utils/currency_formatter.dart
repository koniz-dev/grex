import 'dart:math';
import 'package:intl/intl.dart';

/// Utility class for formatting currency amounts according to locale and
/// currency
class CurrencyFormatter {
  /// Default locale for Vietnamese users
  static const String defaultLocale = 'vi_VN';

  /// Format amount with currency symbol and locale-specific formatting
  static String format({
    required double amount,
    required String currencyCode,
    String? locale,
  }) {
    try {
      final formatter = NumberFormat.currency(
        locale: locale ?? _getDefaultLocaleForCurrency(currencyCode),
        symbol: _getCurrencySymbol(currencyCode),
        decimalDigits: _getDecimalDigits(currencyCode),
      );

      return formatter.format(amount);
    } on Exception catch (_) {
      // Fallback to simple formatting if locale is not supported
      return _formatFallback(amount, currencyCode);
    }
  }

  /// Format amount without currency symbol
  static String formatAmount({
    required double amount,
    required String currencyCode,
    String? locale,
  }) {
    try {
      final formatter = NumberFormat.currency(
        locale: locale ?? _getDefaultLocaleForCurrency(currencyCode),
        symbol: '',
        decimalDigits: _getDecimalDigits(currencyCode),
      );

      return formatter.format(amount).trim();
    } on Exception catch (_) {
      // Fallback to simple formatting
      final decimalDigits = _getDecimalDigits(currencyCode);
      return amount.toStringAsFixed(decimalDigits);
    }
  }

  /// Format amount with compact notation (e.g., 1.2K, 1.5M)
  static String formatCompact({
    required double amount,
    required String currencyCode,
    String? locale,
  }) {
    try {
      final formatter = NumberFormat.compactCurrency(
        locale: locale ?? _getDefaultLocaleForCurrency(currencyCode),
        symbol: _getCurrencySymbol(currencyCode),
        decimalDigits: _getDecimalDigits(currencyCode),
      );

      return formatter.format(amount);
    } on Exception catch (_) {
      // Fallback to regular formatting
      return format(amount: amount, currencyCode: currencyCode, locale: locale);
    }
  }

  /// Format balance amount with positive/negative indicators
  static String formatBalance({
    required double amount,
    required String currencyCode,
    String? locale,
    bool showSign = true,
  }) {
    final formattedAmount = format(
      amount: amount.abs(),
      currencyCode: currencyCode,
      locale: locale,
    );

    if (!showSign || amount == 0) {
      return formattedAmount;
    }

    if (amount > 0) {
      return '+$formattedAmount';
    } else {
      return '-$formattedAmount';
    }
  }

  /// Parse currency string back to double amount
  static double? parseAmount({
    required String formattedAmount,
    required String currencyCode,
    String? locale,
  }) {
    try {
      final formatter = NumberFormat.currency(
        locale: locale ?? _getDefaultLocaleForCurrency(currencyCode),
        symbol: _getCurrencySymbol(currencyCode),
        decimalDigits: _getDecimalDigits(currencyCode),
      );

      return formatter.parse(formattedAmount).toDouble();
    } on Exception catch (_) {
      // Try to parse as simple number
      final cleanedAmount = formattedAmount
          .replaceAll(RegExp(r'[^\d.,\-+]'), '')
          .replaceAll(',', '.');
      return double.tryParse(cleanedAmount);
    }
  }

  /// Get currency symbol for a given currency code (public method)
  static String getCurrencySymbol(String currencyCode) {
    return _getCurrencySymbol(currencyCode);
  }

  /// Get currency symbol for a given currency code
  static String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'VND':
        return '₫';
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      case 'KRW':
        return '₩';
      case 'THB':
        return '฿';
      case 'SGD':
        return r'S$';
      case 'MYR':
        return 'RM';
      default:
        return currencyCode;
    }
  }

  /// Get decimal digits for a given currency code
  static int _getDecimalDigits(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'VND':
      case 'JPY':
      case 'KRW':
        return 0; // These currencies don't use decimal places
      default:
        return 2; // Most currencies use 2 decimal places
    }
  }

  /// Validate currency code
  static bool isValidCurrencyCode(String currencyCode) {
    const validCurrencies = {
      'VND',
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'CNY',
      'KRW',
      'THB',
      'SGD',
      'MYR',
    };
    return validCurrencies.contains(currencyCode.toUpperCase());
  }

  /// Get list of supported currencies
  static List<String> getSupportedCurrencies() {
    return [
      'VND',
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'CNY',
      'KRW',
      'THB',
      'SGD',
      'MYR',
    ];
  }

  /// Get currency display name
  static String getCurrencyDisplayName(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'VND':
        return 'Vietnamese Dong';
      case 'USD':
        return 'US Dollar';
      case 'EUR':
        return 'Euro';
      case 'GBP':
        return 'British Pound';
      case 'JPY':
        return 'Japanese Yen';
      case 'CNY':
        return 'Chinese Yuan';
      case 'KRW':
        return 'South Korean Won';
      case 'THB':
        return 'Thai Baht';
      case 'SGD':
        return 'Singapore Dollar';
      case 'MYR':
        return 'Malaysian Ringgit';
      default:
        return currencyCode;
    }
  }

  /// Get default locale for a currency
  static String _getDefaultLocaleForCurrency(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'VND':
        return 'vi_VN';
      case 'USD':
        return 'en_US';
      case 'EUR':
        return 'de_DE';
      case 'GBP':
        return 'en_GB';
      case 'JPY':
        return 'ja_JP';
      case 'CNY':
        return 'zh_CN';
      case 'KRW':
        return 'ko_KR';
      case 'THB':
        return 'th_TH';
      case 'SGD':
        return 'en_SG';
      case 'MYR':
        return 'ms_MY';
      default:
        return defaultLocale;
    }
  }

  /// Fallback formatting when locale is not supported
  static String _formatFallback(double amount, String currencyCode) {
    final decimalDigits = _getDecimalDigits(currencyCode);
    final symbol = _getCurrencySymbol(currencyCode);
    final formattedAmount = amount.toStringAsFixed(decimalDigits);

    // Add thousand separators
    final parts = formattedAmount.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    final formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );

    final result = decimalDigits > 0 && decimalPart.isNotEmpty
        ? '$formattedInteger.$decimalPart'
        : formattedInteger;

    return '$symbol$result';
  }

  /// Check if two currencies are compatible for operations
  static bool areCurrenciesCompatible(String currency1, String currency2) {
    return currency1.toUpperCase() == currency2.toUpperCase();
  }

  /// Get currency conversion warning message
  static String getCurrencyMismatchWarning(
    String fromCurrency,
    String toCurrency,
  ) {
    return 'Currency mismatch: $fromCurrency → $toCurrency. '
        'Consider converting amounts or using a single currency for the group.';
  }

  /// Validate currency amount format
  static bool isValidAmount(String amountText, String currencyCode) {
    if (amountText.trim().isEmpty) return false;

    final parsed = parseAmount(
      formattedAmount: amountText,
      currencyCode: currencyCode,
    );

    return parsed != null && parsed >= 0;
  }

  /// Format currency for input fields (without symbols for easier editing)
  static String formatForInput({
    required double amount,
    required String currencyCode,
  }) {
    final decimalDigits = _getDecimalDigits(currencyCode);
    return amount.toStringAsFixed(decimalDigits);
  }

  /// Get currency precision (number of decimal places)
  static int getCurrencyPrecision(String currencyCode) {
    return _getDecimalDigits(currencyCode);
  }

  /// Check if currency uses decimal places
  static bool currencyUsesDecimals(String currencyCode) {
    return _getDecimalDigits(currencyCode) > 0;
  }

  /// Round amount according to currency precision
  static double roundToCurrencyPrecision(double amount, String currencyCode) {
    final precision = _getDecimalDigits(currencyCode);
    final multiplier = pow(10, precision);
    return (amount * multiplier).round() / multiplier;
  }
}
