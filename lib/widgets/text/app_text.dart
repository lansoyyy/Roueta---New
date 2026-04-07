import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_colors.dart';

/// AppText - Custom text widgets that use the Urbanist font
class AppText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;
  final double? letterSpacing;
  final double? height;
  final TextDecoration? decoration;
  final bool softWrap;

  const AppText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontWeight,
    this.fontSize,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.softWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _buildStyle(),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }

  TextStyle _buildStyle() {
    TextStyle baseStyle = style ?? AppTextStyles.bodyMedium;

    // Apply overrides
    if (color != null ||
        fontWeight != null ||
        fontSize != null ||
        letterSpacing != null ||
        height != null ||
        decoration != null) {
      baseStyle = baseStyle.copyWith(
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
        letterSpacing: letterSpacing,
        height: height,
        decoration: decoration,
      );
    }

    return baseStyle;
  }
}

/// Display Text Widgets
class AppDisplayLarge extends AppText {
  const AppDisplayLarge(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.displayLarge);
}

class AppDisplayMedium extends AppText {
  const AppDisplayMedium(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.displayMedium);
}

class AppDisplaySmall extends AppText {
  const AppDisplaySmall(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.displaySmall);
}

/// Headline Text Widgets
class AppHeadlineLarge extends AppText {
  const AppHeadlineLarge(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.headlineLarge);
}

class AppHeadlineMedium extends AppText {
  const AppHeadlineMedium(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.headlineMedium);
}

class AppHeadlineSmall extends AppText {
  const AppHeadlineSmall(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.headlineSmall);
}

/// Title Text Widgets
class AppTitleLarge extends AppText {
  const AppTitleLarge(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.titleLarge);
}

class AppTitleMedium extends AppText {
  const AppTitleMedium(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.titleMedium);
}

class AppTitleSmall extends AppText {
  const AppTitleSmall(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.titleSmall);
}

/// Body Text Widgets
class AppBodyLarge extends AppText {
  const AppBodyLarge(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.bodyLarge);
}

class AppBodyMedium extends AppText {
  const AppBodyMedium(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.bodyMedium);
}

class AppBodySmall extends AppText {
  const AppBodySmall(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.bodySmall);
}

/// Label Text Widgets
class AppLabelLarge extends AppText {
  const AppLabelLarge(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.labelLarge);
}

class AppLabelMedium extends AppText {
  const AppLabelMedium(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.labelMedium);
}

class AppLabelSmall extends AppText {
  const AppLabelSmall(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.labelSmall);
}

/// Button Text Widgets
class AppButtonLarge extends AppText {
  const AppButtonLarge(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.buttonLarge);
}

class AppButtonMedium extends AppText {
  const AppButtonMedium(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.buttonMedium);
}

class AppButtonSmall extends AppText {
  const AppButtonSmall(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.buttonSmall);
}

/// Caption Text Widgets
class AppCaption extends AppText {
  const AppCaption(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.caption);
}

class AppOverline extends AppText {
  const AppOverline(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.overline);
}

/// Heading Widgets (H1-H6)
class AppH1 extends AppText {
  const AppH1(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.h1);
}

class AppH2 extends AppText {
  const AppH2(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.h2);
}

class AppH3 extends AppText {
  const AppH3(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.h3);
}

class AppH4 extends AppText {
  const AppH4(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.h4);
}

class AppH5 extends AppText {
  const AppH5(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.h5);
}

class AppH6 extends AppText {
  const AppH6(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.color,
    super.height,
    super.decoration,
  }) : super(style: AppTextStyles.h6);
}

/// Colored Text Widgets
class AppPrimaryText extends AppText {
  const AppPrimaryText(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.style,
    super.fontWeight,
    super.fontSize,
    super.letterSpacing,
    super.height,
    super.decoration,
  }) : super(color: AppColors.primary);
}

class AppSecondaryText extends AppText {
  const AppSecondaryText(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.style,
    super.fontWeight,
    super.fontSize,
    super.letterSpacing,
    super.height,
    super.decoration,
  }) : super(color: AppColors.textSecondary);
}

class AppTertiaryText extends AppText {
  const AppTertiaryText(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.style,
    super.fontWeight,
    super.fontSize,
    super.letterSpacing,
    super.height,
    super.decoration,
  }) : super(color: AppColors.textTertiary);
}

class AppSuccessText extends AppText {
  const AppSuccessText(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.style,
    super.fontWeight,
    super.fontSize,
    super.letterSpacing,
    super.height,
    super.decoration,
  }) : super(color: AppColors.success);
}

class AppWarningText extends AppText {
  const AppWarningText(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.style,
    super.fontWeight,
    super.fontSize,
    super.letterSpacing,
    super.height,
    super.decoration,
  }) : super(color: AppColors.warning);
}

class AppErrorText extends AppText {
  const AppErrorText(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.style,
    super.fontWeight,
    super.fontSize,
    super.letterSpacing,
    super.height,
    super.decoration,
  }) : super(color: AppColors.error);
}
