import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The formatting gate must be scoped to the repository's own sources.
///
/// `dart format .` walks `build/`, where a populated build tree holds
/// vendored third-party sources. On Flutter 3.47.0 the formatter rewrites
/// eleven of them, so `--set-exit-if-changed .` exited 1 on any machine that
/// had built while the repository itself was clean. CI never saw it, because a
/// fresh checkout has no `build/` -- the same "green in CI, red locally" split
/// that #41 was about.
///
/// The pre-commit hooks run the same command, so the unscoped form did not
/// merely confuse: it blocked commits outright. See issue #46.
void main() {
  /// Directories that hold tracked Dart sources.
  const scope = 'lib test integration_test tool';

  /// Every place the formatting gate is invoked, and must agree.
  const invocationSites = [
    '.github/workflows/test.yml',
    'CLAUDE.md',
    'scripts/linux/development/setup-git-hooks.sh',
    'scripts/windows/development/setup-git-hooks.ps1',
  ];

  group('format gate scope', () {
    test('the sites to check all exist', () {
      for (final path in invocationSites) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: '$path is missing, so this test would silently prove nothing',
        );
      }
    });

    test('no invocation formats the whole tree', () {
      // `dart format .` and `dart format --set-exit-if-changed .` both walk
      // build output. Neither may reappear.
      final offenders = <String>[];
      for (final path in invocationSites) {
        for (final line in File(path).readAsLinesSync()) {
          if (!line.contains('dart format')) continue;
          final trimmed = line.trimRight();
          if (trimmed.endsWith('dart format .') ||
              trimmed.endsWith('--set-exit-if-changed .') ||
              trimmed.contains('dart format . ')) {
            offenders.add('$path: ${line.trim()}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'these invocations format the entire tree, including build/, which '
            'makes the gate fail on any machine that has built',
      );
    });

    test('every invocation names the same scope', () {
      // Otherwise CI, the hook and the docs can drift apart, which is how the
      // gate stops meaning anything.
      for (final path in invocationSites) {
        final content = File(path).readAsStringSync();
        if (!content.contains('dart format')) continue;
        expect(
          content,
          contains('dart format --set-exit-if-changed $scope'),
          reason: '$path does not use the agreed scope "$scope"',
        );
      }
    });

    test('the scope covers every directory holding tracked Dart files', () {
      // A new top-level directory of Dart sources would otherwise go
      // unformatted and unnoticed.
      final tracked = Process.runSync('git', [
        'ls-files',
        '*.dart',
      ]).stdout.toString().trim().split('\n');

      expect(tracked.length, greaterThan(100), reason: 'git ls-files failed');

      final topLevel = tracked
          .where((path) => path.contains('/'))
          .map((path) => path.split('/').first)
          .toSet();

      expect(
        topLevel.difference(scope.split(' ').toSet()),
        isEmpty,
        reason:
            'these directories hold tracked .dart files but are outside the '
            'formatting scope; add them here and to every invocation site',
      );
    });
  });
}
