import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'assets.dart';

class MapMarkerIcons {
  MapMarkerIcons._();

  static final Map<String, Future<BitmapDescriptor>> _cache = {};
  static const int _markerWidth = 96;
  static const int _selectedMarkerWidth = 112;
  static const int _compactMarkerWidth = 54;
  static const int _compactSelectedMarkerWidth = 66;
  static const int _busMarkerWidth = 56;
  static const int _compactBusMarkerWidth = 34;

  static Future<BitmapDescriptor> busStop({
    bool selected = false,
    bool compact = false,
  }) {
    return _load(
      cacheKey: 'bus_stop_${selected}_$compact',
      assetPath: AssetPaths.busStopIcon,
      targetWidth: compact
          ? (selected ? _compactSelectedMarkerWidth : _compactMarkerWidth)
          : (selected ? _selectedMarkerWidth : _markerWidth),
    );
  }

  static Future<BitmapDescriptor> bus({
    bool facingRight = true,
    bool compact = false,
  }) {
    return _load(
      cacheKey: 'bus_${facingRight}_$compact',
      assetPath: facingRight ? AssetPaths.busMarkerRight : AssetPaths.busMarkerLeft,
      targetWidth: compact ? _compactBusMarkerWidth : _busMarkerWidth,
    );
  }

  static Future<BitmapDescriptor> startStop({
    bool selected = false,
    bool compact = false,
  }) {
    return _load(
      cacheKey: 'start_stop_${selected}_$compact',
      assetPath: AssetPaths.startingStopIcon,
      targetWidth: compact
          ? (selected ? _compactSelectedMarkerWidth : _compactMarkerWidth)
          : (selected ? _selectedMarkerWidth : _markerWidth),
    );
  }

  static Future<BitmapDescriptor> endStop({
    bool selected = false,
    bool compact = false,
  }) {
    return _load(
      cacheKey: 'end_stop_${selected}_$compact',
      assetPath: AssetPaths.endingStopIcon,
      targetWidth: compact
          ? (selected ? _compactSelectedMarkerWidth : _compactMarkerWidth)
          : (selected ? _selectedMarkerWidth : _markerWidth),
    );
  }

  static Future<BitmapDescriptor> _load({
    required String cacheKey,
    required String assetPath,
    required int targetWidth,
  }) {
    return _cache.putIfAbsent(
      cacheKey,
      () => _descriptorFromAsset(assetPath, targetWidth: targetWidth),
    );
  }

  static Future<BitmapDescriptor> _descriptorFromAsset(
    String assetPath, {
    required int targetWidth,
  }) async {
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: targetWidth,
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return BitmapDescriptor.bytes(Uint8List.view(byteData!.buffer));
    } catch (error) {
      debugPrint('MapMarkerIcons: failed to load $assetPath: $error');
      return BitmapDescriptor.defaultMarker;
    }
  }
}
