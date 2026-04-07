# Roueta App - Missing Features & Future Enhancements

## ⚠️ CRITICAL ISSUE: Routes Use Simulated Coordinates

**Status:** ❌ NOT REAL DATA
**Impact:** All bus stop coordinates are fake/simulated
**Description:** The routes in [`lib/data/routes_data.dart`](lib/data/routes_data.dart:710-736) use mathematically generated coordinates with sine curves, NOT real GPS coordinates of actual Davao City bus stops.

**Current Implementation:**
```dart
// lib/data/routes_data.dart:710-736
static List<BusStop> _buildStops({
  required String routeId,
  required String variantId,
  required List<String> stopNames,
  required LatLng start,
  required double latStep,
  required double lngStep,
}) {
  final stops = <BusStop>[];

  for (int i = 0; i < stopNames.length; i++) {
    final curve = math.sin(i / 2.4) * 0.00055;  // SIMULATED CURVE
    final latitude = start.latitude + (latStep * i) + curve;  // FAKE COORDINATES
    final longitude = start.longitude + (lngStep * i) - curve;  // FAKE COORDINATES

    stops.add(
      BusStop(
        id: '${routeId}_${variantId}_${i + 1}',
        name: stopNames[i],
        position: LatLng(latitude, longitude),  // NOT REAL GPS DATA
        estimatedMinutesFromStart: i * 3,
      ),
    );
  }

  return stops;
}
```

**Problem:**
- All bus stops use simulated coordinates (e.g., `7.0000, 125.4700` with fake curves)
- These are NOT actual GPS coordinates of Davao City bus stops
- Routes will not match real-world locations
- ETA calculations will be inaccurate
- Maps will show routes in wrong locations

**Required Fix:**
Replace simulated coordinates with **real GPS coordinates** of actual Davao City bus stops:

```dart
// Example of REAL coordinates for Davao City
static List<BusStop> _buildStops({
  required String routeId,
  required String variantId,
  required List<String> stopNames,
  required List<LatLng> realCoordinates,  // Use REAL coordinates
}) {
  final stops = <BusStop>[];

  for (int i = 0; i < stopNames.length; i++) {
    stops.add(
      BusStop(
        id: '${routeId}_${variantId}_${i + 1}',
        name: stopNames[i],
        position: realCoordinates[i],  // REAL GPS DATA
        estimatedMinutesFromStart: i * 3,
      ),
    );
  }

  return stops;
}

// Example REAL coordinates for Davao City (these need to be verified):
static const List<BusStop> _r102Stops = [
  BusStop(
    id: 'r102_am_out_1',
    name: 'Toril District Hall',
    position: LatLng(7.0856, 125.4867),  // REAL COORDINATE
  ),
  BusStop(
    id: 'r102_am_out_2',
    name: 'Fusion GTH',
    position: LatLng(7.0833, 125.4921),  // REAL COORDINATE
  ),
  // ... more real coordinates
];
```

**Action Required:**
1. Survey actual GPS coordinates of all Davao City bus stops
2. Replace simulated coordinate generation with real coordinate data
3. Verify coordinates match real-world locations
4. Test routes on actual map to ensure accuracy

---

## Summary

This document outlines features that are currently missing or need implementation in the Roueta bus tracking application.

---

## Summary

**Current Status:** All 14 original issues have been fully implemented with Firebase backend integration, real-time location tracking, and proper state management.

**Missing Features:** 33 identified features across security, UX, functionality, and user experience categories.

---

## 🔐 Security & Authentication

### 1. Password Hashing ⚠️ HIGH PRIORITY
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Security Vulnerability  
**Description:** Passwords are stored in plain text in Firestore database. Anyone with database access can read all driver passwords.

**Current Implementation:**
- [`lib/services/firestore_service.dart`](lib/services/firestore_service.dart:92) - Password stored as plain text
- [`lib/providers/auth_provider.dart`](lib/providers/auth_provider.dart:92) - Direct string comparison

