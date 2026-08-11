import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loader with fallback chain:
/// 1. .env file (for local development)
/// 2. --dart-define flags (for CI/CD)
/// 3. Default values
///
/// Usage:
/// ```dart
/// await EnvConfig.load();
/// final value = EnvConfig.get('BASE_URL');
/// ```
class EnvConfig {
  EnvConfig._();

  static bool _isInitialized = false;

  /// Values supplied with `--dart-define`, keyed by name.
  ///
  /// This table exists because `String.fromEnvironment` only resolves when the
  /// call **and** its key are constant. `String.fromEnvironment(key)` with a
  /// runtime `key` silently returns the default, so the old lookup meant every
  /// `--dart-define` passed to this app was ignored without a word. Proven
  /// under `--dart-define=PROBE_KEY=hello`: the const form returned `hello`,
  /// the runtime-key form returned `''`.
  ///
  /// The consequence of the fix is that the supported set is finite and
  /// explicit. A define whose name is not listed here cannot be read. Keep this
  /// in step with `.env.example`; `env_config_dart_define_test.dart` fails if
  /// they drift apart.
  static const Map<String, String> _dartDefines = <String, String>{
    'ENVIRONMENT': String.fromEnvironment('ENVIRONMENT'),
    'BASE_URL': String.fromEnvironment('BASE_URL'),
    'API_TIMEOUT': String.fromEnvironment('API_TIMEOUT'),
    'API_CONNECT_TIMEOUT': String.fromEnvironment('API_CONNECT_TIMEOUT'),
    'API_RECEIVE_TIMEOUT': String.fromEnvironment('API_RECEIVE_TIMEOUT'),
    'API_SEND_TIMEOUT': String.fromEnvironment('API_SEND_TIMEOUT'),
    'ENABLE_LOGGING': String.fromEnvironment('ENABLE_LOGGING'),
    'ENABLE_ANALYTICS': String.fromEnvironment('ENABLE_ANALYTICS'),
    'ENABLE_CRASH_REPORTING': String.fromEnvironment('ENABLE_CRASH_REPORTING'),
    'ENABLE_PERFORMANCE_MONITORING': String.fromEnvironment(
      'ENABLE_PERFORMANCE_MONITORING',
    ),
    'ENABLE_DEBUG_FEATURES': String.fromEnvironment('ENABLE_DEBUG_FEATURES'),
    'ENABLE_HTTP_LOGGING': String.fromEnvironment('ENABLE_HTTP_LOGGING'),
    'APP_VERSION': String.fromEnvironment('APP_VERSION'),
    'APP_BUILD_NUMBER': String.fromEnvironment('APP_BUILD_NUMBER'),
    'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
    'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY'),
    'SUPABASE_SERVICE_ROLE_KEY': String.fromEnvironment(
      'SUPABASE_SERVICE_ROLE_KEY',
    ),
    'SUPABASE_LOCAL_URL': String.fromEnvironment('SUPABASE_LOCAL_URL'),
    'SUPABASE_LOCAL_ANON_KEY': String.fromEnvironment(
      'SUPABASE_LOCAL_ANON_KEY',
    ),
    'GOOGLE_WEB_CLIENT_ID': String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
    'GOOGLE_IOS_CLIENT_ID': String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
  };

  /// Every key that can be supplied with `--dart-define`.
  static Set<String> get dartDefineKeys => _dartDefines.keys.toSet();

  /// The `--dart-define` value for [key], or an empty string if unset or
  /// unsupported.
  static String _dartDefine(String key) => _dartDefines[key] ?? '';

  /// Load environment variables from .env file
  ///
  /// This should be called before runApp() in main.dart
  ///
  /// The .env file is optional. If it doesn't exist, the system will fall back
  /// to --dart-define flags or default values.
  ///
  /// Note: For .env to be loaded, it must be added to pubspec.yaml assets
  /// after creating it from .env.example
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await EnvConfig.load();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> load({String fileName = '.env'}) async {
    try {
      await dotenv.load(fileName: fileName);
      _isInitialized = true;
    } on Exception catch (_) {
      // .env file is optional - fallback to --dart-define or defaults
      // This is expected in CI/CD environments where .env files aren't used
      _isInitialized = false;
    } on Object catch (_) {
      // Catch all other errors (FileNotFoundError, etc.)
      // .env file is optional - fallback to --dart-define or defaults
      _isInitialized = false;
    }
  }

  /// Get environment variable with fallback chain:
  /// 1. .env file value (if loaded)
  /// 2. --dart-define flag value
  /// 3. Default value (if provided)
  ///
  /// Parameters:
  /// - [key]: The environment variable key
  /// - [defaultValue]: Optional default value if not found in .env or
  ///   --dart-define
  ///
  /// Returns:
  /// The environment variable value, or [defaultValue] if not found
  ///
  /// Example:
  /// ```dart
  /// final baseUrl = EnvConfig.get(
  ///   'BASE_URL',
  ///   defaultValue: 'https://api.example.com',
  /// );
  /// ```
  static String get(String key, {String defaultValue = ''}) {
    // Priority 1: Check .env file (if loaded)
    // Use dotenv.get() with fallback for better null safety support
    if (_isInitialized) {
      try {
        final value = dotenv.get(key, fallback: '');
        if (value.isNotEmpty) {
          return value;
        }
      } on Exception {
        // Variable not found in .env, continue to next priority
      }
    }

    // Priority 2: Check --dart-define flags
    final dartDefineValue = _dartDefine(key);
    if (dartDefineValue.isNotEmpty) {
      return dartDefineValue;
    }

    // Priority 3: Return default value
    return defaultValue;
  }

  /// Get environment variable as boolean
  ///
  /// Returns true for: 'true', '1', 'yes', 'on' (case-insensitive)
  /// Returns false otherwise or if not found
  static bool getBool(String key, {bool defaultValue = false}) {
    // Priority 1: Check .env file (if loaded)
    if (_isInitialized) {
      try {
        return dotenv.getBool(key, fallback: defaultValue);
      } on Exception {
        // Variable not found in .env, continue to next priority
      }
    }

    // Priority 2: Check --dart-define flags
    final dartDefineValue = _dartDefine(key);
    if (dartDefineValue.isNotEmpty) {
      final lowerValue = dartDefineValue.toLowerCase().trim();
      return lowerValue == 'true' ||
          lowerValue == '1' ||
          lowerValue == 'yes' ||
          lowerValue == 'on';
    }

    // Priority 3: Return default value
    return defaultValue;
  }

  /// Get environment variable as integer
  ///
  /// Returns parsed integer value or defaultValue if not found or invalid
  static int getInt(String key, {int defaultValue = 0}) {
    // Priority 1: Check .env file (if loaded)
    if (_isInitialized) {
      try {
        return dotenv.getInt(key, fallback: defaultValue);
      } on Exception {
        // Variable not found in .env, continue to next priority
      }
    }

    // Priority 2: Check --dart-define flags
    final dartDefineValue = _dartDefine(key);
    if (dartDefineValue.isNotEmpty) {
      return int.tryParse(dartDefineValue) ?? defaultValue;
    }

    // Priority 3: Return default value
    return defaultValue;
  }

  /// Get environment variable as double
  ///
  /// Returns parsed double value or defaultValue if not found or invalid
  static double getDouble(String key, {double defaultValue = 0.0}) {
    // Priority 1: Check .env file (if loaded)
    if (_isInitialized) {
      try {
        return dotenv.getDouble(key, fallback: defaultValue);
      } on Exception {
        // Variable not found in .env, continue to next priority
      }
    }

    // Priority 2: Check --dart-define flags
    final dartDefineValue = _dartDefine(key);
    if (dartDefineValue.isNotEmpty) {
      return double.tryParse(dartDefineValue) ?? defaultValue;
    }

    // Priority 3: Return default value
    return defaultValue;
  }

  /// Check if an environment variable exists
  ///
  /// Returns true if the variable exists in .env file or --dart-define
  static bool has(String key) {
    // Check .env file (if loaded)
    if (_isInitialized) {
      try {
        final value = dotenv.maybeGet(key);
        if (value != null && value.isNotEmpty) {
          return true;
        }
      } on Exception {
        // Variable not found in .env
      }
    }
    // Check --dart-define flags
    return _dartDefine(key).isNotEmpty;
  }

  /// Get all environment variables as a map
  ///
  /// Useful for debugging or logging configuration
  static Map<String, String> getAll() {
    final env = <String, String>{};

    // Add .env file values
    if (_isInitialized) {
      env.addAll(dotenv.env);
    }

    // Note: --dart-define values are compile-time only and cannot be
    // enumerated at runtime. They must be accessed via String.fromEnvironment()
    return env;
  }

  /// Check if EnvConfig has been initialized
  static bool get isInitialized => _isInitialized;
}
