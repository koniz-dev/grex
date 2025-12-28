import 'package:flutter/material.dart';
import 'package:grex/l10n/app_localizations.dart';

/// BuildContext extension methods
///
/// This extension provides convenient methods for common BuildContext
/// operations including navigation, theming, and UI feedback.
///
/// **Navigation Approach:**
/// This extension provides basic navigation methods. For advanced routing
/// features (deep linking, type-safe routes, etc.), use the navigation
/// extensions from `core/routing/navigation_extensions.dart` which use GoRouter.
///
/// **Usage:**
/// ```dart
/// context.navigateTo(RegisterScreen());
/// context.showSnackBar('Operation successful');
/// ```
extension ContextExtensions on BuildContext {
  /// Quick access to AppLocalizations
  ///
  /// Usage: context.l10n.someString
  ///
  /// Throws assertion error if AppLocalizations is not found in context.
  /// Use [l10nOrNull] for safe access when localization might not be available.
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    assert(localizations != null, 'AppLocalizations not found in context');
    return localizations!;
  }

  /// Safe access to AppLocalizations with null fallback
  ///
  /// Usage: context.l10nOrNull?.someString ?? 'Fallback'
  ///
  /// Returns null if AppLocalizations is not available in context.
  /// Useful for widgets that might render before localization is ready
  /// or outside the MaterialApp widget tree.
  AppLocalizations? get l10nOrNull => AppLocalizations.of(this);

  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Get screen size
  Size get screenSize => mediaQuery.size;

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Check if screen is mobile (< 600px)
  bool get isMobile => screenWidth < 600;

  /// Check if screen is tablet (600px - 1024px)
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;

  /// Check if screen is desktop (>= 1024px)
  bool get isDesktop => screenWidth >= 1024;

  /// Show snackbar
  void showSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Navigate to a route
  Future<T?> navigateTo<T>(Widget route) {
    return Navigator.of(this).push<T>(
      MaterialPageRoute<T>(builder: (_) => route),
    );
  }

  /// Navigate and replace current route
  Future<T?> navigateToReplacement<T>(Widget route) {
    return Navigator.of(this).pushReplacement<T, void>(
      MaterialPageRoute<T>(builder: (_) => route),
    );
  }

  /// Pop current route
  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }
}