**Required Implementation:**
```dart
// Add to pubspec.yaml
dependencies:
  crypto: ^3.0.0

// Implement password hashing in AuthProvider
import 'package:crypto/crypto.dart';
import 'dart:convert';

String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  final hash = sha256.convert(bytes);
  return hash.toString();
}

// Update Firestore seeding
await _db.collection('driver_accounts').doc(username).set({
  'username': username,
  'password': _hashPassword(password), // Hash before storing
  // ...
});
```

### 2. Password Reset Feature
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Drivers cannot recover forgotten passwords  
**Description:** No mechanism for drivers to reset their password if forgotten.

**Required Implementation:**
- Password reset email functionality
- Reset token generation in Firestore
- Password reset screen
- Token validation and password update

### 3. Email Verification
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** No email verification for new accounts  
**Description:** Driver accounts can be created without email verification, allowing fake accounts.

**Required Implementation:**
- Firebase Email Verification
- Email verification status tracking
- Block unverified accounts from logging in

### 4. Session Timeout
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Security risk if device is left unattended  
**Description:** Driver sessions never expire, allowing indefinite access.

**Required Implementation:**
- Session timeout (e.g., 8 hours of inactivity)
- Auto-logout on timeout
- Remember me option with extended session

---

## 👨‍💼 Admin & Management

### 5. Admin Panel
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** No way to manage drivers, routes, or view feedback  
**Description:** No admin interface for managing the application.

**Required Implementation:**
```dart
// Create: lib/screens/admin/admin_dashboard_screen.dart
class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        children: [
          _AdminSection(
            title: 'Driver Management',
            icon: Icons.people,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DriverManagementScreen()),
            ),
          ),
          _AdminSection(
            title: 'Route Management',
            icon: Icons.route,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RouteManagementScreen()),
            ),
          ),
          _AdminSection(
            title: 'Feedback Management',
            icon: Icons.feedback,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeedbackManagementScreen()),
            ),
          ),
          _AdminSection(
            title: 'Analytics',
            icon: Icons.analytics,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Admin Features Needed:**
- Driver account management (CRUD)
- Route assignment management
- Feedback viewing and response
- Analytics dashboard
- System health monitoring

### 6. Driver Schedule Management
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Drivers cannot view their assigned schedule  
**Description:** No interface for drivers to see their work schedule.

**Required Implementation:**
- Schedule view screen
- Shift assignments
- Route assignments per shift
- Calendar view

---

## 🗺️ Map Features

### 7. Route Polylines on Main Map
**Status:** ⚠️ PARTIALLY IMPLEMENTED  
**Impact:** Main map shows only bus markers, not route paths  
**Description:** The main map screen displays bus markers but no route polylines, making it hard to see which routes buses are on.

**Current Implementation:**
- [`lib/screens/main_map_screen.dart`](lib/screens/main_map_screen.dart:135-170) - Only bus markers shown

**Required Implementation:**
```dart
// Update lib/screens/main_map_screen.dart
class _LiveMapView extends StatelessWidget {
  // Add polylines from active routes
  Set<Polyline> _buildRoutePolylines() {
    final polylines = <Polyline>{};
    
    for (final route in provider.routes) {
      if (route.status == RouteStatus.operating) {
        final variant = route.selectedVariant;
        final points = variant.polylinePoints;
        
        polylines.add(Polyline(
          polylineId: PolylineId('${route.id}_polyline'),
          points: points,
          color: AppColors.primary,
          width: 4,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ));
      }
    }
    
    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final buses = _buildBusMarkers();
    final polylines = _buildRoutePolylines(); // NEW

    return Stack(
      children: [
        GoogleMap(
          // ...
          markers: buses,
          polylines: polylines, // ADD THIS
        ),
        // ...
      ],
    );
  }
}
```

### 8. Bus Stop Markers on Main Map
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Passengers cannot see bus stop locations on main map  
**Description:** The main map shows bus markers but no bus stop markers.

**Required Implementation:**
```dart
// Add to lib/screens/main_map_screen.dart
Set<Marker> _buildStopMarkers() {
  final markers = <Marker>{};
  
  for (final route in provider.routes) {
    for (final stop in route.selectedVariant.stops) {
      markers.add(Marker(
        markerId: MarkerId('stop_${stop.id}'),
        position: stop.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: InfoWindow(title: stop.name),
      ));
    }
  }
  
  return markers;
}
```

### 9. Map Clustering
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Multiple buses in same area overlap on map  
**Description:** No marker clustering for multiple buses in close proximity.

**Required Implementation:**
- Add `flutter_google_maps_cluster` package
- Cluster markers when zoomed out
- Show cluster count
- Expand to individual markers when zoomed in

### 10. Route Filtering by Status
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Cannot filter routes by operating status  
**Description:** No way to show only operating routes or filter by status.

**Required Implementation:**
```dart
// Add to lib/screens/passenger/passenger_routes_screen.dart
enum RouteFilter { all, operating, onStandby, unavailable }

