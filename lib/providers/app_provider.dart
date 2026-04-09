import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';
import '../models/bus_location_data.dart';
import '../models/bus_route.dart';
import '../data/routes_data.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

enum UserMode { passenger, driver }

class RecentRouteEntry {
  final String routeId;
  final String routeCode;
  final String routeName;
  final String variantId;
  final String variantLabel;
  final DateTime viewedAt;

  const RecentRouteEntry({
    required this.routeId,
    required this.routeCode,
    required this.routeName,
    required this.variantId,
    required this.variantLabel,
    required this.viewedAt,
  });

  Map<String, dynamic> toJson() => {
    'routeId': routeId,
    'routeCode': routeCode,
    'routeName': routeName,
    'variantId': variantId,
    'variantLabel': variantLabel,
    'viewedAt': viewedAt.toIso8601String(),
  };

  static RecentRouteEntry fromJson(Map<String, dynamic> json) =>
      RecentRouteEntry(
        routeId: json['routeId'] as String,
        routeCode: json['routeCode'] as String,
        routeName: json['routeName'] as String,
        variantId: json['variantId'] as String,
        variantLabel: json['variantLabel'] as String,
        viewedAt: DateTime.parse(json['viewedAt'] as String),
      );
}

class DriverTripRecord {
  final String routeId;
  final String routeCode;
  final String routeName;
  final String variantId;
  final String variantLabel;
  final DateTime startedAt;
  final DateTime endedAt;
  final int stopsCompleted;
  final int totalStops;
  final OccupancyStatus? peakOccupancy;

  const DriverTripRecord({
    required this.routeId,
    required this.routeCode,
    required this.routeName,
    required this.variantId,
    required this.variantLabel,
    required this.startedAt,
    required this.endedAt,
    required this.stopsCompleted,
    required this.totalStops,
    required this.peakOccupancy,
  });

  Map<String, dynamic> toJson() => {
    'routeId': routeId,
    'routeCode': routeCode,
    'routeName': routeName,
    'variantId': variantId,
    'variantLabel': variantLabel,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'stopsCompleted': stopsCompleted,
    'totalStops': totalStops,
    'peakOccupancy': peakOccupancy?.name,
  };

  static DriverTripRecord fromJson(Map<String, dynamic> json) {
    final occ = json['peakOccupancy'] as String?;
    return DriverTripRecord(
      routeId: json['routeId'] as String,
      routeCode: json['routeCode'] as String,
      routeName: json['routeName'] as String,
      variantId: json['variantId'] as String,
      variantLabel: json['variantLabel'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      stopsCompleted: json['stopsCompleted'] as int,
      totalStops: json['totalStops'] as int,
      peakOccupancy: occ == null
          ? null
          : OccupancyStatus.values.firstWhere(
              (e) => e.name == occ,
              orElse: () => OccupancyStatus.limitedSeats,
            ),
    );
  }
}

class AppProvider extends ChangeNotifier {
  static const String _recentRoutesKey = 'recent_routes';
  static const String _driverTripsKey = 'driver_trip_history';
  static const String _notificationsKey = 'in_app_notifications';
  static const Duration _maxBusLocationAge = Duration(seconds: 45);

  final List<BusRoute> _routes = RoutesData.routes;
  BusRoute? _selectedRoute;
  String? _selectedVariantId;
  UserMode _userMode = UserMode.passenger;
  Position? _currentPosition;
  bool _locationPermissionGranted = false;
  bool _isLoadingLocation = false;
  String _searchQuery = '';
  BusRoute? _activeDriverRoute;
  String? _activeDriverVariantId;
  OccupancyStatus? _driverOccupancy;
  final List<RecentRouteEntry> _recentRoutes = [];
  final List<DriverTripRecord> _driverTripHistory = [];
  DateTime? _activeTripStartedAt;
  int _activeTripMaxStopIndex = 0;
  OccupancyStatus? _activeTripPeakOccupancy;

  // ── Live GPS ──────────────────────────────────────────────────────────────
  StreamSubscription<Position>? _locationSub;

  // ── Firestore listeners ───────────────────────────────────────────────────
  StreamSubscription<QuerySnapshot>? _busLocationsSub;
  StreamSubscription<QuerySnapshot>? _routeStatusSub;
  final Map<String, BusLocationData> _activeBusLocations = {};
  final Map<String, RouteStatus> _remoteRouteStatuses = {};

