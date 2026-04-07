import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// App Theme - Centralized theme configuration for the Roueta app
class AppTheme {
  AppTheme._();

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTextStyles.fontFamily,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.textPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.secondaryLight,
        onSecondaryContainer: AppColors.textPrimary,
        tertiary: AppColors.accent,
        onTertiary: AppColors.white,
        error: AppColors.error,
        onError: AppColors.white,
        errorContainer: AppColors.errorLight,
        onErrorContainer: AppColors.textPrimary,
        background: AppColors.background,
        onBackground: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
        outlineVariant: AppColors.gray200,
        shadow: AppColors.shadow,
        scrim: AppColors.overlay,
        inverseSurface: AppColors.gray900,
        onInverseSurface: AppColors.white,
        inversePrimary: AppColors.primaryLight,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.background,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.titleLarge,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.white,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.buttonMedium.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: AppColors.textPrimary,
          textStyle: AppTextStyles.buttonMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.gray100,
        deleteIconColor: AppColors.textSecondary,
        disabledColor: AppColors.gray200,
        selectedColor: AppColors.primaryLight,
        secondarySelectedColor: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: AppTextStyles.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTextStyles.headlineSmall,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.labelMedium,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTextStyles.fontFamily,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.primaryDark,
        onPrimaryContainer: AppColors.white,
        secondary: AppColors.secondaryLight,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.secondaryDark,
        onSecondaryContainer: AppColors.white,
        tertiary: AppColors.accentLight,
        onTertiary: AppColors.white,
        error: AppColors.error,
        onError: AppColors.white,
        errorContainer: AppColors.error,
        onErrorContainer: AppColors.white,
        background: AppColors.gray900,
        onBackground: AppColors.white,
        surface: AppColors.gray800,
        onSurface: AppColors.white,
        outline: AppColors.gray600,
        outlineVariant: AppColors.gray700,
        shadow: AppColors.shadow,
        scrim: AppColors.overlay,
        inverseSurface: AppColors.white,
        onInverseSurface: AppColors.textPrimary,
        inversePrimary: AppColors.primary,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.gray900,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.gray900,
        foregroundColor: AppColors.white,
        iconTheme: IconThemeData(color: AppColors.white),
        titleTextStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 22,
          color: AppColors.white,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.gray800,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.white,
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: AppColors.primaryLight,
          textStyle: AppTextStyles.buttonMedium.copyWith(
            color: AppColors.primaryLight,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: AppColors.gray600, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: AppColors.white,
          textStyle: AppTextStyles.buttonMedium.copyWith(
            color: AppColors.white,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray800,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray700),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: AppColors.white,
        ),
        displayMedium: AppTextStyles.displayMedium.copyWith(
          color: AppColors.white,
        ),
        displaySmall: AppTextStyles.displaySmall.copyWith(
          color: AppColors.white,
        ),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(
          color: AppColors.white,
        ),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.white,
        ),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.white,
        ),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.white),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.white),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: AppColors.white),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.gray100),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray100),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.gray100),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.white),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: AppColors.white),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.white),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: AppColors.white, size: 24),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.gray700,
        thickness: 1,
        space: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.gray700,
        deleteIconColor: AppColors.textSecondary,
        disabledColor: AppColors.gray600,
        selectedColor: AppColors.primaryDark,
        secondarySelectedColor: AppColors.primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.gray800,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.white,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.gray100,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.gray800,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryLight,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.labelMedium,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        indicatorColor: AppColors.primaryLight,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