class _RouteFilterChip extends StatelessWidget {
  final RouteFilter filter;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _RouteFilterChip({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: filter.toString().split('.').last.toUpperCase(),
      selected: isSelected,
      onSelected: onTap,
    );
  }
}
```

### 11. Route Filtering by Occupancy
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Cannot filter routes by seat availability  
**Description:** No way to show only routes with available seats.

**Required Implementation:**
```dart
// Add occupancy filter to route list
enum OccupancyFilter { all, available, limited, full }

List<BusRoute> get filteredRoutes {
  var routes = provider.routes;
  
  if (searchQuery.isNotEmpty) {
    routes = routes.where(/* search logic */).toList();
  }
  
  if (occupancyFilter != OccupancyFilter.all) {
    routes = routes.where((r) {
      switch (occupancyFilter) {
        case OccupancyFilter.available:
          return r.occupancyStatus == OccupancyStatus.seatAvailable;
        case OccupancyFilter.limited:
          return r.occupancyStatus == OccupancyStatus.limitedSeats;
        case OccupancyFilter.full:
          return r.occupancyStatus == OccupancyStatus.fullCapacity;
        default:
          return true;
      }
    }).toList();
  }
  
  return routes;
}
```

### 12. Nearby Routes Feature
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Cannot find routes near user's location  
**Description:** No feature to find routes based on user's current location.

**Required Implementation:**
```dart
// Create: lib/screens/nearby_routes_screen.dart
class NearbyRoutesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final userLocation = provider.currentPosition;
    
    if (userLocation == null) {
      return _RequestLocationPrompt();
    }
    
    // Find routes within 5km radius
    final nearbyRoutes = provider.routes.where((route) {
      final distance = Geolocator.distanceBetween(
        userLocation!.latitude,
        userLocation!.longitude,
        route.startPosition.latitude,
        route.startPosition.longitude,
      );
      return distance <= 5000; // 5km radius
    }).toList();
    
    // Sort by distance
    nearbyRoutes.sort((a, b) {
      final distA = Geolocator.distanceBetween(/* ... */);
      final distB = Geolocator.distanceBetween(/* ... */);
      return distA.compareTo(distB);
    });
    
    return _NearbyRoutesList(routes: nearbyRoutes);
  }
}
```

---

## 🔔 Notifications

### 13. Firebase Cloud Messaging (FCM)
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** No push notifications when app is closed  
**Description:** Only local notifications work. No remote push notifications when app is in background.

**Required Implementation:**
```yaml
# Add to pubspec.yaml
dependencies:
  firebase_messaging: ^15.1.0
```

```dart
// Create: lib/services/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      // Save token to Firestore for driver
      await FirestoreService().saveDriverFCMToken(token!);
    }

    // Handle incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground message
      NotificationService().showLocalNotification(
        title: message.notification?.title ?? 'New Update',
        body: message.notification?.body ?? '',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle background tap
      // Navigate to appropriate screen
    });
  }
}
```

### 14. Bus Arrival Alerts
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** No alerts when specific bus arrives at user's stop  
**Description:** No way for passengers to set alerts for specific buses arriving at their stop.

**Required Implementation:**
```dart
// Add to lib/screens/route_map_screen.dart
class _BusArrivalAlert extends StatefulWidget {
  @override
  State<_BusArrivalAlert> createState() => _BusArrivalAlertState();
}

