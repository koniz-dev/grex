import 'package:grex/features/auth/domain/entities/entities.dart';

/// Generate valid user for property testing
User generateValidUser() {
  final now = DateTime.now();
  final userIds = [
    'user-id-1-${now.millisecond}',
    'user-id-2-${now.millisecond}',
    'user-id-3-${now.millisecond}',
  ];

  final emails = [
    'user1@test.com',
    'user2@example.org',
    'test.user@domain.co',
    'valid.email@company.net',
  ];

  return User(
    id: userIds[now.millisecond % userIds.length],
    email: emails[now.microsecond % emails.length],
    createdAt: now.subtract(Duration(days: now.day % 30 + 1)),
    lastSignInAt: now.subtract(Duration(hours: now.hour % 24)),
  );
}

/// Generate valid user profile for property testing
UserProfile generateValidUserProfile() {
  final now = DateTime.now();
  final displayNames = [
    'Test User One',
    'Example User Two',
    'Sample User Three',
    'Demo User Four',
  ];

  final currencies = ['VND', 'USD', 'EUR', 'GBP', 'JPY'];
  final languages = ['vi', 'en', 'zh', 'ja', 'ko'];

  final user = generateValidUser();

  return UserProfile(
    id: user.id,
    email: user.email,
    displayName: displayNames[now.millisecond % displayNames.length],
    preferredCurrency: currencies[now.microsecond % currencies.length],
    languageCode: languages[now.second % languages.length],
    createdAt: user.createdAt,
    updatedAt: now,
  );
}

/// Generate random boolean for property testing
bool generateRandomBool() {
  return DateTime.now().millisecond.isEven;
}

/// Generate random positive integer for property testing
int generateRandomPositiveInt({int max = 1000}) {
  return (DateTime.now().millisecond % max) + 1;
}

/// Generate random string for property testing
String generateRandomString({int length = 10}) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final now = DateTime.now();
  final buffer = StringBuffer();

  for (var i = 0; i < length; i++) {
    final index = (now.millisecond + now.microsecond + i) % chars.length;
    buffer.write(chars[index]);
  }

  return buffer.toString();
}

/// Generate valid email for property testing
String generateValidEmail() {
  final domains = ['test.com', 'example.org', 'domain.co', 'company.net'];
  final usernames = ['user1', 'test.user', 'sample', 'demo.user'];

  final now = DateTime.now();
  final username = usernames[now.millisecond % usernames.length];
  final domain = domains[now.microsecond % domains.length];

  return '$username@$domain';
}

/// Generate valid password for property testing
String generateValidPassword() {
  final passwords = [
    'SecurePass123!',
    'MyPassword456@',
    'TestPass789#',
    r'ValidPass012$',
    'StrongPwd345%',
  ];

  return passwords[DateTime.now().millisecond % passwords.length];
}

/// Generate valid display name for property testing
String generateValidDisplayName() {
  final names = [
    'John Doe',
    'Jane Smith',
    'Test User',
    'Sample Person',
    'Demo Account',
  ];

  return names[DateTime.now().millisecond % names.length];
}

/// Generate valid currency code for property testing
String generateValidCurrency() {
  final currencies = ['VND', 'USD', 'EUR', 'GBP', 'JPY', 'KRW', 'CNY'];
  return currencies[DateTime.now().millisecond % currencies.length];
}

/// Generate valid language code for property testing
String generateValidLanguageCode() {
  final languages = ['vi', 'en', 'zh', 'ja', 'ko', 'th', 'id'];
  return languages[DateTime.now().millisecond % languages.length];
}

/// Helper class for property test data generation
class PropertyTestHelpers {
  /// Generate random user ID for testing
  static String generateUserId() {
    final now = DateTime.now();
    return 'user-${now.millisecondsSinceEpoch}-${now.microsecond}';
  }

  /// Generate random email for testing
  static String generateEmail() {
    final domains = ['test.com', 'example.org', 'domain.co', 'company.net'];
    final usernames = ['user', 'test', 'sample', 'demo'];

    final now = DateTime.now();
    final username = usernames[now.millisecond % usernames.length];
    final domain = domains[now.microsecond % domains.length];
    final timestamp = now.millisecondsSinceEpoch % 10000;

    return '$username$timestamp@$domain';
  }

  /// Generate random password for testing
  static String generatePassword() {
    final passwords = [
      'SecurePass123!',
      'MyPassword456@',
      'TestPass789#',
      r'ValidPass012$',
      'StrongPwd345%',
    ];

    return passwords[DateTime.now().millisecond % passwords.length];
  }

  /// Generate random display name for testing
  static String generateDisplayName() {
    final names = [
      'John Doe',
      'Jane Smith',
      'Test User',
      'Sample Person',
      'Demo Account',
    ];

    final now = DateTime.now();
    final baseName = names[now.millisecond % names.length];
    return '$baseName ${now.millisecondsSinceEpoch % 1000}';
  }

  /// Generate random verification token for testing
  static String generateVerificationToken() {
    final now = DateTime.now();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buffer = StringBuffer();

    // Generate 32-character token
    for (var i = 0; i < 32; i++) {
      final index = (now.millisecond + now.microsecond + i) % chars.length;
      buffer.write(chars[index]);
    }

    return buffer.toString();
  }

  /// Generate registration data for testing
  static RegistrationData generateRegistrationData() {
    return RegistrationData(
      email: generateEmail(),
      password: generatePassword(),
      displayName: generateDisplayName(),
      preferredCurrency: generateValidCurrency(),
      languageCode: generateValidLanguageCode(),
    );
  }
}

/// Data class for registration information
class RegistrationData {
  const RegistrationData({
    required this.email,
    required this.password,
    required this.displayName,
    this.preferredCurrency,
    this.languageCode,
  });
  final String email;
  final String password;
  final String displayName;
  final String? preferredCurrency;
  final String? languageCode;
}
