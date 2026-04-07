import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/bus_route.dart';
import 'firestore_service.dart';

/// Fetches road-following polylines by stitching Directions geometry between
/// consecutive route anchor points.
/// Uses a two-level cache: in-memory → Firestore → Directions API.
class DirectionsService {
  static final DirectionsService _instance = DirectionsService._internal();
  factory DirectionsService() => _instance;
  DirectionsService._internal();

  static const String _apiKey = 'AIzaSyBwByaaKz7j4OGnwPDxeMdmQ4Pa50GA42o';
  static const int _polylineCacheVersion = 100;

  // In-memory cache so we don't re-fetch in the same session.
  final Map<String, List<LatLng>> _memCache = {};

  /// Returns road-following polyline for the given variant.
  /// Priority: memory cache → Firestore cache → Directions API.
  Future<List<LatLng>> getPolylineForVariant(
    String routeId,
    RouteVariant variant,
  ) async {
    final variantId = variant.id;
    final routingSegments = _buildRoutingSegments(variant);
    if (routingSegments.isEmpty) return const <LatLng>[];
    final fallbackPoints = _prepareRoutingPoints(
      variant.polylinePoints.length >= 2
          ? variant.polylinePoints
          : variant.stops.map((stop) => stop.position).toList(growable: false),
    );

    final key = _cacheKey(routeId, variantId);

    // 1. Memory cache
    if (_memCache.containsKey(key)) return _memCache[key]!;

    // 2. Firestore cache
    final cached = await FirestoreService().getCachedPolyline(
      routeId,
      variantId,
      cacheVersion: _polylineCacheVersion,
    );
    if (cached != null && cached.length > 1) {
      _memCache[key] = cached;
      return cached;
    }

    // 3. Directions API
    final routedPoints = await _fetchSegmentDirections(routingSegments);
    final result = routedPoints.isNotEmpty ? routedPoints : fallbackPoints;

    _memCache[key] = result;

    // Cache in Firestore asynchronously (don't await)
    if (result.length > 1) {
      FirestoreService().cachePolyline(
        routeId,
        variantId,
        result,
        cacheVersion: _polylineCacheVersion,
      );
    }

    return result;
  }

  Future<List<LatLng>> _fetchSegmentDirections(
    List<_RoutingSegment> routingSegments,
  ) async {
    try {
      final stitchedPoints = <LatLng>[];

      for (var index = 0; index < routingSegments.length; index++) {
        final segment = routingSegments[index];
        final segmentPoints = await _fetchDirectionsSegment(
          origin: segment.origin,
          destination: segment.destination,
          viaPoints: segment.viaPoints,
        );
        if (segmentPoints.isEmpty) {
          _logRouting(
            'Directions API returned no geometry for segment ${index + 1}/${routingSegments.length}.',
          );
          return [];
        }

        _appendUniquePoints(stitchedPoints, segmentPoints);
      }

      return stitchedPoints;
    } catch (error) {
      _logRouting('Directions segment fetch failed: $error');
      return [];
    }
  }

