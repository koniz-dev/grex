import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grex/core/config/env_config.dart';

/// Run with the defines these tests assert on:
///
/// ```bash
/// flutter test --dart-define=SUPABASE_URL=https://define.test \
///              --dart-define=API_TIMEOUT=77 \
///              --dart-define=ENABLE_LOGGING=true \
///              --dart-define=ENVIRONMENT=staging \
///              test/core/config/env_config_dart_define_test.dart
/// ```
///
/// Without those defines the value-reading tests are skipped rather than
/// silently passing: a test that asserts "the define is absent" would have gone
/// green against the very bug this file exists to pin. See issue #23.
const _urlFromDefine = String.fromEnvironment('SUPABASE_URL');
const _timeoutFromDefine = String.fromEnvironment('API_TIMEOUT');
const _loggingFromDefine = String.fromEnvironment('ENABLE_LOGGING');
const _environmentFromDefine = String.fromEnvironment('ENVIRONMENT');

final String? _skipWithoutDefines = _urlFromDefine.isEmpty
    ? 'run with --dart-define=SUPABASE_URL=... (see the header of this file)'
    : null;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('--dart-define resolution', () {
    setUp(() async {
      // No env file, so the define is the only thing that can supply a value.
      await EnvConfig.load(fileName: '.env.does-not-exist');
    });

    test(
      'get returns a value passed with --dart-define',
      () {
        expect(EnvConfig.get('SUPABASE_URL'), equals(_urlFromDefine));
        expect(EnvConfig.get('SUPABASE_URL'), isNotEmpty);
      },
      skip: _skipWithoutDefines,
    );

    test(
      'get prefers the define over the supplied default',
      () {
        expect(
          EnvConfig.get('SUPABASE_URL', defaultValue: 'https://fallback.test'),
          equals(_urlFromDefine),
        );
      },
      skip: _skipWithoutDefines,
    );

    test(
      'getInt reads the define',
      () {
        expect(
          EnvConfig.getInt('API_TIMEOUT', defaultValue: 30),
          equals(int.parse(_timeoutFromDefine)),
        );
      },
      skip: _timeoutFromDefine.isEmpty ? _skipWithoutDefines : null,
    );

    test(
      'getBool reads the define',
      () {
        expect(
          EnvConfig.getBool('ENABLE_LOGGING'),
          equals(_loggingFromDefine.toLowerCase() == 'true'),
        );
      },
      skip: _loggingFromDefine.isEmpty ? _skipWithoutDefines : null,
    );

    test(
      'has reports a key supplied only by --dart-define',
      () {
        expect(EnvConfig.has('SUPABASE_URL'), isTrue);
      },
      skip: _skipWithoutDefines,
    );

    test(
      'a file value wins over a define of the same key',
      () async {
        // `.env.example` sets ENVIRONMENT=development; the define says staging.
        // The documented order is file, then define, then default.
        await EnvConfig.load(fileName: '.env.example');

        expect(_environmentFromDefine, equals('staging'));
        expect(
          EnvConfig.get('ENVIRONMENT', defaultValue: 'production'),
          equals('development'),
        );
      },
      skip: _environmentFromDefine.isEmpty ? _skipWithoutDefines : null,
    );

    test('getAll never exposes a define', () {
      // --dart-define values are compile-time and cannot be enumerated, so
      // getAll must not pretend otherwise. No file is loaded here, so anything
      // getAll returned would have to have come from a define.
      expect(EnvConfig.getAll(), isEmpty);
    });

    test('an unsupported key resolves to the default, not a define', () {
      // The supported set is finite by construction: only const keys resolve.
      expect(EnvConfig.dartDefineKeys, isNot(contains('NOT_A_REAL_KEY')));
      expect(
        EnvConfig.get('NOT_A_REAL_KEY', defaultValue: 'fallback'),
        equals('fallback'),
      );
    });
  });

  group('supported define keys', () {
    test('cover every key documented in .env.example', () {
      final documented = File('.env.example')
          .readAsLinesSync()
          .map((line) => line.trim())
          .where((line) => !line.startsWith('#') && line.contains('='))
          .map((line) => line.split('=').first.trim())
          .where((key) => key.isNotEmpty)
          .toSet();

      expect(
        documented,
        isNotEmpty,
        reason: 'the parse found no keys, so this test proves nothing',
      );

      // Enumerated, not spot-checked: a key added to .env.example that nobody
      // adds to the define table would be settable in one configuration path
      // and silently ignored in the other.
      expect(
        documented.difference(EnvConfig.dartDefineKeys),
        isEmpty,
        reason:
            'these keys are documented in .env.example but cannot be supplied '
            'with --dart-define; add them to _dartDefines in env_config.dart',
      );
    });

    test('contain no key that .env.example does not document', () {
      final documented = File('.env.example')
          .readAsLinesSync()
          .map((line) => line.trim())
          .where((line) => !line.startsWith('#') && line.contains('='))
          .map((line) => line.split('=').first.trim())
          .toSet();

      expect(
        EnvConfig.dartDefineKeys.difference(documented),
        isEmpty,
        reason:
            'these keys accept a --dart-define but are undocumented, so nobody '
            'would know they exist; add them to .env.example',
      );
    });
  });
}
