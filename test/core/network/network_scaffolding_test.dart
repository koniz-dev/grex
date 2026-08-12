import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Dio network layer is kept deliberately but is not in the request path:
/// every repository talks to `SupabaseClient` directly. Issue #7's decision was
/// to keep it as scaffolding and make the code say so.
///
/// A comment claiming "unused" rots the moment someone uses it, so these tests
/// pin both halves of the claim: the notices exist, and the layer really does
/// have no consumer. Wiring it up is allowed — it just has to come with
/// deleting the notices, which is exactly what these failures will say.
void main() {
  /// The sentinel each scaffolding file must open with.
  const notice = '// UNUSED SCAFFOLDING:';

  /// Same sentinel, as a doc comment, for the provider definition.
  const docNotice = '/// UNUSED SCAFFOLDING:';

  group('scaffolding notices', () {
    test('every file under lib/core/network/ carries one', () {
      final files = Directory('lib/core/network')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();

      expect(
        files,
        isNotEmpty,
        reason: 'found no files to check, so this test proves nothing',
      );

      final missing = files
          .where((file) => !file.readAsStringSync().startsWith(notice))
          .map((file) => file.path)
          .toList();

      // Enumerated rather than spot-checked: a new interceptor added without a
      // notice would otherwise read as part of the live request path.
      expect(
        missing,
        isEmpty,
        reason:
            'these files under lib/core/network/ do not open with "$notice", '
            'so a reader cannot tell they are not in the request path',
      );
    });

    test('api_endpoints.dart carries one', () {
      // Not under lib/core/network/, but reachable only from the dead layer.
      expect(
        File('lib/core/constants/api_endpoints.dart').readAsStringSync(),
        startsWith(notice),
      );
    });

    test('the apiClientProvider definition carries one', () {
      expect(
        File('lib/core/di/providers.dart').readAsStringSync(),
        contains(docNotice),
      );
    });
  });

  group('the layer really has no consumer', () {
    test('apiClientProvider is referenced only where it is defined', () {
      final references = <String>[];

      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (!line.contains('apiClientProvider')) continue;
          // Skip the notices, which name it on purpose.
          if (line.trimLeft().startsWith('//')) continue;
          references.add('${entity.path}:${i + 1}');
        }
      }

      // If this fails because the layer was wired up, that is fine and good --
      // delete the UNUSED SCAFFOLDING notices in lib/core/network/,
      // lib/core/constants/api_endpoints.dart and lib/core/di/providers.dart,
      // and delete this test. What must not happen is the notices going stale
      // while still claiming nothing uses the layer.
      expect(
        references,
        hasLength(1),
        reason:
            'apiClientProvider should be referenced only by its own definition '
            'while the layer is scaffolding; found: $references',
      );
      expect(references.single, contains('lib/core/di/providers.dart'));
    });
  });
}
