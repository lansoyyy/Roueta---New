import 'package:flutter/material.dart';

/// Asset Paths - Centralized asset path management for the Roueta app
class AssetPaths {
  AssetPaths._();

  // Images Directory
  static const String imagesDir = 'assets/images/';

  // Fonts Directory
  static const String fontsDir = 'assets/fonts/';

  // Images
  static const String appLogo = '${imagesDir}logo.png';
  static const String newLogo = '${imagesDir}NEW LOGO.png';
  static const String startingStopIcon = '${imagesDir}STARTING STOP ICON.PNG';
  static const String endingStopIcon = '${imagesDir}ENDING STOP ICON.PNG';
  static const String busStopIcon = '${imagesDir}BUS STOPS ICON.PNG';
  static const String busMarkerLeft = '${imagesDir}bus marker left.png';
  static const String busMarkerRight = '${imagesDir}bus marker right.png';
  static const String userImage = '${imagesDir}user (1).png';

  // Fonts
  static const String urbanistRegular = '${fontsDir}Urbanist-Regular.ttf';
  static const String urbanistMedium = '${fontsDir}Urbanist-Medium.ttf';
  static const String urbanistBold = '${fontsDir}Urbanist-Bold.ttf';
}

/// Asset Helper - Helper methods for loading assets
class AssetHelper {
  AssetHelper._();

  /// Load image from assets
  static Image loadImage(
    String path, {
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
    return Image.asset(
      path,
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

  /// Load network image
  static Image loadNetworkImage(
    String url, {
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
    ImageErrorWidgetBuilder? errorBuilder,
    ImageFrameBuilder? frameBuilder,
    ImageLoadingBuilder? loadingBuilder,
  }) {
    return Image.network(
      url,
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
      errorBuilder: errorBuilder,
      frameBuilder: frameBuilder,
      loadingBuilder: loadingBuilder,
    );
  }

  /// Get image provider from assets
  static AssetImage getAssetImageProvider(String path) {
    return AssetImage(path);
  }

  /// Get image provider from network
  static NetworkImage getNetworkImageProvider(String url) {
    return NetworkImage(url);
  }
}
