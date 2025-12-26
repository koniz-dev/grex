/// Represents a single password requirement with its validation status.
class PasswordRequirement {
  /// Creates a [PasswordRequirement].
  const PasswordRequirement({
    required this.label,
    required this.isMet,
  });

  /// The display label for this requirement.
  final String label;

  /// Whether this requirement is currently met.
  final bool isMet;
}

/// Input validation utilities for authentication forms.
///
/// This class provides static methods for validating user input
/// according to business rules and security requirements.
class InputValidators {
  // Private constructor to prevent instantiation
  InputValidators._();

  // Password validation regex patterns (single source of truth)
  static final _uppercaseRegex = RegExp('[A-Z]');
  static final _lowercaseRegex = RegExp('[a-z]');
  static final _numberRegex = RegExp('[0-9]');
  static final _specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
  static const _minPasswordLength = 8;
  static const _maxPasswordLength = 128;

  /// Returns a list of password requirements with their current
  /// validation status.
  ///
  /// Use this to display real-time feedback to users as they type
  /// their password.
  static List<PasswordRequirement> getPasswordRequirements(String password) {
    return [
      PasswordRequirement(
        label: 'Ít nhất $_minPasswordLength ký tự',
        isMet: password.length >= _minPasswordLength,
      ),
      PasswordRequirement(
        label: 'Có chữ hoa (A-Z)',
        isMet: _uppercaseRegex.hasMatch(password),
      ),
      PasswordRequirement(
        label: 'Có chữ thường (a-z)',
        isMet: _lowercaseRegex.hasMatch(password),
      ),
      PasswordRequirement(
        label: 'Có số (0-9)',
        isMet: _numberRegex.hasMatch(password),
      ),
      PasswordRequirement(
        label: r'Có ký tự đặc biệt (!@#$%^&*)',
        isMet: _specialCharRegex.hasMatch(password),
      ),
    ];
  }

  /// Checks if all password requirements are met.
  static bool areAllPasswordRequirementsMet(String password) {
    return getPasswordRequirements(password).every((req) => req.isMet);
  }

  /// Validates email format according to RFC 5322 specification.
  ///
  /// Returns null if email is valid, error message if invalid.
  ///
  /// Rules:
  /// - Must not be empty
  /// - Must contain @ symbol
  /// - Must have valid domain format
  /// - Must not exceed 254 characters (RFC limit)
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }

    final trimmedEmail = email.trim();

    if (trimmedEmail.length > 254) {
      return 'Email is too long';
    }

    // RFC 5322 compliant email regex (simplified but robust)
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(trimmedEmail)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates password strength according to security requirements.
  ///
  /// Returns null if password is valid, error message if invalid.
  ///
  /// Rules:
  /// - Minimum 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one number
  /// - At least one special character
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < _minPasswordLength) {
      return 'Password must be at least $_minPasswordLength characters long';
    }

    if (password.length > _maxPasswordLength) {
      return 'Password is too long (maximum $_maxPasswordLength characters)';
    }

    if (!_uppercaseRegex.hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!_lowercaseRegex.hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!_numberRegex.hasMatch(password)) {
      return 'Password must contain at least one number';
    }

    if (!_specialCharRegex.hasMatch(password)) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  /// Validates display name according to business rules.
  ///
  /// Returns null if display name is valid, error message if invalid.
  ///
  /// Rules:
  /// - Must not be empty or only whitespace
  /// - Maximum 50 characters
  /// - Must contain at least one non-whitespace character
  static String? validateDisplayName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) {
      return 'Display name is required';
    }

    final trimmedName = displayName.trim();

    if (trimmedName.length > 50) {
      return 'Display name must be 50 characters or less';
    }

    if (trimmedName.length < 2) {
      return 'Display name must be at least 2 characters long';
    }

    // Check for valid characters (letters, numbers, spaces, basic punctuation)
    if (!RegExp(r'^[a-zA-Z0-9\s\-_.]+$').hasMatch(trimmedName)) {
      return 'Display name contains invalid characters';
    }

    return null;
  }

  /// Validates currency code according to ISO 4217 standard.
  ///
  /// Returns null if currency code is valid, error message if invalid.
  ///
  /// Rules:
  /// - Must be exactly 3 characters
  /// - Must be uppercase letters only
  /// - Must be a supported currency
  static String? validateCurrencyCode(String? currencyCode) {
    if (currencyCode == null || currencyCode.trim().isEmpty) {
      return 'Currency code is required';
    }

    final trimmedCode = currencyCode.trim().toUpperCase();

    if (trimmedCode.length != 3) {
      return 'Currency code must be exactly 3 characters';
    }

    if (!RegExp(r'^[A-Z]{3}$').hasMatch(trimmedCode)) {
      return 'Currency code must contain only uppercase letters';
    }

    // List of supported currencies (can be expanded)
    const supportedCurrencies = {
      'VND', // Vietnamese Dong
      'USD', // US Dollar
      'EUR', // Euro
      'GBP', // British Pound
      'JPY', // Japanese Yen
      'KRW', // South Korean Won
      'CNY', // Chinese Yuan
      'THB', // Thai Baht
      'SGD', // Singapore Dollar
      'MYR', // Malaysian Ringgit
      'IDR', // Indonesian Rupiah
      'PHP', // Philippine Peso
    };

    if (!supportedCurrencies.contains(trimmedCode)) {
      return 'Currency code is not supported';
    }

    return null;
  }

  /// Validates language code according to ISO 639-1 standard.
  ///
  /// Returns null if language code is valid, error message if invalid.
  ///
  /// Rules:
  /// - Must be exactly 2 characters
  /// - Must be lowercase letters only
  /// - Must be a supported language
  static String? validateLanguageCode(String? languageCode) {
    if (languageCode == null || languageCode.trim().isEmpty) {
      return 'Language code is required';
    }

    final trimmedCode = languageCode.trim().toLowerCase();

    if (trimmedCode.length != 2) {
      return 'Language code must be exactly 2 characters';
    }

    if (!RegExp(r'^[a-z]{2}$').hasMatch(trimmedCode)) {
      return 'Language code must contain only lowercase letters';
    }

    // List of supported languages (can be expanded)
    const supportedLanguages = {
      'vi', // Vietnamese
      'en', // English
      'zh', // Chinese
      'ja', // Japanese
      'ko', // Korean
      'th', // Thai
      'id', // Indonesian
      'ms', // Malay
      'tl', // Filipino
    };

    if (!supportedLanguages.contains(trimmedCode)) {
      return 'Language code is not supported';
    }

    return null;
  }

  /// Validates password confirmation matches original password.
  ///
  /// Returns null if passwords match, error message if they don't.
  static String? validatePasswordConfirmation(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Password confirmation is required';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Checks if a string contains only whitespace or is empty.
  static bool isEmptyOrWhitespace(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Sanitizes input by trimming whitespace and removing null bytes.
  static String sanitizeInput(String? input) {
    if (input == null) return '';
    return input.trim().replaceAll('\x00', '');
  }
}