  // ── Change detection for notifications ───────────────────────────────────
  final Map<String, RouteStatus> _prevRouteStatus = {};
  final Map<String, OccupancyStatus?> _prevOccupancy = {};

  // ── In-app notifications ──────────────────────────────────────────────────
  final List<AppNotification> _notifications = [];

  // ── Getters ───────────────────────────────────────────────────────────────

  List<BusRoute> get routes => _routes;
  BusRoute? get selectedRoute => _selectedRoute;
  String? get selectedVariantId => _selectedVariantId;
  RouteVariant? get selectedRouteVariant {
    if (_selectedRoute == null) return null;
    final id = _selectedVariantId ?? _selectedRoute!.defaultVariantId;
    return _selectedRoute!.variantById(id) ?? _selectedRoute!.defaultVariant;
  }

  UserMode get userMode => _userMode;
  Position? get currentPosition => _currentPosition;
  bool get locationPermissionGranted => _locationPermissionGranted;
  bool get isLoadingLocation => _isLoadingLocation;
  String get searchQuery => _searchQuery;
  BusRoute? get activeDriverRoute => _activeDriverRoute;
  String? get activeDriverVariantId => _activeDriverVariantId;
  RouteVariant? get activeDriverVariant {
    if (_activeDriverRoute == null) return null;
    final id = _activeDriverVariantId ?? _activeDriverRoute!.defaultVariantId;
    return _activeDriverRoute!.variantById(id) ??
        _activeDriverRoute!.defaultVariant;
  }

  OccupancyStatus? get driverOccupancy => _driverOccupancy;
  List<RecentRouteEntry> get recentRoutes => List.unmodifiable(_recentRoutes);
  List<DriverTripRecord> get driverTripHistory =>
      List.unmodifiable(_driverTripHistory);
  Map<String, BusLocationData> get activeBusLocations =>
      Map.unmodifiable(_activeBusLocations);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  LatLng get currentLatLng => _currentPosition != null
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : const LatLng(7.0644, 125.5214);

  List<BusRoute> get filteredRoutes {
    if (_searchQuery.isEmpty) return _routes;
    final query = _searchQuery.toLowerCase();
    return _routes
        .where(
          (r) =>
              r.name.toLowerCase().contains(query) ||
              r.code.toLowerCase().contains(query) ||
              r.origin.toLowerCase().contains(query) ||
              r.destination.toLowerCase().contains(query) ||
              r.allStopNames.any((s) => s.toLowerCase().contains(query)),
        )
        .toList();
  }

  List<BusLocationData> getBusLocationsForRoute(String routeId) =>
      _activeBusLocations.values.where((b) => b.routeId == routeId).toList();

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> initLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    final recentRaw = prefs.getString(_recentRoutesKey);
    if (recentRaw != null && recentRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(recentRaw) as List<dynamic>;
        _recentRoutes
          ..clear()
          ..addAll(
            decoded.map(
              (e) => RecentRouteEntry.fromJson(e as Map<String, dynamic>),
            ),
          );
      } catch (_) {}
    }

