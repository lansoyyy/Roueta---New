import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/bus_route.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/map_marker_icons.dart';
import '../widgets/app_drawer.dart';
import 'auth/driver_login_screen.dart';
import 'passenger/passenger_routes_screen.dart';
import 'driver/driver_routes_screen.dart';
import 'profile_screen.dart';

class MainMapScreen extends StatefulWidget {
  const MainMapScreen({super.key});

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends State<MainMapScreen> {
  GoogleMapController? _mapController;

  /// 0 = routes/bus tab, 1 = live map, 2 = profile
  int _selectedIndex = 1;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      context.read<AppProvider>().startLiveTracking(
        accuracy: settings.locationAccuracy,
      );
      if (settings.autoCenter) _centerOnUser();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _centerOnUser() {
    final provider = context.read<AppProvider>();
    if (provider.locationPermissionGranted && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(provider.currentLatLng),
      );
    }
  }

  // ── Build body based on selected tab ─────────────────────────────────────

  Widget _buildBody(AppProvider provider, SettingsProvider settings) {
    if (_selectedIndex == 0) {
      if (provider.userMode == UserMode.driver) {
        final auth = context.read<AuthProvider>();
        if (!auth.isDriverLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.setUserMode(UserMode.passenger);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DriverLoginScreen()),
            );
          });
          return const PassengerRoutesScreen();
        }
        return const DriverRoutesScreen();
      }
      return const PassengerRoutesScreen();
    }

    if (_selectedIndex == 2) return const ProfileScreen();

    // ── Live map view (index 1) ──────────────────────────────────────────
    return _LiveMapView(
      mapController: _mapController,
      onMapCreated: (ctrl) {
        _mapController = ctrl;
        if (settings.autoCenter) _centerOnUser();
      },
      provider: provider,
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _TopBar(
            scaffoldKey: _scaffoldKey,
            searchController: _searchController,
            onSearch: (q) => provider.setSearchQuery(q),
            unreadCount: provider.unreadNotificationCount,
          ),
          Expanded(child: _buildBody(provider, settings)),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        userMode: provider.userMode,
      ),
    );
  }
}

enum _StopMarkerKind { start, end, mid }

class _MainMapStopEntry {
  final BusStop stop;
  final _StopMarkerKind kind;

  const _MainMapStopEntry({required this.stop, required this.kind});
}

// ── Live map with active bus markers ─────────────────────────────────────────

class _LiveMapView extends StatefulWidget {
  final GoogleMapController? mapController;
  final MapCreatedCallback onMapCreated;
  final AppProvider provider;
  final SettingsProvider settings;

  const _LiveMapView({
    required this.mapController,
    required this.onMapCreated,
    required this.provider,
    required this.settings,
  });

  @override
  State<_LiveMapView> createState() => _LiveMapViewState();
}

class _LiveMapViewState extends State<_LiveMapView> {
  static const double _compactMarkerZoomThreshold = 12.0;
  BitmapDescriptor? _startStopIcon;
  BitmapDescriptor? _selectedStartStopIcon;
  BitmapDescriptor? _endStopIcon;
  BitmapDescriptor? _selectedEndStopIcon;
  BitmapDescriptor? _midStopIcon;
  BitmapDescriptor? _selectedMidStopIcon;
  BitmapDescriptor? _busMarkerIcon;
  BitmapDescriptor? _busMarkerIconLeft;
  BitmapDescriptor? _compactStartStopIcon;
  BitmapDescriptor? _compactSelectedStartStopIcon;
  BitmapDescriptor? _compactEndStopIcon;
  BitmapDescriptor? _compactSelectedEndStopIcon;
  BitmapDescriptor? _compactMidStopIcon;
  BitmapDescriptor? _compactSelectedMidStopIcon;
  BitmapDescriptor? _compactBusMarkerIcon;
  BitmapDescriptor? _compactBusMarkerIconLeft;
  String? _selectedStopId;
  Set<Marker> _stopMarkers = {};
  double _currentZoom = 13.5;

