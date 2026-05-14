import 'package:flutter/widgets.dart';

/// Corner radius scale.
///
/// All component corner radii should reference these values to keep the
/// "softness" of the UI consistent. Mixing arbitrary radii (e.g. `8` here
/// and `12` there for the same component) is the fastest way to make a UI
/// look amateur.
class AppRadius {
  AppRadius._();

  /// 4pt — chips, pills.
  static const double xs = 4;

  /// 8pt — small inputs and dense buttons.
  static const double sm = 8;

  /// 12pt — default for cards, list items, primary buttons.
  static const double md = 12;

  /// 16pt — modal sheets, dialogs.
  static const double lg = 16;

  /// 24pt — full-bleed feature surfaces.
  static const double xl = 24;

  /// Fully rounded (pill / circle).
  static const double full = 999;

  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
}
