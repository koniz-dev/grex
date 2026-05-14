import 'package:flutter/widgets.dart';

/// Layout spacing scale (4pt base).
///
/// Use these constants instead of raw numeric values to keep vertical and
/// horizontal rhythm consistent across the app. The scale is multiplicative
/// from a 4pt base so every value composes predictably with the rest of the
/// design system.
class AppSpacing {
  AppSpacing._();

  /// 2pt — hairline gap (icon-to-text in dense rows).
  static const double xxs = 2;

  /// 4pt — tight inline gap.
  static const double xs = 4;

  /// 8pt — small inline gap (icon ↔ label).
  static const double sm = 8;

  /// 12pt — comfortable inline gap.
  static const double md = 12;

  /// 16pt — default container padding.
  static const double lg = 16;

  /// 20pt — section padding.
  static const double xl = 20;

  /// 24pt — generous section spacing.
  static const double xxl = 24;

  /// 32pt — page-level spacing.
  static const double xxxl = 32;

  /// 48pt — hero spacing (empty states, splash).
  static const double huge = 48;

  /// Symmetric horizontal page padding (16 left/right).
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: lg);

  /// Symmetric content padding used in list/grid items (16 all).
  static const EdgeInsets card = EdgeInsets.all(lg);

  /// Page-level padding used as the default Scaffold body inset.
  static const EdgeInsets page = EdgeInsets.all(lg);

  /// Comfortable form padding (24 top, 16 horizontal, 24 bottom).
  static const EdgeInsets form = EdgeInsets.fromLTRB(lg, xxl, lg, xxl);

  /// Minimum touch target size per Apple HIG / Material guidelines.
  static const double minTouchTarget = 44;
}