  Future<List<LatLng>> _fetchDirectionsSegment({
    required LatLng origin,
    required LatLng destination,
    required List<LatLng> viaPoints,
  }) async {
    final response = await http
        .get(
          _buildDirectionsUri(
            origin: origin,
            destination: destination,
            viaPoints: viaPoints,
          ),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      _logRouting(
        'Directions API HTTP ${response.statusCode} for segment ${_pointString(origin)} -> ${_pointString(destination)}.',
      );
      return [];
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status'] as String? ?? '';
    if (status != 'OK') {
      _logRouting(
        'Directions API status $status for segment ${_pointString(origin)} -> ${_pointString(destination)}: ${body['error_message'] ?? 'no details'}',
      );
      return [];
    }

    final routes = body['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      _logRouting('Directions API response had no routes.');
      return [];
    }

    final route = routes.first as Map<String, dynamic>;
    final points = _decodeRouteSteps(route);
    if (points.isNotEmpty) {
      return points;
    }

    final overview =
        (route['overview_polyline'] as Map<String, dynamic>?)?['points']
            as String?;
    if (overview == null || overview.isEmpty) {
      _logRouting('Directions API route had no step or overview polyline.');
      return [];
    }

    return _decodePolyline(overview);
  }

  Uri _buildDirectionsUri({
    required LatLng origin,
    required LatLng destination,
    required List<LatLng> viaPoints,
  }) {
    final params = <String, String>{
      'origin': _pointString(origin),
      'destination': _pointString(destination),
      'mode': 'driving',
      'region': 'ph',
      'alternatives': 'false',
      'avoid': 'ferries',
      'key': _apiKey,
    };

    if (viaPoints.isNotEmpty) {
      params['waypoints'] = viaPoints
          .map((point) => 'via:${_pointString(point)}')
          .join('|');
    }

    return Uri.https('maps.googleapis.com', 'maps/api/directions/json', params);
  }

  List<_RoutingSegment> _buildRoutingSegments(RouteVariant variant) {
    final stopPoints = _prepareRoutingPoints(
      variant.stops.map((stop) => stop.position).toList(growable: false),
    );
    if (stopPoints.length < 2) {
      return const <_RoutingSegment>[];
    }

    final pathPoints = _prepareRoutingPoints(
      variant.polylinePoints.length >= 2 ? variant.polylinePoints : stopPoints,
    );
    final hasManualPath = _hasManualPath(stopPoints, pathPoints);

    if (!hasManualPath) {
      return [
        for (var index = 0; index < stopPoints.length - 1; index++)
          _RoutingSegment(
            origin: stopPoints[index],
            destination: stopPoints[index + 1],
            viaPoints: const <LatLng>[],
          ),
      ];
    }

    final segments = <_RoutingSegment>[];
    var pathIndex = 0;

    for (var stopIndex = 0; stopIndex < stopPoints.length - 1; stopIndex++) {
      final origin = stopPoints[stopIndex];
      final destination = stopPoints[stopIndex + 1];

      while (pathIndex < pathPoints.length &&
          !_isNearPoint(pathPoints[pathIndex], origin)) {
        pathIndex++;
      }
      if (pathIndex < pathPoints.length) {
        pathIndex++;
      }

      final viaPoints = <LatLng>[];
      while (pathIndex < pathPoints.length &&
          !_isNearPoint(pathPoints[pathIndex], destination)) {
        viaPoints.add(pathPoints[pathIndex]);
        pathIndex++;
      }

      segments.add(
        _RoutingSegment(
          origin: origin,
          destination: destination,
          viaPoints: viaPoints,
        ),
      );
    }

    return segments;
  }

  bool _hasManualPath(List<LatLng> stopPoints, List<LatLng> pathPoints) {
    if (stopPoints.length != pathPoints.length) {
      return true;
    }

    for (var index = 0; index < stopPoints.length; index++) {
      if (!_isNearPoint(stopPoints[index], pathPoints[index])) {
        return true;
      }
    }

    return false;
  }

  List<LatLng> _decodeRouteSteps(Map<String, dynamic> route) {
    final decodedPoints = <LatLng>[];
    final legs = route['legs'] as List<dynamic>?;
    if (legs == null) {
      return decodedPoints;
    }

    for (final leg in legs) {
      final steps = (leg as Map<String, dynamic>)['steps'] as List<dynamic>?;
      if (steps == null) {
        continue;
      }

      for (final step in steps) {
        final polyline =
            ((step as Map<String, dynamic>)['polyline']
                    as Map<String, dynamic>?)?['points']
                as String?;
        if (polyline == null || polyline.isEmpty) {
          continue;
        }

        final stepPoints = _decodePolyline(polyline);
        _appendUniquePoints(decodedPoints, stepPoints);
      }
    }

    return decodedPoints;
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var result = 0;
      var shift = 0;
      var value = 0;

      do {
        if (index >= encoded.length) {
          return points;
        }
        value = encoded.codeUnitAt(index++) - 63;
        result |= (value & 0x1f) << shift;
        shift += 5;
      } while (value >= 0x20);

      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      result = 0;
      shift = 0;

      do {
        if (index >= encoded.length) {
          return points;
        }
        value = encoded.codeUnitAt(index++) - 63;
        result |= (value & 0x1f) << shift;
        shift += 5;
      } while (value >= 0x20);

      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  String _pointString(LatLng point) => '${point.latitude},${point.longitude}';

  void _appendUniquePoints(List<LatLng> target, List<LatLng> points) {
    for (final point in points) {
      if (target.isNotEmpty && _distanceMeters(target.last, point) < 1) {
        continue;
      }
      target.add(point);
    }
  }

  List<LatLng> _prepareRoutingPoints(List<LatLng> points) {
    final deduped = <LatLng>[];
    for (final point in points) {
      if (deduped.isNotEmpty && _distanceMeters(deduped.last, point) < 6) {
        continue;
      }
      deduped.add(point);
    }

    return deduped;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const earthRadiusM = 6371000.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);

    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);
    final haversine =
        (sinLat * sinLat) + (math.cos(lat1) * math.cos(lat2) * sinLng * sinLng);
    final arc = 2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
    return earthRadiusM * arc;
  }

  double _toRadians(double value) => value * math.pi / 180;

  bool _isNearPoint(LatLng a, LatLng b) => _distanceMeters(a, b) < 15;

  void _logRouting(String message) {
    debugPrint('DirectionsService: $message');
  }

  String _cacheKey(String routeId, String variantId) {
    return 'v${_polylineCacheVersion}_${routeId}_$variantId';
  }

  void invalidateCache(String routeId, String variantId) {
    _memCache.remove(_cacheKey(routeId, variantId));
  }
}

class _RoutingSegment {
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> viaPoints;

  const _RoutingSegment({
    required this.origin,
    required this.destination,
    required this.viaPoints,
  });
}
