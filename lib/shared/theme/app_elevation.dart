/// Material elevation tokens.
///
/// Keep the elevation set small — when every card has its own shadow depth
/// the hierarchy collapses. Use [card] for resting surfaces, [floating] for
/// modal/FAB-style affordances, and reserve [overlay] for transient layers.
class AppElevation {
  AppElevation._();

  /// 0 — flush with the background.
  static const double flat = 0;

  /// 1 — resting card / list item.
  static const double card = 1;

  /// 3 — raised card / app bar on scroll.
  static const double raised = 3;

  /// 6 — floating action / persistent bottom sheet.
  static const double floating = 6;

  /// 12 — modal overlay.
  static const double overlay = 12;
}
