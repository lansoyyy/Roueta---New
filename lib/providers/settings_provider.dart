import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _kBusApproachNotifs = 'settings_bus_approach_notifs';
  static const String _kOccupancyNotifs = 'settings_occupancy_notifs';
  static const String _kRouteStatusNotifs = 'settings_route_status_notifs';
  static const String _kVibrate = 'settings_vibrate';
  static const String _kMapType = 'settings_map_type';
  static const String _kShowTraffic = 'settings_show_traffic';
  static const String _kHighAccuracy = 'settings_high_accuracy';
  static const String _kAutoCenter = 'settings_auto_center';
  static const String _kDefaultMode = 'settings_default_mode';
  static const String _kLanguage = 'settings_language';

  bool busApproachNotifs = true;
  bool occupancyNotifs = true;
  bool routeStatusNotifs = false;
  bool vibrate = true;
  String mapType = 'Normal';
  bool showTraffic = false;
  bool highAccuracy = true;
  bool autoCenter = true;
  String defaultMode = 'Passenger';
  String language = 'English';

  // ── Computed properties used by map widgets ───────────────────────────────

  MapType get googleMapType {
    switch (mapType) {
      case 'Satellite':
        return MapType.satellite;
      case 'Terrain':
        return MapType.terrain;
      case 'Hybrid':
        return MapType.hybrid;
      default:
        return MapType.normal;
    }
  }

  LocationAccuracy get locationAccuracy =>
      highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium;

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    busApproachNotifs = prefs.getBool(_kBusApproachNotifs) ?? busApproachNotifs;
    occupancyNotifs = prefs.getBool(_kOccupancyNotifs) ?? occupancyNotifs;
    routeStatusNotifs = prefs.getBool(_kRouteStatusNotifs) ?? routeStatusNotifs;
    vibrate = prefs.getBool(_kVibrate) ?? vibrate;
    mapType = prefs.getString(_kMapType) ?? mapType;
    showTraffic = prefs.getBool(_kShowTraffic) ?? showTraffic;
    highAccuracy = prefs.getBool(_kHighAccuracy) ?? highAccuracy;
    autoCenter = prefs.getBool(_kAutoCenter) ?? autoCenter;
    defaultMode = prefs.getString(_kDefaultMode) ?? defaultMode;
    language = prefs.getString(_kLanguage) ?? language;
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBusApproachNotifs, busApproachNotifs);
    await prefs.setBool(_kOccupancyNotifs, occupancyNotifs);
    await prefs.setBool(_kRouteStatusNotifs, routeStatusNotifs);
    await prefs.setBool(_kVibrate, vibrate);
    await prefs.setString(_kMapType, mapType);
    await prefs.setBool(_kShowTraffic, showTraffic);
    await prefs.setBool(_kHighAccuracy, highAccuracy);
    await prefs.setBool(_kAutoCenter, autoCenter);
    await prefs.setString(_kDefaultMode, defaultMode);
    await prefs.setString(_kLanguage, language);
    notifyListeners();
  }

  // ── Localised strings ─────────────────────────────────────────────────────

  static const Map<String, Map<String, String>> _strings = {
    'English': {
      'search_hint': 'SEARCH',
      'scroll_click': 'SCROLL & CLICK YOUR BUS ROUTE',
      'the_bus_operating': 'THE BUS YOU ARE OPERATING',
      'start_route': 'Start Route',
      'routes': 'ROUTES',
      'no_routes_found': 'No routes found',
    },
    'Filipino': {
      'search_hint': 'MAGHANAP',
      'scroll_click': 'MAG-SCROLL AT PILIIN ANG IYONG RUTA',
      'the_bus_operating': 'ANG BUS NA IYONG PINATATAKBO',
      'start_route': 'Simulan ang Ruta',
      'routes': 'MGA RUTA',
      'no_routes_found': 'Walang nakitang ruta',
    },
    'Cebuano': {
      'search_hint': 'PANGITA',
      'scroll_click': 'I-SCROLL UG PILIA ANG IMONG RUTA',
      'the_bus_operating': 'ANG BUS NGA IMONG GIPATAKBO',
      'start_route': 'Sugdi ang Ruta',
      'routes': 'MGA RUTA',
      'no_routes_found': 'Walay nakit-ang ruta',
    },
  };

  String tr(String key) {
    return _strings[language]?[key] ?? _strings['English']![key] ?? key;
  }
}
