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
      // These assert the "absent everywhere" fallback, so they deliberately use
      // keys that no `--dart-define` can supply. A real key such as
      // SUPABASE_URL would resolve from a define when the suite is run with
      // one, and the assertion would be about the runner's flags rather than
      // about EnvConfig. See issue #23.
      const absentKey = 'KEY_NO_DEFINE_CAN_SUPPLY';
      const absentIntKey = 'INT_KEY_NO_DEFINE_CAN_SUPPLY';
      const absentBoolKey = 'BOOL_KEY_NO_DEFINE_CAN_SUPPLY';

      setUp(() async {
        await EnvConfig.load(fileName: '.env.does-not-exist');
      });

      test('load reports itself uninitialized instead of throwing', () {
        expect(EnvConfig.isInitialized, isFalse);
      });

      test('get falls back to the supplied default', () {
        expect(
          EnvConfig.get(absentKey, defaultValue: 'https://fallback.test'),
          equals('https://fallback.test'),
        );
      });

      test('get returns empty string when no default is supplied', () {
        expect(EnvConfig.get(absentKey), isEmpty);
      });

      test('typed getters fall back to their defaults', () {
        expect(EnvConfig.getInt(absentIntKey, defaultValue: 30), equals(30));
        expect(
          EnvConfig.getBool(absentBoolKey, defaultValue: true),
          isTrue,
        );
        expect(
          EnvConfig.getDouble('SOME_RATIO', defaultValue: 1.5),
          equals(1.5),
        );
      });

      test('has reports the key as absent', () {
        expect(EnvConfig.has(absentKey), isFalse);
      });

      test('getAll is empty', () {
        expect(EnvConfig.getAll(), isEmpty);
      });
    });

    group('with the committed .env asset', () {
      // Deliberately asserts nothing about what is *in* `.env`. The file ships
      // empty but developers fill it in, so any assertion on its contents would
      // pass on a fresh clone and fail on every configured machine. What has to
      // hold in both states is that the asset exists and loads — that is the
      // build failure this file was committed to fix.
      setUp(() async {
        await EnvConfig.load();
      });

      test('loads successfully, so a fresh clone boots', () {
        expect(EnvConfig.isInitialized, isTrue);
      });

      test('a key absent from it falls through to its default', () {
        expect(
          EnvConfig.get('NOT_IN_ANY_FILE', defaultValue: 'fallback'),
          equals('fallback'),
        );
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
