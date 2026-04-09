import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/bus_route.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/directions_service.dart';
import '../services/firestore_service.dart';
import '../utils/map_marker_icons.dart';

class ActiveBusScreen extends StatefulWidget {
  final BusRoute route;
  final String? initialVariantId;

  const ActiveBusScreen({
    super.key,
    required this.route,
    this.initialVariantId,
  });

  @override
  State<ActiveBusScreen> createState() => _ActiveBusScreenState();
}

class _ActiveBusScreenState extends State<ActiveBusScreen> {
  static const double _compactMarkerZoomThreshold = 12.0;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  int _currentStopIdx = 0;
  int _minutesToNext = 0;
  Timer? _gpsTimer;
  bool _loadingPolyline = true;
  late String _variantId;
  bool _busLocationSessionStarted = false;
  // Stored so we can clear the Firestore doc in dispose() without needing context.
  String? _driverBadge;
  String? _driverName;

  // Custom marker icons
  BitmapDescriptor? _startIcon;
  BitmapDescriptor? _startSelectedIcon;
  BitmapDescriptor? _endIcon;
  BitmapDescriptor? _endSelectedIcon;
  BitmapDescriptor? _midIcon;
  BitmapDescriptor? _midSelectedIcon;
  BitmapDescriptor? _compactStartIcon;
  BitmapDescriptor? _compactStartSelectedIcon;
  BitmapDescriptor? _compactEndIcon;
  BitmapDescriptor? _compactEndSelectedIcon;
  BitmapDescriptor? _compactMidIcon;
  BitmapDescriptor? _compactMidSelectedIcon;
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _compactBusIcon;
  LatLng? _driverPosition;
  double _currentZoom = 13.5;

  RouteVariant get _variant =>
      widget.route.variantById(_variantId) ?? widget.route.defaultVariant;

  List<BusStop> get _stops => _variant.stops;
  bool get _useCompactMarkers => _currentZoom < _compactMarkerZoomThreshold;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();
    _driverBadge = auth.driverBadge;
    _driverName = auth.driverName;
    _variantId =
        widget.initialVariantId ??
        provider.activeDriverVariantId ??
        widget.route.defaultVariantId;
    widget.route.selectVariant(_variantId);

