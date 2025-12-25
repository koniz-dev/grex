import 'package:flutter/material.dart';

/// Application color scheme
class AppColors {
  AppColors._();

  /// Primary brand color (from logo: Premium Blue)
  static const Color primary = Color(0xFF2563EB);

  /// Darker variant of primary color
  static const Color primaryVariant = Color(0xFF1E40AF);

  /// Secondary accent color (from logo: Emerald Green)
  static const Color secondary = Color(0xFF10B981);

  /// Darker variant of secondary color
  static const Color secondaryVariant = Color(0xFF059669);

  /// Background color for the app
  static const Color background = Color(0xFFF8FAFC);

  /// Surface color for cards and elevated elements
  static const Color surface = Color(0xFFFFFFFF);

  /// Primary text color
  static const Color textPrimary = Color(0xFF212121);

  /// Secondary text color for less important text
  static const Color textSecondary = Color(0xFF757575);

  /// Text color to use on primary colored backgrounds
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Error color for error states
  static const Color error = Color(0xFFB00020);

  /// Lighter variant of error color
  static const Color errorLight = Color(0xFFEF5350);

  /// Success color for success states
  static const Color success = Color(0xFF4CAF50);

  /// Lighter variant of success color
  static const Color successLight = Color(0xFF81C784);

  /// Warning color for warning states
  static const Color warning = Color(0xFFFF9800);

  /// Lighter variant of warning color
  static const Color warningLight = Color(0xFFFFB74D);

  /// Border color for dividers and borders
  static const Color border = Color(0xFFE2E8F0);

  /// Lighter variant of border color
  static const Color borderLight = Color(0xFFF1F5F9);
}
