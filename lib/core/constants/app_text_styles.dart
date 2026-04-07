import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App Text Styles - Centralized text style management for the Roueta app
class AppTextStyles {
  AppTextStyles._();

  // Font Family
  static const String fontFamily = 'Urbanist';

  // Display Styles - Largest text on the screen
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 57,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 45,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 36,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // Headline Styles - High-emphasis headings
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // Title Styles - Medium-emphasis headings
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 22,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  // Body Styles - Body text and buttons
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0.4,
    color: AppColors.textPrimary,
  );

  // Label Styles - Labels on buttons, tabs, etc.
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 11,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  // Button Text Styles
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: 0.5,
    color: AppColors.white,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0.5,
    color: AppColors.white,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    letterSpacing: 0.5,
    color: AppColors.white,
  );

  // Caption Text Styles
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 10,
    letterSpacing: 1.5,
    color: AppColors.textSecondary,
  );

  // Custom Styles for specific use cases
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle h5 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 18,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle h6 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // Helper method to apply color to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  // Helper method to apply weight to any text style
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  // Helper method to apply size to any text style
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  // Helper method to apply multiple properties
  static TextStyle withProperties({
    required TextStyle style,
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    return style.copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }
}