  AppProvider get provider => widget.provider;
  bool get _useCompactMarkers => _currentZoom < _compactMarkerZoomThreshold;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
  }

  @override
  void didUpdateWidget(covariant _LiveMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider.routes != widget.provider.routes) {
      _rebuildStopMarkers();
    }
  }

  Future<void> _loadMarkerIcons() async {
    final startStopIcon = await MapMarkerIcons.startStop();
    final selectedStartStopIcon = await MapMarkerIcons.startStop(
      selected: true,
    );
    final endStopIcon = await MapMarkerIcons.endStop();
    final selectedEndStopIcon = await MapMarkerIcons.endStop(selected: true);
    final midStopIcon = await MapMarkerIcons.busStop();
    final selectedMidStopIcon = await MapMarkerIcons.busStop(selected: true);
    final busMarkerIcon = await MapMarkerIcons.bus(facingRight: true);
    final busMarkerIconLeft = await MapMarkerIcons.bus(facingRight: false);
    final compactBusMarkerIconLeft = await MapMarkerIcons.bus(
      facingRight: false,
      compact: true,
    );
    final compactStartStopIcon = await MapMarkerIcons.startStop(compact: true);
    final compactSelectedStartStopIcon = await MapMarkerIcons.startStop(
      selected: true,
      compact: true,
    );
    final compactEndStopIcon = await MapMarkerIcons.endStop(compact: true);
    final compactSelectedEndStopIcon = await MapMarkerIcons.endStop(
      selected: true,
      compact: true,
    );
    final compactMidStopIcon = await MapMarkerIcons.busStop(compact: true);
    final compactSelectedMidStopIcon = await MapMarkerIcons.busStop(
      selected: true,
      compact: true,
    );
    final compactBusMarkerIcon = await MapMarkerIcons.bus(
      facingRight: true,
      compact: true,
    );
    if (!mounted) return;
    setState(() {
      _startStopIcon = startStopIcon;
      _selectedStartStopIcon = selectedStartStopIcon;
      _endStopIcon = endStopIcon;
      _selectedEndStopIcon = selectedEndStopIcon;
      _midStopIcon = midStopIcon;
      _selectedMidStopIcon = selectedMidStopIcon;
      _busMarkerIcon = busMarkerIcon;
      _busMarkerIconLeft = busMarkerIconLeft;
      _compactBusMarkerIconLeft = compactBusMarkerIconLeft;
      _compactStartStopIcon = compactStartStopIcon;
      _compactSelectedStartStopIcon = compactSelectedStartStopIcon;
      _compactEndStopIcon = compactEndStopIcon;
      _compactSelectedEndStopIcon = compactSelectedEndStopIcon;
      _compactMidStopIcon = compactMidStopIcon;
      _compactSelectedMidStopIcon = compactSelectedMidStopIcon;
      _compactBusMarkerIcon = compactBusMarkerIcon;
    });
    _rebuildStopMarkers();
  }

  void _handleCameraMove(CameraPosition position) {
    final shouldUseCompact = position.zoom < _compactMarkerZoomThreshold;
    final wasCompact = _useCompactMarkers;
    _currentZoom = position.zoom;
    if (shouldUseCompact != wasCompact) {
      _rebuildStopMarkers();
    }
  }

  _StopMarkerKind _mergeStopKind(
    _StopMarkerKind existing,
    _StopMarkerKind candidate,
  ) {
    if (existing == _StopMarkerKind.start || candidate == _StopMarkerKind.start) {
      return _StopMarkerKind.start;
    }
    if (existing == _StopMarkerKind.end || candidate == _StopMarkerKind.end) {
      return _StopMarkerKind.end;
    }
    return _StopMarkerKind.mid;
  }

  BitmapDescriptor _stopIconFor(_StopMarkerKind kind, {required bool selected}) {
    switch (kind) {
      case _StopMarkerKind.start:
        return selected
            ? ((_useCompactMarkers
                      ? _compactSelectedStartStopIcon
                      : _selectedStartStopIcon) ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen))
            : ((_useCompactMarkers ? _compactStartStopIcon : _startStopIcon) ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen));
      case _StopMarkerKind.end:
        return selected
            ? ((_useCompactMarkers
                      ? _compactSelectedEndStopIcon
                      : _selectedEndStopIcon) ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))
            : ((_useCompactMarkers ? _compactEndStopIcon : _endStopIcon) ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed));
      case _StopMarkerKind.mid:
        return selected
            ? ((_useCompactMarkers
                      ? _compactSelectedMidStopIcon
                      : _selectedMidStopIcon) ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure))
            : ((_useCompactMarkers ? _compactMidStopIcon : _midStopIcon) ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure));
    }
  }

  void _rebuildStopMarkers() {
    final uniqueStops = <String, _MainMapStopEntry>{};
    for (final route in provider.routes) {
      for (final variant in route.variants.values) {
        for (int index = 0; index < variant.stops.length; index++) {
          final stop = variant.stops[index];
          final kind = index == 0
              ? _StopMarkerKind.start
              : index == variant.stops.length - 1
              ? _StopMarkerKind.end
              : _StopMarkerKind.mid;
          final key = '${stop.name}_${stop.position.latitude.toStringAsFixed(5)}_${stop.position.longitude.toStringAsFixed(5)}';
          final existing = uniqueStops[key];
          if (existing == null) {
            uniqueStops[key] = _MainMapStopEntry(stop: stop, kind: kind);
            continue;
          }
          uniqueStops[key] = _MainMapStopEntry(
            stop: existing.stop,
            kind: _mergeStopKind(existing.kind, kind),
          );
        }
      }
    }

    final markers = uniqueStops.values.map((entry) {
      final isSelected = _selectedStopId == entry.stop.id;
      return Marker(
        markerId: MarkerId('main_stop_${entry.stop.id}'),
        position: entry.stop.position,
        icon: _stopIconFor(entry.kind, selected: isSelected),
        anchor: const Offset(0.5, 1.0),
        zIndexInt: isSelected ? 3 : 1,
        infoWindow: InfoWindow(title: entry.stop.name),
        onTap: () {
          setState(() {
            _selectedStopId = entry.stop.id;
          });
          _rebuildStopMarkers();
        },
      );
    }).toSet();

    if (!mounted) return;
    setState(() {
      _stopMarkers = markers;
    });
  }

  Set<Marker> _buildBusMarkers() {
    return provider.activeBusLocations.values.map((bus) {
      final facingRight = !bus.variantId.contains('_in');
      final icon = _useCompactMarkers
          ? (facingRight ? _compactBusMarkerIcon : _compactBusMarkerIconLeft)
          : (facingRight ? _busMarkerIcon : _busMarkerIconLeft);
      return Marker(
        markerId: MarkerId('bus_${bus.driverBadge}'),
        position: bus.position,
        icon: icon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: '${bus.driverBadge} — ${bus.routeId.toUpperCase()}',
          snippet: bus.driverName,
        ),
        anchor: const Offset(0.5, 1.0),
        zIndexInt: 4,
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final buses = _buildBusMarkers();

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: provider.currentLatLng,
            zoom: 13.5,
          ),
          onMapCreated: widget.onMapCreated,
          onCameraMove: _handleCameraMove,
          mapType: widget.settings.googleMapType,
          trafficEnabled: widget.settings.showTraffic,
          myLocationEnabled: provider.locationPermissionGranted,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          buildingsEnabled: true,
          compassEnabled: false,
          markers: {..._stopMarkers, ...buses},
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.place_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  '${_stopMarkers.length} bus stops',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (buses.isNotEmpty)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
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
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${buses.length} active',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (provider.locationPermissionGranted)
          Positioned(
            bottom: 20,
            right: 12,
            child: GestureDetector(
              onTap: () {
                widget.mapController?.animateCamera(
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
      ],
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final int unreadCount;

  const _TopBar({
    required this.scaffoldKey,
    required this.searchController,
    required this.onSearch,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Container(
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
            onTap: () => scaffoldKey.currentState?.openDrawer(),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.menu, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearch,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: settings.tr('search_hint'),
                        hintStyle: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bottom navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final UserMode userMode;

  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
    required this.userMode,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 80,
          child: Stack(
            children: [
              Row(
                children: [
                  _NavItem(
                    icon: Icons.directions_bus,
                    label: 'Routes',
                    isSelected: selectedIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  const Spacer(),
                  _NavItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    isSelected: selectedIndex == 2,
                    onTap: () => onTap(2),
                  ),
                ],
              ),
              Center(
                child: GestureDetector(
                  onTap: () => onTap(1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      Text(
                        settings.tr('routes'),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String? label;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        height: 62,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.14)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : const [],
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : Colors.grey[400],
                  size: 26,
                ),
              ),
              if (label != null) ...[  
                const SizedBox(height: 2),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : Colors.grey[400],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
