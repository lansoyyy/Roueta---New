import 'package:flutter/material.dart';

/// App Colors - Centralized color management for the Roueta app
class AppColors {
  AppColors._();

  // Primary Colors - Teal palette matching RouETA brand
  static const Color primary = Color(0xFF00BCD4);
  static const Color primaryDark = Color(0xFF00838F);
  static const Color primaryLight = Color(0xFF4DD0E1);
  static const Color primaryVeryLight = Color(0xFFE0F7FA);

  // Secondary Colors
  static const Color secondary = Color(0xFF26C6DA);
  static const Color secondaryDark = Color(0xFF00ACC1);
  static const Color secondaryLight = Color(0xFF80DEEA);

  // Accent Colors
  static const Color accent = Color(0xFFFFB300);
  static const Color accentDark = Color(0xFFFF8F00);
  static const Color accentLight = Color(0xFFFFD54F);

  // Status Colors
  static const Color statusOperating = Color(0xFF4CAF50);
  static const Color statusStandby = Color(0xFF9E9E9E);
  static const Color statusUnavailable = Color(0xFFE53935);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFFF3F4F6);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF4DD0E1),
    Color(0xFF00838F),
  ];

  static const List<Color> splashGradient = [
    Color(0xFF26C6DA),
    Color(0xFF00ACC1),
    Color(0xFF00838F),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF80DEEA),
    Color(0xFF26C6DA),
  ];

  // Overlay Colors
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
}
