/// Centralized font family constants for the application.
///
/// All references to a font family in the app should go through this class,
/// either directly or via `AppTextStyles` / `ThemeData.fontFamily`. Changing a
/// constant here cascades through every screen — no other place in the codebase
/// should hardcode a font family string.
///
/// The matching font assets are declared in `pubspec.yaml` under
/// `flutter > fonts`.
class AppFonts {
  AppFonts._();

  /// Display font — used for headings, logo, primary buttons, and other
  /// high-emphasis UI text. Weights bundled: 400, 600, 800.
  static const String heading = 'Outfit';

  /// Body font — used for paragraph copy, inputs, captions, and most general
  /// text. Weights bundled: 400, 500, 600. Also wired as the app-wide default
  /// via `ThemeData.fontFamily`.
  static const String body = 'Inter';
}
