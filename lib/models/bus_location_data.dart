import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'bus_route.dart';

class BusLocationData {
  final String driverBadge;
  final String driverName;
  final String routeId;
  final String variantId;
  final double lat;
  final double lng;
  final int currentStopIndex;
  final bool isActive;
  final OccupancyStatus? occupancyStatus;
  final DateTime? occupancyLastUpdated;
  final DateTime? timestamp;

  const BusLocationData({
    required this.driverBadge,
    required this.driverName,
    required this.routeId,
    required this.variantId,
    required this.lat,
    required this.lng,
    required this.currentStopIndex,
    this.isActive = true,
    this.occupancyStatus,
    this.occupancyLastUpdated,
    this.timestamp,
  });

  LatLng get position => LatLng(lat, lng);

  factory BusLocationData.fromFirestore(Map<String, dynamic> data) {
    final occStr = data['occupancyStatus'] as String?;
    return BusLocationData(
      driverBadge: (data['driverBadge'] as String?) ?? '',
      driverName: (data['driverName'] as String?) ?? 'Driver',
      routeId: (data['routeId'] as String?) ?? '',
      variantId: (data['variantId'] as String?) ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      currentStopIndex: (data['currentStopIndex'] as int?) ?? 0,
      isActive: (data['isActive'] as bool?) ?? false,
      occupancyStatus: occStr == null
          ? null
          : OccupancyStatus.values.firstWhere(
              (status) => status.name == occStr,
              orElse: () => OccupancyStatus.limitedSeats,
            ),
      occupancyLastUpdated: (data['occupancyLastUpdated'] as Timestamp?)
          ?.toDate(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}