class _BusArrivalAlertState extends State<_BusArrivalAlert> {
  bool _alertEnabled = false;
  int _alertMinutes = 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text('Alert Me When Bus Arrives'),
            ],
          ),
          const SizedBox(height: 16),
          Switch(
            value: _alertEnabled,
            onChanged: (v) => setState(() => _alertEnabled = v),
          ),
          if (_alertEnabled) ...[
            const SizedBox(height: 16),
            Text('Alert me when bus is within:'),
            const SizedBox(height: 8),
            Row(
              children: [
                _MinuteChip(minutes: 2, selected: _alertMinutes == 2),
                const SizedBox(width: 8),
                _MinuteChip(minutes: 5, selected: _alertMinutes == 5),
                const SizedBox(width: 8),
                _MinuteChip(minutes: 10, selected: _alertMinutes == 10),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
```

### 15. Delay Notifications
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** No notifications when buses are delayed  
**Description:** No alerts when buses are running behind schedule.

**Required Implementation:**
- Track scheduled vs actual arrival times
- Calculate delay threshold (e.g., 5+ minutes late)
- Send delay notifications to affected passengers
- Allow passengers to opt-in/out of delay notifications

---

## 👤 User Experience

### 16. Dark Mode
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** No dark mode for night-time use  
**Description:** No way to switch app to dark theme.

**Required Implementation:**
```dart
// Update lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    // ... existing light theme
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: const Color(0xFF121212),
      background: const Color(0xFF121212),
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onErrorContainer: Colors.red,
    ),
    // ... dark theme colors
  );
}

// Add to SettingsProvider
bool isDarkMode = false;

void toggleDarkMode() {
  isDarkMode = !isDarkMode;
  save();
  notifyListeners();
}
```

### 17. Accessibility Features
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Poor accessibility for users with disabilities  
**Description:** No screen reader support, large text options, or high contrast mode.

**Required Implementation:**
- Semantic labels for all widgets
- Screen reader announcements
- Large text scaling option
- High contrast mode
- Voice control support

### 18. Onboarding Tutorial
**Status:** ⚠️ PARTIALLY IMPLEMENTED  
**Impact:** New users may not understand all features  
**Description:** Splash screen shows logo but no tutorial for first-time users.

**Required Implementation:**
- Interactive tutorial screens
- Feature walkthrough
- Skip tutorial option
- Show tutorial again from settings

### 19. Rate App Prompt
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** No way for users to rate the app  
**Description:** No prompt asking users to rate the app after certain usage.

**Required Implementation:**
```dart
// Create: lib/services/rate_app_service.dart
class RateAppService {
  static const int _minLaunches = 5;
  static const int _minDays = 7;

  Future<void> showRateDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final launchCount = prefs.getInt('app_launch_count') ?? 0;
    final lastRated = prefs.getBool('has_rated') ?? false;

    if (lastRated) return;

    if (launchCount >= _minLaunches) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rate RouETA'),
          content: const Text('If you enjoy using RouETA, please take a moment to rate it!'),
          actions: [
            TextButton(
              onPressed: () {
                prefs.setBool('has_rated', true);
                Navigator.pop(ctx);
                // Open Play Store/App Store
                launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.example.roueta'));
              },
              child: const Text('Rate Now'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                prefs.setInt('app_launch_count', 0);
              },
              child: const Text('Later'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> incrementLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt('app_launch_count') ?? 0) + 1;
    await prefs.setInt('app_launch_count', count);
  }
}
```

---

## 📱 App Features

### 20. Favorite Routes
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Passengers cannot save favorite routes for quick access  
**Description:** No way to mark routes as favorites for quick access.

**Required Implementation:**
```dart
// Add to lib/models/bus_route.dart
class BusRoute {
  // ... existing properties
  bool isFavorite = false;
}

// Add to AppProvider
final Set<String> _favoriteRouteIds = {};

Set<String> get favoriteRouteIds => Set.unmodifiable(_favoriteRouteIds);

void toggleFavorite(String routeId) {
  if (_favoriteRouteIds.contains(routeId)) {
    _favoriteRouteIds.remove(routeId);
  } else {
    _favoriteRouteIds.add(routeId);
  }
  _saveFavorites();
  notifyListeners();
}

Future<void> _saveFavorites() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('favorite_routes', _favoriteRouteIds.toList());
}

