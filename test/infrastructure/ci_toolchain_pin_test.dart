import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CI must not float its toolchain.
///
/// Every workflow used to set `flutter-version: 'stable'`, so the Dart SDK
/// advanced underneath the repo and `flutter analyze` went from 0 issues to 36
/// with nobody committing anything. Re-running `main`'s own last green workflow
/// reproduced it: success on 2026-08-12, failure on 2026-08-17, identical
/// commit. See issue #41.
///
/// A floating pin also means a developer cannot reproduce the failure — the
/// gate says one thing locally and another in CI, which is how a gate becomes
/// something people learn to ignore.
void main() {
  /// The version every workflow must install. Bump deliberately; see the
  /// "Toolchain" section of CLAUDE.md.
  const pinnedFlutterVersion = '3.41.9';

  List<File> workflowFiles() => Directory('.github/workflows')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.yml'))
      .toList();

  /// Every `flutter-version:` value declared across the workflows.
  List<String> declaredVersions() {
    final pattern = RegExp(r"flutter-version:\s*'([^']*)'");
    return [
      for (final file in workflowFiles())
        ...pattern
            .allMatches(file.readAsStringSync())
            .map((match) => match.group(1)!),
    ];
  }

  group('CI toolchain pin', () {
    test('there are workflows to check', () {
      expect(
        workflowFiles(),
        isNotEmpty,
        reason: 'found no workflows, so this test proves nothing',
      );
      expect(declaredVersions(), isNotEmpty);
    });

    test('no workflow floats on a channel name', () {
      // 'stable' and 'beta' are moving targets: they make an unchanged commit
      // able to go red on a day nobody touched the repo.
      expect(
        declaredVersions().where(
          (version) => const [
            'stable',
            'beta',
            'master',
            'main',
            'any',
          ].contains(version),
        ),
        isEmpty,
        reason:
            'a workflow pins flutter-version to a floating channel; use an '
            'explicit version so an unchanged commit cannot break',
      );
    });

    test('every declared version is an explicit x.y.z', () {
      for (final version in declaredVersions()) {
        expect(
          version,
          matches(RegExp(r'^\d+\.\d+\.\d+$')),
          reason: '"$version" is not an explicit Flutter version',
        );
      }
    });

    test('all workflows pin the same version', () {
      // Otherwise a deploy could build on a different SDK from the one the
      // tests passed on.
      expect(declaredVersions().toSet(), hasLength(1));
      expect(declaredVersions().toSet().single, equals(pinnedFlutterVersion));
    });

    test('every setup-flutter step declares a version', () {
      // A step with only `channel:` and no `flutter-version:` floats just as
      // badly, which is what test.yml did.
      for (final file in workflowFiles()) {
        final content = file.readAsStringSync();
        final setups = 'subosito/flutter-action'.allMatches(content).length;
        final pins = 'flutter-version:'.allMatches(content).length;

        expect(
          pins,
          equals(setups),
          reason:
              '${file.path} sets up Flutter $setups time(s) but pins a version '
              '$pins time(s)',
        );
      }
    });

    test('CLAUDE.md documents the pinned version', () {
      // Pinning rots into a years-old SDK unless the upgrade path is written
      // down where the next person will read it.
      expect(
        File('CLAUDE.md').readAsStringSync(),
        contains(pinnedFlutterVersion),
        reason:
            'CLAUDE.md must name the pinned Flutter version so upgrading it is '
            'a deliberate, documented act',
      );
    });
  });
}
