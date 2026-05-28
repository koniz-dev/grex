import 'package:flutter/material.dart';
import 'package:grex/shared/theme/app_fonts.dart';

/// Application text styles
class AppTextStyles {
  AppTextStyles._();

  /// Heading 1 style - largest heading
  static const TextStyle h1 = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  /// Heading 2 style - second largest heading
  static const TextStyle h2 = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  /// Heading 3 style - medium heading
  static const TextStyle h3 = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  /// Heading 4 style - small heading
  static const TextStyle h4 = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
  );

  /// Body large text style
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
  );

  /// Body medium text style
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
  );

  /// Body small text style
  static const TextStyle bodySmall = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
  );

  /// Button text style
  static const TextStyle button = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.25,
  );

  /// Caption text style for small labels
  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
  );

  /// Overline text style for very small labels
  static const TextStyle overline = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 10,
    fontWeight: FontWeight.normal,
    letterSpacing: 1.5,
  );
}