Future<void> initFavorites() async {
  final prefs = await SharedPreferences.getInstance();
  final ids = prefs.getStringList('favorite_routes');
  if (ids != null) {
    _favoriteRouteIds.addAll(ids!);
  }
}
```

### 21. Passenger Trip History
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Passengers cannot see their trip history  
**Description:** Only drivers have trip history. Passengers have no record of routes they've viewed.

**Required Implementation:**
```dart
// Add to AppProvider
class PassengerTripRecord {
  final String routeId;
  final String routeCode;
  final String routeName;
  final DateTime viewedAt;
  final DateTime? arrivedAt;
  
  const PassengerTripRecord({
    required this.routeId,
    required this.routeCode,
    required this.routeName,
    required this.viewedAt,
    this.arrivedAt,
  });
}

final List<PassengerTripRecord> _passengerTripHistory = [];

List<PassengerTripRecord> get passengerTripHistory =>
    List.unmodifiable(_passengerTripHistory);

void addPassengerTrip(String routeId) {
  // Add trip when user views route
  // Mark as "arrived" when user reaches destination
}
```

### 22. Trip Planning
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Cannot plan multi-route trips  
**Description:** No way to plan trips with multiple transfers or routes.

**Required Implementation:**
- Multi-route selection
- Transfer point identification
- Total trip time calculation
- Save trip plans
- Share trip plans

### 23. Share Location
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Cannot share bus location with others  
**Description:** No way to share current bus location with friends/family.

**Required Implementation:**
```dart
// Add to lib/screens/route_map_screen.dart
import 'package:share_plus/share_plus.dart';

void _shareBusLocation() async {
  final provider = context.read<AppProvider>();
  final buses = provider.getBusLocationsForRoute(widget.route.id);
  
  if (buses.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No active buses on this route')),
    );
    return;
  }
  
  final bus = buses.first;
  final shareText = '${bus.driverName} is on ${widget.route.name}\n'
      'Bus: ${bus.driverBadge}\n'
      'Current Stop: ${bus.currentStopIndex + 1}\n'
      'Track on RouETA App!';
  
  await Share.share(shareText, subject: 'Bus Location');
}
```

### 24. Search History
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** No search history for routes  
**Description:** Search queries are not saved for quick access.

**Required Implementation:**
```dart
// Add to AppProvider
final List<String> _searchHistory = [];

List<String> get searchHistory => List.unmodifiable(_searchHistory);

void addToSearchHistory(String query) {
  if (query.trim().isEmpty) return;
  
  _searchHistory.remove(query);
  _searchHistory.insert(0, query);
  
  if (_searchHistory.length > 10) {
    _searchHistory.removeLast();
  }
  
  _saveSearchHistory();
  notifyListeners();
}
```

### 25. Offline Mode
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Cannot use app without internet  
**Description:** No offline support for viewing routes and cached data.

**Required Implementation:**
```dart
// Create: lib/services/offline_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  bool _isOffline = false;
  final Connectivity _connectivity = Connectivity();

  Stream<ConnectivityResult> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _isOffline = result == ConnectivityResult.none;
  }

  bool get isOffline => _isOffline;

  // Cache data for offline use
  Future<void> cacheRoutes(List<BusRoute> routes) async {
    final prefs = await SharedPreferences.getInstance();
    final routesJson = jsonEncode(routes.map((r) => r.toJson()).toList());
    await prefs.setString('cached_routes', routesJson);
  }

  Future<List<BusRoute>?> getCachedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final routesJson = prefs.getString('cached_routes');
    if (routesJson == null) return null;
    
    final List<dynamic> decoded = jsonDecode(routesJson!);
    return decoded.map((j) => BusRoute.fromJson(j)).toList();
  }
}
```

---

## 📊 Analytics & Monitoring

### 26. Analytics Tracking
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** No insight into app usage and user behavior  
**Description:** No analytics to track user engagement, feature usage, and errors.

**Required Implementation:**
```yaml
# Add to pubspec.yaml
dependencies:
  firebase_analytics: ^11.3.0
