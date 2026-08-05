import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/shared/theme/app_fonts.dart';

/// Font assets registered by [loadAppFonts], keyed by font family.
///
/// These paths must stay in sync with the `flutter > fonts` section of
/// `pubspec.yaml`. `golden_helpers_test.dart` fails if they drift, so the
/// duplication cannot rot silently.
const Map<String, List<String>> goldenFontAssets = <String, List<String>>{
  AppFonts.heading: <String>[
    'assets/fonts/Outfit/static/Outfit-Regular.ttf',
    'assets/fonts/Outfit/static/Outfit-SemiBold.ttf',
    'assets/fonts/Outfit/static/Outfit-ExtraBold.ttf',
  ],
  AppFonts.body: <String>[
    'assets/fonts/Inter/static/Inter_18pt-Regular.ttf',
    'assets/fonts/Inter/static/Inter_18pt-Medium.ttf',
    'assets/fonts/Inter/static/Inter_18pt-SemiBold.ttf',
  ],
};

var _fontsLoaded = false;

/// Registers the app's real font families with the test font system.
///
/// Call this before any golden assertion whose expected outcome involves text.
/// Without it, `flutter_test` substitutes a placeholder font that renders every
/// glyph as a filled rectangle: the PNG then proves layout but not a single
/// character of copy, currency formatting, or any number shown on screen.
///
/// Safe to call from every test; the work happens once per test process.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;

  for (final entry in goldenFontAssets.entries) {
    final loader = FontLoader(entry.key);
    for (final assetPath in entry.value) {
      loader.addFont(_readFontAsset(assetPath));
    }
    await loader.load();
  }

  _fontsLoaded = true;
}

/// Reads a font file from the repository working directory.
///
/// `flutter test` runs with the package root as its working directory, so the
/// asset paths from `pubspec.yaml` resolve directly. Reading from disk rather
/// than `rootBundle` avoids depending on an asset bundle that the widget test
/// binding does not populate.
///
/// The read is deliberately synchronous and wrapped in a [SynchronousFuture].
/// `testWidgets` bodies run inside a fake-async zone where real asynchronous
/// file I/O never completes, so an `await File(...).readAsBytes()` here makes
/// [FontLoader.load] hang forever instead of failing. Keeping it synchronous is
/// what allows `await loadAppFonts()` to work directly inside a `testWidgets`
/// body as well as in `setUpAll`.
SynchronousFuture<ByteData> _readFontAsset(String assetPath) {
  final bytes = File(assetPath).readAsBytesSync();
  return SynchronousFuture<ByteData>(
    ByteData.view(Uint8List.fromList(bytes).buffer),
  );
}
