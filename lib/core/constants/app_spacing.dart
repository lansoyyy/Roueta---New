import 'package:flutter/widgets.dart';

/// App Spacing - Centralized spacing management for the Roueta app
class AppSpacing {
  AppSpacing._();

  // Extra Small Spacing
  static const double xs2 = 2.0;
  static const double xs4 = 4.0;

  // Small Spacing
  static const double sm8 = 8.0;
  static const double sm12 = 12.0;

  // Medium Spacing
  static const double md16 = 16.0;
  static const double md20 = 20.0;
  static const double md24 = 24.0;

  // Large Spacing
  static const double lg32 = 32.0;
  static const double lg40 = 40.0;
  static const double lg48 = 48.0;

  // Extra Large Spacing
  static const double xl64 = 64.0;
  static const double xl80 = 80.0;
  static const double xl96 = 96.0;

  // Special Spacing
  static const double screenPadding = 16.0;
  static const double cardPadding = 16.0;
  static const double buttonPadding = 16.0;
  static const double inputPadding = 16.0;
}

/// Spacing Helper - Helper methods for spacing
class SpacingHelper {
  SpacingHelper._();

  /// Get horizontal spacing
  static SizedBox horizontal(double width) {
    return SizedBox(width: width);
  }

  /// Get vertical spacing
  static SizedBox vertical(double height) {
    return SizedBox(height: height);
  }

  /// Get square spacing
  static SizedBox square(double size) {
    return SizedBox(width: size, height: size);
  }

  // Pre-defined horizontal spacing widgets
  static const SizedBox h2 = SizedBox(width: AppSpacing.xs2);
  static const SizedBox h4 = SizedBox(width: AppSpacing.xs4);
  static const SizedBox h8 = SizedBox(width: AppSpacing.sm8);
  static const SizedBox h12 = SizedBox(width: AppSpacing.sm12);
  static const SizedBox h16 = SizedBox(width: AppSpacing.md16);
  static const SizedBox h20 = SizedBox(width: AppSpacing.md20);
  static const SizedBox h24 = SizedBox(width: AppSpacing.md24);
  static const SizedBox h32 = SizedBox(width: AppSpacing.lg32);
  static const SizedBox h40 = SizedBox(width: AppSpacing.lg40);
  static const SizedBox h48 = SizedBox(width: AppSpacing.lg48);
  static const SizedBox h64 = SizedBox(width: AppSpacing.xl64);
  static const SizedBox h80 = SizedBox(width: AppSpacing.xl80);
  static const SizedBox h96 = SizedBox(width: AppSpacing.xl96);

  // Pre-defined vertical spacing widgets
  static const SizedBox v2 = SizedBox(height: AppSpacing.xs2);
  static const SizedBox v4 = SizedBox(height: AppSpacing.xs4);
  static const SizedBox v8 = SizedBox(height: AppSpacing.sm8);
  static const SizedBox v12 = SizedBox(height: AppSpacing.sm12);
  static const SizedBox v16 = SizedBox(height: AppSpacing.md16);
  static const SizedBox v20 = SizedBox(height: AppSpacing.md20);
  static const SizedBox v24 = SizedBox(height: AppSpacing.md24);
  static const SizedBox v32 = SizedBox(height: AppSpacing.lg32);
  static const SizedBox v40 = SizedBox(height: AppSpacing.lg40);
  static const SizedBox v48 = SizedBox(height: AppSpacing.lg48);
  static const SizedBox v64 = SizedBox(height: AppSpacing.xl64);
  static const SizedBox v80 = SizedBox(height: AppSpacing.xl80);
  static const SizedBox v96 = SizedBox(height: AppSpacing.xl96);
}
