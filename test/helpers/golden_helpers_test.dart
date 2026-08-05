import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/shared/theme/app_fonts.dart';
import 'package:grex/shared/theme/app_theme.dart';

import 'golden_helpers.dart';

/// A widget that always throws from [build], used to pin the second golden
/// failure mode: a crashed widget still produces a PNG.
class _ThrowingWidget extends StatelessWidget {
  const _ThrowingWidget();

  @override
  Widget build(BuildContext context) {
    throw StateError('deliberate failure for the golden harness');
  }
}

void main() {
  group('loadAppFonts', () {
    // Tagged `golden` so CI can exclude it: pixel output depends on the host
    // renderer, and the committed PNGs are generated on macOS. The two
    // untagged tests below still guard against asset drift on every CI run.
    testWidgets('renders text as real glyphs in a golden', tags: ['golden'], (
      tester,
    ) async {
      await loadAppFonts();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Grex golden harness',
                    style: TextStyle(
                      fontFamily: AppFonts.heading,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    '100.00',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 48,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/golden_harness_text.png'),
      );
    });

    test('font assets exist on disk', () {
      for (final paths in goldenFontAssets.values) {
        for (final path in paths) {
          expect(
            File(path).existsSync(),
            isTrue,
            reason: 'font asset $path is missing; update goldenFontAssets',
          );
        }
      }
    });

    test('font assets match the pubspec.yaml font declarations', () {
      // Scans the `flutter > fonts` block for `asset:` entries and compares
      // them with what the helper registers, so the hardcoded list in
      // golden_helpers.dart cannot drift from what the app ships.
      final pubspecLines = File('pubspec.yaml').readAsLinesSync();
      final declaredAssets = <String>{};
      var insideFontsBlock = false;

      for (final line in pubspecLines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('#')) continue;
        if (trimmed == 'fonts:' && line.startsWith('  fonts:')) {
          insideFontsBlock = true;
          continue;
        }
        // Entries appear as `- asset: path` under each family's `fonts:` list.
        final assetEntry = trimmed.startsWith('- asset:')
            ? trimmed.substring('- asset:'.length)
            : trimmed.startsWith('asset:')
            ? trimmed.substring('asset:'.length)
            : null;
        if (insideFontsBlock && assetEntry != null) {
          declaredAssets.add(assetEntry.trim());
        }
      }

      expect(
        declaredAssets,
        isNotEmpty,
        reason: 'failed to parse any font assets out of pubspec.yaml',
      );
      expect(
        goldenFontAssets.values.expand((paths) => paths).toSet(),
        equals(declaredAssets),
      );
    });
  });

  group('golden failure modes', () {
    testWidgets(
      'a crashed widget still produces a golden PNG',
      tags: ['golden'],
      (tester) async {
        await loadAppFonts();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: _ThrowingWidget()),
          ),
        );

        // The framework swallows the build error and substitutes ErrorWidget,
        // so the render tree is valid and a golden gets written regardless.
        expect(tester.takeException(), isA<StateError>());
        expect(find.byType(ErrorWidget), findsOneWidget);

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/golden_harness_error_screen.png'),
        );
      },
    );
  });
}
