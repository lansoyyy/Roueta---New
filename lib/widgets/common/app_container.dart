import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_spacing.dart';

/// AppContainer - A custom container widget with common styling
class AppContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final DecorationImage? image;
  final BoxShape shape;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;
  final VoidCallback? onTap;
  final bool isClickable;

  const AppContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.image,
    this.shape = BoxShape.rectangle,
    this.alignment,
    this.clipBehavior = Clip.none,
    this.onTap,
    this.isClickable = false,
  });

  const AppContainer.card({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin,
    this.color = AppColors.white,
    this.borderRadius = AppDimensions.cardRadius,
    this.border,
    this.boxShadow,
    this.image,
    this.shape = BoxShape.rectangle,
    this.alignment,
    this.clipBehavior = Clip.none,
    this.onTap,
    this.isClickable = false,
  });

  const AppContainer.rounded({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius = AppDimensions.radiusLG,
    this.border,
    this.boxShadow,
    this.image,
    this.shape = BoxShape.rectangle,
    this.alignment,
    this.clipBehavior = Clip.none,
    this.onTap,
    this.isClickable = false,
  });

  const AppContainer.circle({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.image,
    this.shape = BoxShape.circle,
    this.alignment,
    this.clipBehavior = Clip.none,
    this.onTap,
    this.isClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius ?? 0)
            : null,
        border: border,
        boxShadow: boxShadow,
        image: image,
        shape: shape,
      ),
      alignment: alignment,
      clipBehavior: clipBehavior,
      child: child,
    );

    if (isClickable && onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius ?? 0)
            : null,
        child: container,
      );
    }

    return container;
  }
}

/// AppCard - A pre-styled card widget
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool isClickable;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.onTap,
    this.isClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      margin: margin,
      color: color ?? AppColors.white,
      borderRadius: borderRadius ?? AppDimensions.cardRadius,
      onTap: onTap,
      isClickable: isClickable,
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      child: child,
    );
  }
}
