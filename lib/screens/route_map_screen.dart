import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/bus_location_data.dart';
import '../models/bus_route.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../services/directions_service.dart';
import '../services/notification_service.dart';
import '../utils/map_marker_icons.dart';

class RouteMapScreen extends StatefulWidget {
  final BusRoute route;
  final String? initialVariantId;

  const RouteMapScreen({super.key, required this.route, this.initialVariantId});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  static const double _compactMarkerZoomThreshold = 12.0;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _loadingPolyline = true;

  // ETA state
  BusStop? _nextStop;
  int _etaMinutes = 0;
  bool _notificationSent = false;
  Timer? _etaTimer;

  // Custom marker icons
  BitmapDescriptor? _startIcon;
  BitmapDescriptor? _endIcon;
  BitmapDescriptor? _midIcon;
  BitmapDescriptor? _compactStartIcon;
  BitmapDescriptor? _compactEndIcon;
  BitmapDescriptor? _compactMidIcon;
  double _currentZoom = 13.5;

  late String _variantId;

  RouteVariant get _variant =>
      widget.route.variantById(_variantId) ?? widget.route.defaultVariant;
  List<BusStop> get _stops => _variant.stops;
  bool get _useCompactMarkers => _currentZoom < _compactMarkerZoomThreshold;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _variantId =
        widget.initialVariantId ??
        provider.selectedVariantId ??
        widget.route.defaultVariantId;
    widget.route.selectVariant(_variantId);

    _buildStopMarkers();
    _loadMarkerIcons();
    _fetchRoadPolyline();

