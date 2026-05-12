import 'dart:ui';

/// Default currency and language codes for new profiles / groups /
/// registration forms.
///
/// Resolution order:
/// 1. The app-locale override set via [appLocale] — this is what
///    `main.dart` writes after reading the user's persisted locale from
///    `LocalizationService` (and what `LocaleNotifier` updates when the user
///    picks a language via the language switcher). Falls through if null.
/// 2. `PlatformDispatcher.instance.locale` — the device locale.
///
/// Language codes are clamped to the set we actually ship translations for
/// ({vi, en, es, ar}); anything else falls back to `en`. Currency is mapped
/// from the (clamped) language code, falling back to `USD`.
class LocaleDefaults {
  LocaleDefaults._();

  static const Set<String> _supportedLanguages = {'vi', 'en', 'es', 'ar'};
  static const String _defaultLanguage = 'en';
  static const String _defaultCurrency = 'USD';

  static const Map<String, String> _currencyByLanguage = {
    'vi': 'VND',
    'en': 'USD',
    'es': 'EUR',
    'ar': 'AED',
    'ja': 'JPY',
    'ko': 'KRW',
    'zh': 'CNY',
    'th': 'THB',
    'id': 'IDR',
    'ms': 'MYR',
    'tl': 'PHP',
    'fr': 'EUR',
    'de': 'EUR',
    'it': 'EUR',
    'pt': 'EUR',
    'ru': 'RUB',
    'hi': 'INR',
  };

  /// App-locale override set by the locale layer once the persisted
  /// preference is known. When `null`, defaults fall back to the device
  /// locale via `PlatformDispatcher.instance.locale`.
  static Locale? appLocale;

  /// Clear the override (intended for tests).
  static void resetAppLocale() {
    appLocale = null;
  }

  /// Raw language code from the override (if set) or the device locale.
  static String get _rawLanguageCode {
    final override = appLocale;
    if (override != null) return override.languageCode;
    return PlatformDispatcher.instance.locale.languageCode;
  }

  /// Default app language code, clamped to the set of languages the app
  /// actually ships translations for. Falls back to `en`.
  static String get languageCode {
    final code = _rawLanguageCode;
    return _supportedLanguages.contains(code) ? code : _defaultLanguage;
  }

  /// Default currency code derived from the resolved language. Falls back
  /// to `USD` for languages we don't have a mapping for.
  static String get currencyCode {
    return _currencyByLanguage[_rawLanguageCode] ?? _defaultCurrency;
  }
}