```

```dart
// Create: lib/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> init() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
  }

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClassOverride: screenName,
    );
  }

  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  Future<void> logRouteView(String routeId, String routeCode) async {
    await logEvent('route_view', parameters: {
      'route_id': routeId,
      'route_code': routeCode,
    });
  }

  Future<void> logDriverLogin(String driverBadge) async {
    await logEvent('driver_login', parameters: {
      'driver_badge': driverBadge,
    });
  }
}
```

### 27. Error Reporting (Crashlytics)
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** No automatic crash reporting  
**Description:** No way to track and fix crashes automatically.

**Required Implementation:**
```yaml
# Add to pubspec.yaml
dependencies:
  firebase_crashlytics: ^4.1.0
```

```dart
// Create: lib/services/crash_service.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashService {
  static final CrashService _instance = CrashService._internal();
  factory CrashService() => _instance;
  CrashService._internal();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<void> init() async {
    await _crashlytics.setCrashlyticsCollectionEnabled(true);
  }

  Future<void> logError(String error, {StackTrace? stackTrace}) async {
    await _crashlytics.recordError(error, fatal: false, stackTrace: stackTrace);
  }

  Future<void> logCustomError(String message) async {
    await _crashlytics.recordError(message, fatal: false);
  }
}
```

### 28. Driver Statistics
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Drivers cannot see their performance metrics  
**Description:** No statistics for drivers (total trips, passengers, ratings, etc.).

**Required Implementation:**
```dart
// Create: lib/screens/driver/driver_stats_screen.dart
class DriverStatsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tripHistory = provider.driverTripHistory;
    
    final totalTrips = tripHistory.length;
    final totalStops = tripHistory.fold(0, (sum, trip) => sum + trip.stopsCompleted);
    final avgCompletionRate = totalStops / totalTrips;
    
    return Scaffold(
      appBar: AppBar(title: const Text('My Statistics')),
      body: ListView(
        children: [
          _StatCard(
            icon: Icons.directions_bus,
            title: 'Total Trips',
            value: '$totalTrips',
          ),
          _StatCard(
            icon: Icons.location_on,
            title: 'Total Stops Completed',
            value: '$totalStops',
          ),
          _StatCard(
            icon: Icons.percent,
            title: 'Average Completion Rate',
            value: '${(avgCompletionRate * 100).toStringAsFixed(1)}%',
          ),
          // ... more stats
        ],
      ),
    );
  }
}
```

---

## 🌐 External Integrations

### 29. Weather Integration
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** No weather information for travel planning  
**Description:** No weather data to help passengers plan trips.

**Required Implementation:**
```yaml
# Add to pubspec.yaml
dependencies:
  weather: ^3.1.0
