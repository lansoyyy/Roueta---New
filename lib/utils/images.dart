import 'package:flutter/material.dart';
import 'assets.dart';

/// Image Utils - Helper utilities for image handling
class ImageUtils {
  ImageUtils._();

  /// Load user image
  static Widget userImage({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Color? color,
    BlendMode? colorBlendMode,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    FilterQuality filterQuality = FilterQuality.low,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return AssetHelper.loadImage(
      AssetPaths.userImage,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      alignment: alignment,
      repeat: repeat,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  /// Create circular avatar from asset
  static Widget circularAvatar(
    String imagePath, {
    double radius = 24,
    Color? backgroundColor,
    Widget? child,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: AssetImage(imagePath),
      child: child,
    );
  }

  /// Create circular avatar from network
  static Widget circularAvatarNetwork(
    String imageUrl, {
    double radius = 24,
    Color? backgroundColor,
    Widget? child,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: NetworkImage(imageUrl),
      child: child,
    );
  }

  /// Create rounded image from asset
  static Widget roundedImage(
    String imagePath, {
    double? width,
    double? height,
    double borderRadius = 12,
    BoxFit fit = BoxFit.cover,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AssetHelper.loadImage(
        imagePath,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }

  /// Create rounded image from network
  static Widget roundedImageNetwork(
    String imageUrl, {
    double? width,
    double? height,
    double borderRadius = 12,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AssetHelper.loadNetworkImage(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
        },
      ),
    );
  }

  /// Create shadowed image container
  static Widget shadowedImage(
    Widget image, {
    double borderRadius = 12,
    double blurRadius = 8,
    Color shadowColor = Colors.black26,
    Offset offset = const Offset(0, 4),
    double spreadRadius = 0,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: blurRadius,
            offset: offset,
            spreadRadius: spreadRadius,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      ),
    );
  }
}
