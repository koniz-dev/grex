import 'package:grex/core/config/env_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  SupabaseConfig._();

  /// Initialize Supabase with environment configuration
  ///
  /// This should be called before runApp() in main.dart after EnvConfig.load()
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await EnvConfig.load();
  ///   await SupabaseConfig.initialize();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> initialize() async {
    final supabaseUrl = EnvConfig.get(
      'SUPABASE_URL',
      defaultValue: EnvConfig.get('SUPABASE_LOCAL_URL'),
    );

    final supabaseAnonKey = EnvConfig.get(
      'SUPABASE_ANON_KEY',
      defaultValue: EnvConfig.get('SUPABASE_LOCAL_ANON_KEY'),
    );

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'Supabase configuration missing. Please set SUPABASE_URL and '
        'SUPABASE_ANON_KEY in your .env file or use --dart-define flags.',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: EnvConfig.getBool('ENABLE_DEBUG_FEATURES'),
    );
  }

  /// Get the Supabase client instance
  ///
  /// This should only be called after initialize() has been called
  static SupabaseClient get client => Supabase.instance.client;

  /// Check if Supabase has been initialized
  static bool get isInitialized =>
      Supabase.instance.client.auth.currentUser != null ||
      Supabase.instance.client.auth.currentSession != null;
}