```

```dart
// Create: lib/services/weather_service.dart
import 'package:weather/weather.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  final WeatherFactory _wf = WeatherFactory('YOUR_API_KEY');

  Future<Weather?> getCurrentWeather(double lat, double lng) async {
    try {
      final weather = await _wf.currentWeatherByLocation(
        Location(name: 'Davao City', lat: lat, lon: lng),
      );
      return weather;
    } catch (e) {
      return null;
    }
  }
}
```

### 30. Traffic Alerts
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** No notifications for traffic incidents  
**Description:** No traffic incident alerts that might affect bus routes.

**Required Implementation:**
- Traffic incident API integration
- Route-specific traffic alerts
- Push notifications for major incidents
- Display traffic warnings on route map

### 31. Social Media Integration
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Cannot share app on social media  
**Description:** No social media sharing or login options.

**Required Implementation:**
- Share app on Facebook, Twitter
- Social media login option
- Share route info on social media

---

## 🚨 Safety Features

### 32. Emergency Contacts
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** No emergency contact feature  
**Description:** No way for passengers to access emergency contacts.

**Required Implementation:**
```dart
// Create: lib/screens/emergency_contacts_screen.dart
class EmergencyContactsScreen extends StatefulWidget {
  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final List<EmergencyContact> _contacts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: Column(
        children: [
          _EmergencyButton(
            icon: Icons.phone_in_talk,
            label: 'Call Emergency Services',
            color: Colors.red,
            onTap: () => launchUrl(Uri.parse('tel:911')),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) => _ContactCard(contact: _contacts[index]),
            ),
          ),
          FloatingActionButton(
            onPressed: () => _addContact(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class EmergencyContact {
  final String name;
  final String phone;
  final String relationship;
  final bool isPrimary;
}
```

### 33. SOS Button
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** No emergency SOS feature  
**Description:** No one-tap emergency button for passengers in distress.

**Required Implementation:**
```dart
// Add to main map screen
class _SOSButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 16,
      child: GestureDetector(
        onLongPress: () => _triggerSOS(context),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 12),
            ],
          ),
          child: const Icon(
            Icons.sos,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  void _triggerSOS(BuildContext context) async {
    // Confirm SOS
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text('Are you sure you want to trigger an emergency SOS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Send SOS to emergency services
      // Include current location
      // Notify emergency contacts
      // Log to analytics
    }
  }
}
```

---

## 🎯 Performance & Optimization

### 34. Image Caching
**Status:** ❌ NOT IMPLEMENTED  
**Impact:** Images may reload unnecessarily  
**Description:** No caching for bus route images or user avatars.

**Required Implementation:**
```yaml
# Add to pubspec.yaml
dependencies:
  cached_network_image: ^3.3.0
```

### 35. State Persistence
**Status:** ⚠️ PARTIALLY IMPLEMENTED  
**Impact:** Some data lost on app restart  
**Description:** Only some data is persisted. App state may be lost on force-quit.

**Current Implementation:**
- [`lib/providers/app_provider.dart`](lib/providers/app_provider.dart:669-699) - Recent routes, driver trips, notifications persisted
- Settings persisted
- Auth session persisted

**Missing:**
- Current route selection not persisted
- Map camera position not persisted
- Search query not persisted

---

## 📋 Priority Implementation Order

### Phase 1: Critical Security (Week 1-2)
1. **Password Hashing** - Security vulnerability
2. **Password Reset** - User experience
3. **Email Verification** - Account security
4. **Session Timeout** - Security

### Phase 2: Core Features (Week 3-4)
5. **Route Polylines on Main Map** - Visual improvement
6. **Bus Stop Markers on Main Map** - User experience
7. **Map Clustering** - Performance with many buses
8. **Route Filtering** - User experience
9. **Nearby Routes** - User experience
10. **Favorite Routes** - User convenience

### Phase 3: Notifications (Week 5-6)
11. **FCM Push Notifications** - Critical for engagement
12. **Bus Arrival Alerts** - Core feature
13. **Delay Notifications** - User expectation

### Phase 4: UX Improvements (Week 7-8)
14. **Dark Mode** - User preference
15. **Accessibility** - Inclusive design
16. **Onboarding Tutorial** - New user experience
17. **Rate App Prompt** - App store ratings

### Phase 5: Analytics & Monitoring (Week 9-10)
18. **Analytics Tracking** - Business intelligence
19. **Crash Reporting** - App stability
20. **Driver Statistics** - Driver engagement

### Phase 6: Safety Features (Week 11-12)
21. **Emergency Contacts** - User safety
22. **SOS Button** - Emergency feature

### Phase 7: Advanced Features (Week 13+)
23. **Trip Planning** - Advanced feature
24. **Passenger Trip History** - User value
25. **Share Location** - Social feature
26. **Search History** - Convenience
27. **Offline Mode** - Connectivity
28. **Admin Panel** - Management
29. **Driver Schedule** - Driver tools
30. **Weather Integration** - External API
31. **Traffic Alerts** - External API
32. **Image Caching** - Performance
33. **State Persistence** - Data integrity

---

## 📦 Required Dependencies

Add these packages to [`pubspec.yaml`](pubspec.yaml:1):

```yaml
dependencies:
  # Security
  crypto: ^3.0.0
  
  # Maps & Location
  flutter_google_maps_cluster: ^2.0.0
  
  # Notifications
  firebase_messaging: ^15.1.0
  
