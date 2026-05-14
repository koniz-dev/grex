/// Animation duration tokens.
///
/// Motion budget rule of thumb: small UI affordances (taps, ripples) should
/// resolve under 200ms so they feel instant; page-level transitions live
/// around 250–400ms; ambient motion (shimmer, breathing) is longer-running.
class AppDurations {
  AppDurations._();

  /// 120ms — micro feedback (toggles, button press).
  static const Duration fast = Duration(milliseconds: 120);

  /// 200ms — default UI affordance.
  static const Duration short = Duration(milliseconds: 200);

  /// 280ms — page/list element entrance.
  static const Duration medium = Duration(milliseconds: 280);

  /// 400ms — large overlays (sheets, dialogs).
  static const Duration long = Duration(milliseconds: 400);

  /// 1200ms — ambient shimmer loop.
  static const Duration shimmer = Duration(milliseconds: 1200);
}
