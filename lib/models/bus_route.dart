import 'package:google_maps_flutter/google_maps_flutter.dart';

enum RouteStatus { operating, onStandby, unavailable }

enum OccupancyStatus { seatAvailable, limitedSeats, fullCapacity }

enum RouteShift { am, pm }

enum RouteDirection { outbound, inbound }

class BusStop {
  final String id;
  final String name;
  final LatLng position;
  final int? estimatedMinutesFromStart;

  const BusStop({
    required this.id,
    required this.name,
    required this.position,
    this.estimatedMinutesFromStart,
  });
}

class RouteVariant {
  final String id;
  final String label;
  final RouteShift shift;
  final RouteDirection direction;
  final List<BusStop> stops;
  final List<LatLng> polylinePoints;

  const RouteVariant({
    required this.id,
    required this.label,
    required this.shift,
    required this.direction,
    required this.stops,
    required this.polylinePoints,
  });

  String get shortLabel {
    final shiftText = shift == RouteShift.am ? 'AM' : 'PM';
    final dirText = direction == RouteDirection.outbound
        ? 'Outbound'
        : 'Inbound';
    return '$shiftText • $dirText';
  }
}

class BusRoute {
  final String id;
  final String name;
  final String code;
  final String origin;
  final String destination;
  final String amStartTime;
  final String amEndTime;
  final String pmStartTime;
  final String pmEndTime;
  final Map<String, RouteVariant> variants;
  final String defaultVariantId;
  String? _selectedVariantId;
  RouteStatus status;
  OccupancyStatus? occupancyStatus;
  DateTime? occupancyLastUpdated;
  int currentStopIndex;

  BusRoute({
    required this.id,
    required this.name,
    required this.code,
    required this.origin,
    required this.destination,
    required this.amStartTime,
    required this.amEndTime,
    required this.pmStartTime,
    required this.pmEndTime,
    required this.variants,
    required this.defaultVariantId,
    this.status = RouteStatus.onStandby,
    this.occupancyStatus,
    this.occupancyLastUpdated,
    this.currentStopIndex = 0,
  }) : _selectedVariantId = defaultVariantId;

  RouteVariant get defaultVariant =>
      variants[defaultVariantId] ?? variants.values.first;

  String get selectedVariantId => _selectedVariantId ?? defaultVariantId;

  RouteVariant get selectedVariant =>
      variants[selectedVariantId] ?? defaultVariant;

  List<RouteVariant> get orderedVariants => variants.values.toList();

  RouteVariant? variantById(String id) => variants[id];

  void selectVariant(String? variantId) {
    if (variantId != null && variants.containsKey(variantId)) {
      _selectedVariantId = variantId;
    } else {
      _selectedVariantId = defaultVariantId;
    }
  }

  // Compatibility getters to avoid breaking existing screen code.
  List<BusStop> get stops => selectedVariant.stops;

  List<LatLng> get polylinePoints => selectedVariant.polylinePoints;

  List<String> get allStopNames => {
    for (final v in variants.values) ...v.stops.map((s) => s.name),
  }.toList(growable: false);

  LatLng get startPosition => stops.first.position;
  LatLng get endPosition => stops.last.position;

  BusStop? get currentStop => stops.isNotEmpty ? stops[currentStopIndex] : null;

  BusStop? get nextStop =>
      currentStopIndex + 1 < stops.length ? stops[currentStopIndex + 1] : null;
}