  # Analytics & Monitoring
  firebase_analytics: ^11.3.0
  firebase_crashlytics: ^4.1.0
  
  # Connectivity
  connectivity_plus: ^6.0.0
  
  # Sharing
  share_plus: ^9.0.0
  
  # Weather
  weather: ^3.1.0
  
  # Images
  cached_network_image: ^3.3.0
```

---

## 🗂️ New Files Structure

Create these new files:

```
lib/
├── screens/
│   ├── admin/
│   │   ├── admin_dashboard_screen.dart
│   │   ├── driver_management_screen.dart
│   │   ├── route_management_screen.dart
│   │   ├── feedback_management_screen.dart
│   │   └── analytics_screen.dart
│   ├── driver/
│   │   ├── driver_stats_screen.dart
│   │   └── driver_schedule_screen.dart
│   ├── passenger/
│   │   ├── nearby_routes_screen.dart
│   │   ├── favorite_routes_screen.dart
│   │   └── passenger_trip_history_screen.dart
│   └── safety/
│       ├── emergency_contacts_screen.dart
│       └── sos_button.dart
├── services/
│   ├── fcm_service.dart
│   ├── analytics_service.dart
│   ├── crash_service.dart
│   ├── offline_service.dart
│   ├── weather_service.dart
│   └── rate_app_service.dart
└── models/
    ├── emergency_contact.dart
    ├── passenger_trip_record.dart
    └── driver_stats.dart
```

---

## 📊 Implementation Checklist

Use this checklist to track progress:

### Security
- [ ] Password hashing implemented
- [ ] Password reset feature added
- [ ] Email verification added
- [ ] Session timeout implemented

### Admin & Management
- [ ] Admin dashboard created
- [ ] Driver management added
- [ ] Route management added
- [ ] Feedback management added
- [ ] Analytics dashboard added
- [ ] Driver schedule view added

### Map Features
- [ ] Route polylines on main map
- [ ] Bus stop markers on main map
- [ ] Map clustering implemented
- [ ] Route filtering by status
- [ ] Route filtering by occupancy
- [ ] Nearby routes feature added

### Notifications
- [ ] FCM push notifications
- [ ] Bus arrival alerts
- [ ] Delay notifications

### User Experience
- [ ] Dark mode implemented
- [ ] Accessibility features added
- [ ] Onboarding tutorial created
- [ ] Rate app prompt added

### App Features
- [ ] Favorite routes added
- [ ] Passenger trip history added
- [ ] Trip planning feature added
- [ ] Share location implemented
- [ ] Search history added
- [ ] Offline mode implemented

### Analytics & Monitoring
- [ ] Analytics tracking added
- [ ] Crash reporting added
- [ ] Driver statistics added

### Safety Features
- [ ] Emergency contacts added
- [ ] SOS button implemented

### External Integrations
- [ ] Weather integration added
- [ ] Traffic alerts added

### Performance
- [ ] Image caching implemented
- [ ] State persistence improved

---

## 🎯 Success Criteria

A feature is considered "fully implemented" when:

1. **Code Complete:** All necessary files created and code written
2. **UI Implemented:** User interface is visible and functional
3. **Connected:** Feature is connected to existing app architecture
4. **Tested:** Feature works as expected in normal use cases
5. **Error Handling:** Proper error handling and user feedback
6. **Documentation:** Code is documented and maintainable

---

## 💡 Recommendations

### Immediate Actions (This Week)
1. **Implement Password Hashing** - Critical security issue
2. **Add Route Polylines to Main Map** - High visual impact
3. **Implement FCM Push Notifications** - Critical for engagement
4. **Add Bus Stop Markers to Main Map** - High user value

### Short-term Actions (This Month)
5. **Create Admin Dashboard** - Management needs
6. **Implement Dark Mode** - Popular user request
7. **Add Favorite Routes** - User convenience
8. **Implement Analytics** - Business intelligence

### Long-term Actions (Next Quarter)
9. **Add Trip Planning** - Advanced feature
10. **Implement Weather Integration** - External API
11. **Add Accessibility Features** - Inclusive design
12. **Create Driver Statistics** - Driver engagement

---

*Last Updated: March 13, 2026*