    // ETA refresh every 5 s
    _etaTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _refreshEta();
    });
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Polyline ──────────────────────────────────────────────────────────────

  Future<void> _fetchRoadPolyline() async {
    final previewPoints = _stops
        .map((stop) => stop.position)
        .toList(growable: false);
    setState(() {
      _loadingPolyline = true;
      if (previewPoints.length >= 2) {
        _polylines = {
          Polyline(
            polylineId: PolylineId('${widget.route.id}_${_variantId}_preview'),
            points: previewPoints,
            color: const Color(0xFF3F51B5),
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        };
      }
    });
    final fetchedPoints = await DirectionsService().getPolylineForVariant(
      widget.route.id,
      _variant,
    );
    final points = fetchedPoints.length >= 2
        ? fetchedPoints
        : _stops.map((stop) => stop.position).toList(growable: false);
    if (!mounted) return;
    final polyline = Polyline(
      polylineId: PolylineId('${widget.route.id}_$_variantId'),
      points: points,
      color: const Color(0xFF3F51B5),
      width: 5,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
    setState(() {
      _polylines = {polyline};
      _loadingPolyline = false;
    });
    _refreshEta();
  }

  Future<void> _loadMarkerIcons() async {
    final start = await MapMarkerIcons.startStop();
    final end = await MapMarkerIcons.endStop();
    final mid = await MapMarkerIcons.busStop();
    final compactStart = await MapMarkerIcons.startStop(compact: true);
    final compactEnd = await MapMarkerIcons.endStop(compact: true);
    final compactMid = await MapMarkerIcons.busStop(compact: true);
    if (!mounted) return;
    _startIcon = start;
    _endIcon = end;
    _midIcon = mid;
    _compactStartIcon = compactStart;
    _compactEndIcon = compactEnd;
    _compactMidIcon = compactMid;
    _buildStopMarkers();
  }

  void _handleCameraMove(CameraPosition position) {
    final shouldUseCompact = position.zoom < _compactMarkerZoomThreshold;
    final wasCompact = _useCompactMarkers;
    _currentZoom = position.zoom;
    if (shouldUseCompact != wasCompact) {
      _buildStopMarkers();
    }
  }

  void _buildStopMarkers() {
    if (_stops.isEmpty) return;
    final markers = <Marker>{};
    for (int i = 0; i < _stops.length; i++) {
      final stop = _stops[i];
      final BitmapDescriptor icon;
      if (i == 0) {
        icon =
            (_useCompactMarkers ? _compactStartIcon : _startIcon) ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      } else if (i == _stops.length - 1) {
        icon =
            (_useCompactMarkers ? _compactEndIcon : _endIcon) ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      } else {
        icon =
            (_useCompactMarkers ? _compactMidIcon : _midIcon) ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      }
      markers.add(
        Marker(
          markerId: MarkerId(stop.id),
          position: stop.position,
          icon: icon,
          anchor: const Offset(0.5, 1.0),
          infoWindow: InfoWindow(title: stop.name),
        ),
      );
    }
    if (mounted) {
      setState(() => _markers = markers);
    } else {
      _markers = markers;
    }
  }

  // ── Bus markers from Firestore ────────────────────────────────────────────

  Set<Marker> _buildAllMarkers(List<BusLocationData> buses) {
    final m = <Marker>{..._markers};
    for (final bus in buses) {
      m.add(
        Marker(
          markerId: MarkerId('bus_${bus.driverBadge}'),
          position: bus.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          anchor: const Offset(0.5, 1.0),
          zIndexInt: 4,
          infoWindow: InfoWindow(
            title: bus.driverBadge,
            snippet: 'Stop ${bus.currentStopIndex + 1} of ${_stops.length}',
          ),
        ),
      );
    }
    return m;
  }

  // ── ETA calculation ───────────────────────────────────────────────────────

  void _refreshEta() {
    final provider = context.read<AppProvider>();
    final buses = provider.getBusLocationsForRoute(widget.route.id);

    // Filter to buses on current variant for best accuracy.
    final variantBuses = buses.where((b) => b.variantId == _variantId).toList();
    final allBuses = variantBuses.isNotEmpty ? variantBuses : buses;

    if (allBuses.isEmpty || _stops.isEmpty) {
      setState(() {
        _nextStop = _stops.isNotEmpty ? _stops.first : null;
        _etaMinutes = 0;
      });
      return;
    }

    // Pick the bus that is farthest along the route (highest stop index).
    final bus = allBuses.reduce(
      (a, b) => a.currentStopIndex >= b.currentStopIndex ? a : b,
    );

    final busStopIdx = bus.currentStopIndex.clamp(0, _stops.length - 1);
    final nextStopIdx = (busStopIdx + 1).clamp(0, _stops.length - 1);
    final next = _stops[nextStopIdx];

    // ETA to the next stop: distance / avg speed (15 km/h = 250 m/min).
    final distanceM = Geolocator.distanceBetween(
      bus.lat,
      bus.lng,
      next.position.latitude,
      next.position.longitude,
    );
    final minsToNext = math.max(1, (distanceM / 250).ceil());

    if (minsToNext <= 2 && !_notificationSent) {
      _notificationSent = true;
      NotificationService().showBusApproachingNotification(
        stopName: next.name,
        minutesAway: minsToNext,
      );
      provider.addBusApproachingNotification(
        routeCode: widget.route.code,
        stopName: next.name,
        minutesAway: minsToNext,
      );
    }
    if (minsToNext > 2) _notificationSent = false;

    setState(() {
      _nextStop = next;
      _etaMinutes = minsToNext;
    });
  }

  // ── Variant change ────────────────────────────────────────────────────────

  void _changeVariant(String newVariantId) {
    setState(() {
      _variantId = newVariantId;
      _loadingPolyline = true;
      _nextStop = null;
      _etaMinutes = 0;
      _notificationSent = false;
      widget.route.selectVariant(newVariantId);
    });
    context.read<AppProvider>().selectRoute(
      widget.route,
      variantId: newVariantId,
    );
    _buildStopMarkers();
    _fetchRoadPolyline();
  }

  // ── Map helpers ───────────────────────────────────────────────────────────

  LatLng get _mapCenter {
    if (_stops.isEmpty) return const LatLng(7.0644, 125.5214);
    double lat = 0, lng = 0;
    for (final s in _stops) {
      lat += s.position.latitude;
      lng += s.position.longitude;
    }
    return LatLng(lat / _stops.length, lng / _stops.length);
  }

  // ── Occupancy helpers ─────────────────────────────────────────────────────

  OccupancyStatus? get _occupancy => widget.route.occupancyStatus;

  String get _occupancyLabel {
    switch (_occupancy) {
      case OccupancyStatus.seatAvailable:
        return 'Seats Available';
      case OccupancyStatus.limitedSeats:
        return 'Limited Seats';
      case OccupancyStatus.fullCapacity:
        return 'Full Capacity';
      case null:
        return 'No live occupancy yet';
    }
  }

  Color get _occupancyColor {
    switch (_occupancy) {
      case OccupancyStatus.seatAvailable:
        return AppColors.statusOperating;
      case OccupancyStatus.limitedSeats:
        return AppColors.accent;
      case OccupancyStatus.fullCapacity:
        return AppColors.statusUnavailable;
      case null:
        return AppColors.gray400;
    }
  }

  int get _staleMinutes => widget.route.occupancyLastUpdated == null
      ? 0
      : DateTime.now().difference(widget.route.occupancyLastUpdated!).inMinutes;

  bool get _isStale =>
      widget.route.occupancyLastUpdated != null && _staleMinutes >= 5;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final settings = context.watch<SettingsProvider>();
    final buses = provider.getBusLocationsForRoute(widget.route.id);
    final allMarkers = _buildAllMarkers(buses);

    return Scaffold(
      body: Column(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  key: const ValueKey('route_map'),
                  initialCameraPosition: CameraPosition(
                    target: _mapCenter,
                    zoom: 13.5,
                  ),
                  onMapCreated: (ctrl) => _mapController = ctrl,
                  onCameraMove: _handleCameraMove,
                  mapType: settings.googleMapType,
                  trafficEnabled: settings.showTraffic,
                  markers: allMarkers,
                  polylines: _polylines,
                  myLocationEnabled: provider.locationPermissionGranted,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  buildingsEnabled: true,
                  compassEnabled: false,
                ),
                if (_loadingPolyline)
                  const Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(child: _RouteLoadingBadge()),
                  ),
                // My location button
                if (provider.locationPermissionGranted)
                  Positioned(
                    bottom: 16,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLng(provider.currentLatLng),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                // Active bus count
                if (buses.isNotEmpty)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_bus,
                            color: AppColors.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${buses.length} on route',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Bottom panel ─────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.route.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryVeryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.route.code,
                                  style: TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_stops.length} stops',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _variantId,
                  isDense: true,
                  items: widget.route.orderedVariants
                      .map(
                        (v) => DropdownMenuItem(
                          value: v.id,
                          child: Text(v.shortLabel),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _changeVariant(v);
                  },
                  decoration: InputDecoration(
                    labelText: 'Trip Variant',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ETA row
                if (buses.isEmpty)
                  Text(
                    'No active bus on this route',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (_nextStop != null)
                  Row(
                    children: [
                      Icon(
                        Icons.directions_bus,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Bus approaching ${_nextStop!.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_etaMinutes min',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 8),

                // Occupancy row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _occupancyColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _occupancyLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isStale)
                      Text(
                        'Last updated $_staleMinutes min ago',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      )
                    else if (widget.route.occupancyLastUpdated != null)
                      Text(
                        'Just updated',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteLoadingBadge extends StatelessWidget {
  const _RouteLoadingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading road route…',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