    final tripRaw = prefs.getString(_driverTripsKey);
    if (tripRaw != null && tripRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(tripRaw) as List<dynamic>;
        _driverTripHistory
          ..clear()
          ..addAll(
            decoded.map(
              (e) => DriverTripRecord.fromJson(e as Map<String, dynamic>),
            ),
          );
      } catch (_) {}
    }

    final notifRaw = prefs.getString(_notificationsKey);
    if (notifRaw != null && notifRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(notifRaw) as List<dynamic>;
        _notifications
          ..clear()
          ..addAll(
            decoded.map(
              (e) => AppNotification.fromJson(e as Map<String, dynamic>),
            ),
          );
      } catch (_) {}
    }

    notifyListeners();
  }

  /// Subscribe to Firestore for live bus positions and route status updates.
  void startFirestoreListeners() {
    _busLocationsSub?.cancel();
    _busLocationsSub = FirestoreService().streamActiveBusLocations().listen((
      snap,
    ) {
      _activeBusLocations.clear();
      for (final doc in snap.docs) {
        final bus = BusLocationData.fromFirestore(
          doc.data() as Map<String, dynamic>,
        );
        if (bus.driverBadge.isNotEmpty && _isFreshBusLocation(bus)) {
          _activeBusLocations[bus.driverBadge] = bus;
        }
      }
      _reconcileRouteStates();
      notifyListeners();
    }, onError: (_) {});

    _routeStatusSub?.cancel();
    _routeStatusSub = FirestoreService().streamAllRouteStatuses().listen((
      snap,
    ) {
      _remoteRouteStatuses.clear();
      for (final doc in snap.docs) {
        final routeId = doc.id;
        final data = doc.data() as Map<String, dynamic>;

        final statusStr = data['status'] as String?;
        final newStatus = statusStr == null
            ? null
            : RouteStatus.values.firstWhere(
                (s) => s.name == statusStr,
                orElse: () => RouteStatus.onStandby,
              );
        if (newStatus != null) {
          _remoteRouteStatuses[routeId] = newStatus;
        }
      }
      if (_reconcileRouteStates()) {
        notifyListeners();
      }
    }, onError: (_) {});
  }

  bool _reconcileRouteStates() {
    var changed = false;

    for (final route in _routes) {
      final nextStatus = _deriveRouteStatus(route.id);
      final nextOccupancy = _deriveRouteOccupancy(route.id);
      final nextOccupancyUpdated = _deriveRouteOccupancyUpdated(route.id);

      if (_prevRouteStatus.containsKey(route.id) &&
          _prevRouteStatus[route.id] != nextStatus) {
        _onRouteStatusChanged(route, nextStatus);
      }
      if (_prevOccupancy.containsKey(route.id) &&
          _prevOccupancy[route.id] != nextOccupancy &&
          nextOccupancy != null) {
        _onOccupancyChanged(route, nextOccupancy);
      }

      if (route.status != nextStatus ||
          route.occupancyStatus != nextOccupancy ||
          route.occupancyLastUpdated != nextOccupancyUpdated) {
        changed = true;
      }

      route.status = nextStatus;
      route.occupancyStatus = nextOccupancy;
      route.occupancyLastUpdated = nextOccupancyUpdated;
      _prevRouteStatus[route.id] = nextStatus;
      _prevOccupancy[route.id] = nextOccupancy;
    }

    return changed;
  }

  RouteStatus _deriveRouteStatus(String routeId) {
    final remoteStatus = _remoteRouteStatuses[routeId];
    if (remoteStatus == RouteStatus.unavailable) {
      return RouteStatus.unavailable;
    }
    if (getBusLocationsForRoute(routeId).isNotEmpty) {
      return RouteStatus.operating;
    }
    return RouteStatus.onStandby;
  }

  OccupancyStatus? _deriveRouteOccupancy(String routeId) {
    final buses = getBusLocationsForRoute(
      routeId,
    ).where((bus) => bus.occupancyStatus != null).toList(growable: false);

    if (buses.isEmpty) return null;

    return buses
        .map((bus) => bus.occupancyStatus!)
        .reduce(
          (current, next) =>
              _occupancyScore(next) > _occupancyScore(current) ? next : current,
        );
  }

  DateTime? _deriveRouteOccupancyUpdated(String routeId) {
    final timestamps = getBusLocationsForRoute(routeId)
        .map((bus) => bus.occupancyLastUpdated)
        .whereType<DateTime>()
        .toList(growable: false);

    if (timestamps.isEmpty) return null;
    timestamps.sort();
    return timestamps.last;
  }

  bool _isFreshBusLocation(BusLocationData bus) {
    final timestamp = bus.timestamp;
    if (timestamp == null) return true;
    return DateTime.now().difference(timestamp) <= _maxBusLocationAge;
  }

  void _onRouteStatusChanged(BusRoute route, RouteStatus newStatus) {
    final label = newStatus == RouteStatus.operating
        ? 'now operating. Buses are on the road.'
        : newStatus == RouteStatus.onStandby
        ? 'placed on standby. Service will resume shortly.'
        : 'currently unavailable.';
    _addNotification(
      AppNotification(
        id: '${route.id}_status_${DateTime.now().millisecondsSinceEpoch}',
        type: AppNotificationType.routeStatus,
        title: 'Route Status Changed',
        body: '${route.name} is $label',
        time: DateTime.now(),
      ),
    );
    NotificationService().showRouteStatusNotification(
      routeName: route.name,
      status: label,
    );
  }

  void _onOccupancyChanged(BusRoute route, OccupancyStatus newOcc) {
    final label = newOcc == OccupancyStatus.seatAvailable
        ? 'Seats Available (~33%)'
        : newOcc == OccupancyStatus.limitedSeats
        ? 'Limited Seats (~67%)'
        : 'Full Capacity (~95%). Expect standing passengers.';
    _addNotification(
      AppNotification(
        id: '${route.id}_occ_${DateTime.now().millisecondsSinceEpoch}',
        type: AppNotificationType.occupancyUpdate,
        title: 'Occupancy Update – ${route.code}',
        body: '${route.name} is now reporting $label',
        time: DateTime.now(),
      ),
    );
    NotificationService().showOccupancyNotification(
      routeName: route.name,
      occupancyLabel: label,
    );
  }

  // ── Notification CRUD ─────────────────────────────────────────────────────

  void _addNotification(AppNotification notif) {
    _notifications.insert(0, notif);
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }
    _saveNotifications();
    notifyListeners();
  }

  void addBusApproachingNotification({
    required String routeCode,
    required String stopName,
    required int minutesAway,
  }) {
    _addNotification(
      AppNotification(
        id: 'approach_${stopName}_${DateTime.now().millisecondsSinceEpoch}',
        type: AppNotificationType.busApproaching,
        title: 'Your bus is $minutesAway mins away!',
        body:
            '$routeCode bus is $minutesAway mins away from $stopName bus stop.',
        time: DateTime.now(),
      ),
    );
  }

  void markNotificationRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      _saveNotifications();
      notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    _saveNotifications();
    notifyListeners();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _saveNotifications();
    notifyListeners();
  }

  // ── User mode ─────────────────────────────────────────────────────────────

  void setUserMode(UserMode mode) {
    _userMode = mode;
    notifyListeners();
  }

  void selectRoute(BusRoute route, {String? variantId}) {
    _selectedRoute = route;
    _selectedVariantId = variantId ?? route.defaultVariantId;
    route.selectVariant(_selectedVariantId);
    addRecentRoute(route, _selectedVariantId ?? route.defaultVariantId);
    notifyListeners();
  }

  void selectRouteVariant(String variantId) {
    if (_selectedRoute == null) return;
    if (_selectedRoute!.variantById(variantId) == null) return;
    _selectedVariantId = variantId;
    _selectedRoute!.selectVariant(variantId);
    notifyListeners();
  }

  void clearSelectedRoute() {
    _selectedRoute = null;
    _selectedVariantId = null;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setActiveDriverRoute(
    BusRoute? route, {
    String? variantId,
    String? driverBadge,
    String? driverName,
  }) {
    // Clear any stale Firestore location doc from a previous session.
    if (driverBadge != null) {
      FirestoreService().clearBusLocation(driverBadge);
    }
    _activeDriverRoute = route;
    _activeDriverVariantId = variantId;
    if (route != null) {
      route.selectVariant(variantId ?? route.defaultVariantId);
      route.status = RouteStatus.operating;
      route.occupancyStatus = null;
      route.occupancyLastUpdated = null;
      _activeTripStartedAt = DateTime.now();
      _activeTripMaxStopIndex = 0;
      _activeTripPeakOccupancy = null;
    }
    notifyListeners();
  }

  void updateActiveStopProgress(int stopIndex) {
    if (stopIndex > _activeTripMaxStopIndex) {
      _activeTripMaxStopIndex = stopIndex;
    }
  }

  void stopDriverRoute({String? driverBadge}) {
    if (_activeDriverRoute != null && _activeTripStartedAt != null) {
      final variant = activeDriverVariant;
      final totalStops =
          variant?.stops.length ?? _activeDriverRoute!.stops.length;
      final completedStops = (_activeTripMaxStopIndex + 1).clamp(1, totalStops);

      _driverTripHistory.insert(
        0,
        DriverTripRecord(
          routeId: _activeDriverRoute!.id,
          routeCode: _activeDriverRoute!.code,
          routeName: _activeDriverRoute!.name,
          variantId: variant?.id ?? _activeDriverRoute!.defaultVariantId,
          variantLabel: variant?.shortLabel ?? 'AM • Outbound',
          startedAt: _activeTripStartedAt!,
          endedAt: DateTime.now(),
          stopsCompleted: completedStops,
          totalStops: totalStops,
          peakOccupancy: _activeTripPeakOccupancy ?? _driverOccupancy,
        ),
      );

      if (_driverTripHistory.length > 100) {
        _driverTripHistory.removeRange(100, _driverTripHistory.length);
      }
      _saveDriverTrips();
    }

    if (_activeDriverRoute != null) {
      _activeDriverRoute!.status = RouteStatus.onStandby;
      _activeDriverRoute!.occupancyStatus = null;
      _activeDriverRoute!.occupancyLastUpdated = null;
      if (driverBadge != null) {
        FirestoreService().clearBusLocation(driverBadge);
      }
    }

    _activeDriverRoute = null;
    _activeDriverVariantId = null;
    _driverOccupancy = null;
    _activeTripStartedAt = null;
    _activeTripMaxStopIndex = 0;
    _activeTripPeakOccupancy = null;
    notifyListeners();
  }

  void updateOccupancy(
    OccupancyStatus status, {
    String? driverBadge,
    String? routeId,
  }) {
    _driverOccupancy = status;

    if (_activeTripPeakOccupancy == null ||
        _occupancyScore(status) > _occupancyScore(_activeTripPeakOccupancy!)) {
      _activeTripPeakOccupancy = status;
    }

    if (_activeDriverRoute != null) {
      _activeDriverRoute!.occupancyStatus = status;
      _activeDriverRoute!.occupancyLastUpdated = DateTime.now();
      if (driverBadge != null) {
        FirestoreService().updateBusOccupancy(
          driverBadge: driverBadge,
          routeId: routeId ?? _activeDriverRoute!.id,
          variantId:
              _activeDriverVariantId ?? _activeDriverRoute!.defaultVariantId,
          occupancyStatus: status.name,
        );
      }
    }
    notifyListeners();
  }

  int _occupancyScore(OccupancyStatus s) {
    switch (s) {
      case OccupancyStatus.seatAvailable:
        return 1;
      case OccupancyStatus.limitedSeats:
        return 2;
      case OccupancyStatus.fullCapacity:
        return 3;
    }
  }

  void addRecentRoute(BusRoute route, String variantId) {
    final variant = route.variantById(variantId) ?? route.defaultVariant;
    _recentRoutes.removeWhere(
      (e) => e.routeId == route.id && e.variantId == variant.id,
    );
    _recentRoutes.insert(
      0,
      RecentRouteEntry(
        routeId: route.id,
        routeCode: route.code,
        routeName: route.name,
        variantId: variant.id,
        variantLabel: variant.shortLabel,
        viewedAt: DateTime.now(),
      ),
    );
    if (_recentRoutes.length > 25) {
      _recentRoutes.removeRange(25, _recentRoutes.length);
    }
    _saveRecentRoutes();
  }

  void updateRouteStatus(String routeId, RouteStatus status) {
    final idx = _routes.indexWhere((r) => r.id == routeId);
    if (idx != -1) {
      _routes[idx].status = status;
      notifyListeners();
    }
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<bool> requestLocationPermission({LocationAccuracy? accuracy}) async {
    _isLoadingLocation = true;
    notifyListeners();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _isLoadingLocation = false;
      notifyListeners();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _isLoadingLocation = false;
        notifyListeners();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _isLoadingLocation = false;
      notifyListeners();
      return false;
    }

    _locationPermissionGranted = true;
    await _getCurrentLocation(accuracy: accuracy);
    return true;
  }

  Future<void> _getCurrentLocation({LocationAccuracy? accuracy}) async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy ?? LocationAccuracy.high,
        ),
      );
    } catch (_) {}
    _isLoadingLocation = false;
    notifyListeners();
  }

  void setLocationPermissionGranted(bool value) {
    _locationPermissionGranted = value;
    notifyListeners();
  }

  void startLiveTracking({LocationAccuracy? accuracy}) {
    _locationSub?.cancel();
    _locationSub =
        Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: accuracy ?? LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((pos) {
          _currentPosition = pos;
          notifyListeners();
        }, onError: (_) {});
  }

  void stopLiveTracking() {
    _locationSub?.cancel();
    _locationSub = null;
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _saveRecentRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _recentRoutesKey,
        jsonEncode(_recentRoutes.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> _saveDriverTrips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _driverTripsKey,
        jsonEncode(_driverTripHistory.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _notificationsKey,
        jsonEncode(_notifications.take(50).map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _busLocationsSub?.cancel();
    _routeStatusSub?.cancel();
    super.dispose();
  }
}
