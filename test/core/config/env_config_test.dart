import 'package:flutter_test/flutter_test.dart';
import 'package:grex/core/config/env_config.dart';

/// Tests for the config fallback chain, with the committed `.env` placeholder
/// in place.
///
/// `.env` is a declared Flutter asset, so it has to exist for the app to build
/// at all — it is committed empty for exactly that reason. These tests pin the
/// two halves of that arrangement: an absent or empty file must fall through to
/// defaults, and a file that does have values must still win over them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnvConfig', () {
    group('with no env file present', () {
      setUp(() async {
        await EnvConfig.load(fileName: '.env.does-not-exist');
      });

      test('load reports itself uninitialized instead of throwing', () {
        expect(EnvConfig.isInitialized, isFalse);
      });

      test('get falls back to the supplied default', () {
        expect(
          EnvConfig.get('SUPABASE_URL', defaultValue: 'https://fallback.test'),
          equals('https://fallback.test'),
        );
      });

      test('get returns empty string when no default is supplied', () {
        expect(EnvConfig.get('SUPABASE_URL'), isEmpty);
      });

      test('typed getters fall back to their defaults', () {
        expect(EnvConfig.getInt('API_TIMEOUT', defaultValue: 30), equals(30));
        expect(
          EnvConfig.getBool('ENABLE_LOGGING', defaultValue: true),
          isTrue,
        );
        expect(
          EnvConfig.getDouble('SOME_RATIO', defaultValue: 1.5),
          equals(1.5),
        );
      });

      test('has reports the key as absent', () {
        expect(EnvConfig.has('SUPABASE_URL'), isFalse);
      });

      test('getAll is empty', () {
        expect(EnvConfig.getAll(), isEmpty);
      });
    });

    group('with the committed .env placeholder', () {
      setUp(() async {
        await EnvConfig.load();
      });

      test('loads successfully, so a fresh clone boots', () {
        expect(EnvConfig.isInitialized, isTrue);
      });

      test('carries no keys, so it cannot shadow anything', () {
        // The placeholder is comments-only on purpose. A key with an empty
        // value would be read as a real empty value by dotenv's typed getters
        // and could override an environment-aware default.
        expect(EnvConfig.getAll(), isEmpty);
      });

      test('every lookup still falls through to its default', () {
        expect(
          EnvConfig.get('SUPABASE_URL', defaultValue: 'https://fallback.test'),
          equals('https://fallback.test'),
        );
        expect(EnvConfig.getInt('API_TIMEOUT', defaultValue: 30), equals(30));
        expect(EnvConfig.has('SUPABASE_ANON_KEY'), isFalse);
      });
    });

    group('with a file that does have values', () {
      // `.env.example` is a committed, declared asset with real values in it,
      // so it stands in for a developer's filled-in `.env` without this test
      // ever touching the developer's actual file.
      setUp(() async {
        await EnvConfig.load(fileName: '.env.example');
      });

      test('file values take precedence over the supplied default', () {
        expect(
          EnvConfig.get('ENVIRONMENT', defaultValue: 'production'),
          equals('development'),
        );
        expect(
          EnvConfig.get('SUPABASE_LOCAL_URL', defaultValue: 'unused'),
          equals('http://localhost:54321'),
        );
      });

      test('typed getters read the file value, not the default', () {
        expect(EnvConfig.getInt('API_TIMEOUT', defaultValue: 999), equals(30));
      });

      test('has reports a populated key as present', () {
        expect(EnvConfig.has('ENVIRONMENT'), isTrue);
      });

      test('a key present but empty falls through to the default', () {
        // `BASE_URL=` with nothing after it is not a value.
        expect(
          EnvConfig.get('BASE_URL', defaultValue: 'https://fallback.test'),
          equals('https://fallback.test'),
        );
        expect(EnvConfig.has('BASE_URL'), isFalse);
      });

      test('an absent key still falls through to the default', () {
        expect(
          EnvConfig.get('NOT_IN_ANY_FILE', defaultValue: 'default'),
          equals('default'),
        );
      });
    });
  });
}