    // Safety net: clear any stale Firestore doc from a previous session.
    if (_driverBadge != null) {
      FirestoreService().clearBusLocation(_driverBadge!);
    }
    _buildStopMarkers();
    _loadMarkerIcons();
    _fetchRoadPolyline();
    _startGpsTracking();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _mapController?.dispose();
    if (_driverBadge != null) {
      FirestoreService().clearBusLocation(_driverBadge!);
    }
    super.dispose();
  }

  // ── Variant change ────────────────────────────────────────────────────────

  void _changeVariant(String variantId) {
    setState(() {
      _variantId = variantId;
      _currentStopIdx = 0;
      _minutesToNext = 0;
      _loadingPolyline = true;
      widget.route.selectVariant(variantId);
    });
    context.read<AppProvider>().setActiveDriverRoute(
      widget.route,
      variantId: variantId,
      driverBadge: _driverBadge,
      driverName: _driverName,
    );
    _buildStopMarkers();
    _fetchRoadPolyline();
    _reloadBusIcons();
  }

  // ── Stop markers (no polyline — handled separately) ───────────────────────

  Future<void> _loadMarkerIcons() async {
    final start = await MapMarkerIcons.startStop();
    final startSel = await MapMarkerIcons.startStop(selected: true);
    final end = await MapMarkerIcons.endStop();
    final endSel = await MapMarkerIcons.endStop(selected: true);
    final mid = await MapMarkerIcons.busStop();
    final midSel = await MapMarkerIcons.busStop(selected: true);
    final compactStart = await MapMarkerIcons.startStop(compact: true);
    final compactStartSel = await MapMarkerIcons.startStop(
      selected: true,
      compact: true,
    );
    final compactEnd = await MapMarkerIcons.endStop(compact: true);
    final compactEndSel = await MapMarkerIcons.endStop(
      selected: true,
      compact: true,
    );
    final compactMid = await MapMarkerIcons.busStop(compact: true);
    final compactMidSel = await MapMarkerIcons.busStop(
      selected: true,
      compact: true,
    );
    final facingRight = !_variantId.contains('_in');
    final busIcon = await MapMarkerIcons.bus(facingRight: facingRight);
    final compactBusIcon = await MapMarkerIcons.bus(
      facingRight: facingRight,
      compact: true,
    );
    if (!mounted) return;
    _startIcon = start;
    _startSelectedIcon = startSel;
    _endIcon = end;
    _endSelectedIcon = endSel;
    _midIcon = mid;
    _midSelectedIcon = midSel;
    _compactStartIcon = compactStart;
    _compactStartSelectedIcon = compactStartSel;
    _compactEndIcon = compactEnd;
    _compactEndSelectedIcon = compactEndSel;
    _compactMidIcon = compactMid;
    _compactMidSelectedIcon = compactMidSel;
    _busIcon = busIcon;
    _compactBusIcon = compactBusIcon;
    // Rebuild markers now that real icons are available.
    _buildStopMarkers();
  }

  Future<void> _reloadBusIcons() async {
    final facingRight = !_variantId.contains('_in');
    final icon = await MapMarkerIcons.bus(facingRight: facingRight);
    final compact = await MapMarkerIcons.bus(
      facingRight: facingRight,
      compact: true,
    );
    if (!mounted) return;
    _busIcon = icon;
    _compactBusIcon = compact;
    _buildStopMarkers();
  }

  void _handleCameraMove(CameraPosition position) {
    final shouldUseCompact = position.zoom < _compactMarkerZoomThreshold;
    final wasCompact = _useCompactMarkers;
    _currentZoom = position.zoom;
    if (shouldUseCompact != wasCompact) {
      _refreshStopMarkers(_currentStopIdx);
    }
  }

  // Returns a computed marker set — shared between _buildStopMarkers and
  // _refreshStopMarkers to avoid duplicated icon-selection logic.
  Set<Marker> _computeMarkers(int activeIdx) {
    if (_stops.isEmpty) return {};
    final markers = <Marker>{};
    for (int i = 0; i < _stops.length; i++) {
      final stop = _stops[i];
      final bool isCurrent = i == activeIdx;
      final BitmapDescriptor icon;
      if (i == 0) {
        icon = isCurrent
            ? ((_useCompactMarkers
                      ? _compactStartSelectedIcon
                      : _startSelectedIcon) ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ))
            : ((_useCompactMarkers ? _compactStartIcon : _startIcon) ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ));
      } else if (i == _stops.length - 1) {
        icon = isCurrent
            ? ((_useCompactMarkers
                      ? _compactEndSelectedIcon
                      : _endSelectedIcon) ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ))
            : ((_useCompactMarkers ? _compactEndIcon : _endIcon) ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ));
      } else {
        icon = isCurrent
            ? ((_useCompactMarkers
                      ? _compactMidSelectedIcon
                      : _midSelectedIcon) ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ))
            : ((_useCompactMarkers ? _compactMidIcon : _midIcon) ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueCyan,
                  ));
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
    // Driver's own bus position marker.
    if (_driverPosition != null) {
      final driverBusIcon =
          (_useCompactMarkers ? _compactBusIcon : _busIcon) ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      markers.add(
        Marker(
          markerId: const MarkerId('_driver_bus'),
          position: _driverPosition!,
          icon: driverBusIcon,
          anchor: const Offset(0.5, 0.5),
          zIndex: 5,
        ),
      );
    }
    return markers;
  }

  void _buildStopMarkers() {
    setState(() => _markers = _computeMarkers(_currentStopIdx));
  }

  // ── Road-following polyline ───────────────────────────────────────────────

  Future<void> _fetchRoadPolyline() async {
    setState(() {
      _loadingPolyline = true;
      _polylines = {};
    });
    final fetchedPoints = await DirectionsService().getPolylineForVariant(
      widget.route.id,
      _variant,
    );
    if (!mounted) return;
    setState(() {
      _polylines = fetchedPoints.length >= 2
          ? {
              Polyline(
                polylineId: PolylineId('${widget.route.id}_$_variantId'),
                points: fetchedPoints,
                color: AppColors.primaryDark,
                width: 5,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            }
          : {};
      _loadingPolyline = false;
    });
  }

  // ── GPS tracking → Firestore ──────────────────────────────────────────────

  void _startGpsTracking() {
    // Show the last cached position immediately so the icon appears right away.
    Geolocator.getLastKnownPosition().then((lastPos) {
      if (lastPos == null || !mounted) return;
      final busPos = LatLng(lastPos.latitude, lastPos.longitude);
      setState(() => _driverPosition = busPos);
      _buildStopMarkers();
      _publishBusLocation(
        lat: lastPos.latitude,
        lng: lastPos.longitude,
        currentStopIndex: _currentStopIdx,
      );
    });
    // Immediate first accurate update.
    _updateGps();
    // Then every 10 seconds.
    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _updateGps();
    });
  }

  Future<void> _updateGps() async {
    try {
      final settings = context.read<SettingsProvider>();
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: settings.locationAccuracy,
      );
      final busPos = LatLng(pos.latitude, pos.longitude);
      final stopIdx = _nearestStopIndex(busPos);
      final mins = _minsToNextStop(busPos, stopIdx);

      if (mounted) {
        setState(() {
          _currentStopIdx = stopIdx;
          _minutesToNext = mins;
          _driverPosition = busPos;
        });
        context.read<AppProvider>().updateActiveStopProgress(stopIdx);
        _refreshStopMarkers(stopIdx);
      }

      // Push to Firestore
      _publishBusLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        currentStopIndex: stopIdx,
      );
    } catch (_) {
      // Location permission not granted or service unavailable — ignore.
    }
  }

  Future<void> _publishBusLocation({
    required double lat,
    required double lng,
    required int currentStopIndex,
  }) async {
    if (_driverBadge == null) return;

    final service = FirestoreService();
    if (!_busLocationSessionStarted) {
      final activated = await service.activateBusLocation(
        driverBadge: _driverBadge!,
        driverName: _driverName ?? 'Driver',
        routeId: widget.route.id,
        variantId: _variantId,
        lat: lat,
        lng: lng,
        currentStopIndex: currentStopIndex,
      );
      if (activated) {
        _busLocationSessionStarted = true;
        return;
      }
    }

    await service.updateBusLocation(
      driverBadge: _driverBadge!,
      driverName: _driverName ?? 'Driver',
      routeId: widget.route.id,
      variantId: _variantId,
      lat: lat,
      lng: lng,
      currentStopIndex: currentStopIndex,
    );
  }

  // Rebuild just the markers when active stop changes (avoids full polyline rebuild).
  void _refreshStopMarkers(int activeIdx) {
    if (!mounted) return;
    setState(() => _markers = _computeMarkers(activeIdx));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _nearestStopIndex(LatLng pos) {
    if (_stops.isEmpty) return 0;
    double minDist = double.infinity;
    int nearest = 0;
    for (int i = 0; i < _stops.length; i++) {
      final d = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        _stops[i].position.latitude,
        _stops[i].position.longitude,
      );
      if (d < minDist) {
        minDist = d;
        nearest = i;
      }
    }
    return nearest;
  }

  int _minsToNextStop(LatLng busPos, int currentIdx) {
    final nextIdx = (currentIdx + 1).clamp(0, _stops.length - 1);
    if (nextIdx == currentIdx) return 0;
    final distM = Geolocator.distanceBetween(
      busPos.latitude,
      busPos.longitude,
      _stops[nextIdx].position.latitude,
      _stops[nextIdx].position.longitude,
    );
    // 15 km/h ≈ 250 m/min
    return (distM / 250).ceil().clamp(1, 99);
  }

  BusStop? get _nextStop {
    if (_stops.isEmpty) return null;
    if (_currentStopIdx + 1 < _stops.length) {
      return _stops[_currentStopIdx + 1];
    }
    return _stops.last;
  }

  void _confirmEndRoute() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Route?'),
        content: const Text(
          'This will stop GPS tracking and mark your trip as completed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusUnavailable,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Route'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) Navigator.pop(context);
    });
  }

  LatLng get _mapCenter {
    if (_stops.isEmpty) return const LatLng(7.0644, 125.5214);
    double lat = 0;
    double lng = 0;
    for (final s in _stops) {
      lat += s.position.latitude;
      lng += s.position.longitude;
    }
    return LatLng(lat / _stops.length, lng / _stops.length);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 4,
              bottom: 10,
              left: 12,
              right: 12,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(child: _SearchBar()),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Text(
              'THE BUS YOU ARE OPERATING',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.route.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.route.code,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusOperating,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Operating',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) _changeVariant(value);
                  },
                  decoration: InputDecoration(
                    labelText: 'Operating Variant',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _mapCenter,
                    zoom: 13.5,
                  ),
                  onMapCreated: (ctrl) => _mapController = ctrl,
                  onCameraMove: _handleCameraMove,
                  mapType: settings.googleMapType,
                  trafficEnabled: settings.showTraffic,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: provider.locationPermissionGranted,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                if (_loadingPolyline)
                  const Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(child: _PolylineLoadingBadge()),
                  ),
                Positioned(
                  bottom: 16,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.route.code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _minutesToNext > 0
                                ? 'Approaching ${_nextStop?.name ?? "Next Stop"} in $_minutesToNext min'
                                : 'At stop: ${_stops.isNotEmpty ? _stops[_currentStopIdx].name : "—"}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              // Respect the home-indicator safe area — there is no
              // bottomNavigationBar to handle it automatically.
              4 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmEndRoute,
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: const Text(
                      'End Route',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusUnavailable,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'UPDATE OCCUPANCY STATUS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                if (provider.driverOccupancy != null) ...[
                  _OccupancyDisplay(status: provider.driverOccupancy!),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _OccupancyBtn(
                        label: 'Seat Available',
                        sublabel: '~33%',
                        color: AppColors.statusOperating,
                        isSelected:
                            provider.driverOccupancy ==
                            OccupancyStatus.seatAvailable,
                        onTap: () => provider.updateOccupancy(
                          OccupancyStatus.seatAvailable,
                          driverBadge: _driverBadge,
                          routeId: widget.route.id,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _OccupancyBtn(
                        label: 'Limited Seats',
                        sublabel: '~67%',
                        color: AppColors.accent,
                        isSelected:
                            provider.driverOccupancy ==
                            OccupancyStatus.limitedSeats,
                        onTap: () => provider.updateOccupancy(
                          OccupancyStatus.limitedSeats,
                          driverBadge: _driverBadge,
                          routeId: widget.route.id,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _OccupancyBtn(
                        label: 'Full Capacity',
                        sublabel: '~95%',
                        color: AppColors.statusUnavailable,
                        isSelected:
                            provider.driverOccupancy ==
                            OccupancyStatus.fullCapacity,
                        onTap: () => provider.updateOccupancy(
                          OccupancyStatus.fullCapacity,
                          driverBadge: _driverBadge,
                          routeId: widget.route.id,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
    // No bottomNavigationBar — the back arrow in the header ends the active
    // session by popping this route, which triggers stopDriverRoute in the caller.
  }
}

class _OccupancyDisplay extends StatelessWidget {
  final OccupancyStatus status;
  const _OccupancyDisplay({required this.status});

  double get _percentage {
    switch (status) {
      case OccupancyStatus.seatAvailable:
        return 0.33;
      case OccupancyStatus.limitedSeats:
        return 0.67;
      case OccupancyStatus.fullCapacity:
        return 0.95;
    }
  }

  Color get _barColor {
    switch (status) {
      case OccupancyStatus.seatAvailable:
        return AppColors.statusOperating;
      case OccupancyStatus.limitedSeats:
        return AppColors.accent;
      case OccupancyStatus.fullCapacity:
        return AppColors.statusUnavailable;
    }
  }

  String get _label {
    switch (status) {
      case OccupancyStatus.seatAvailable:
        return 'Seats Available';
      case OccupancyStatus.limitedSeats:
        return 'Limited Seats';
      case OccupancyStatus.fullCapacity:
        return 'Full Capacity';
    }
  }

  bool get _isStandingOnly => _percentage >= 0.9;

  @override
  Widget build(BuildContext context) {
    final pct = (_percentage * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isStandingOnly)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.statusUnavailable,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'STANDING ONLY — Bus is at full capacity',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Text(
              '$pct%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: _barColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _percentage,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OccupancyBtn extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _OccupancyBtn({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              sublabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.85)
                    : color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          SizedBox(width: 12),
          Icon(Icons.search, color: Colors.white70, size: 18),
          SizedBox(width: 6),
          Text(
            'SEARCH',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolylineLoadingBadge extends StatelessWidget {
  const _PolylineLoadingBadge();

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
