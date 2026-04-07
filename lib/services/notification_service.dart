import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _kBusApproachKey = 'settings_bus_approach_notifs';
  static const String _kOccupancyKey = 'settings_occupancy_notifs';
  static const String _kRouteStatusKey = 'settings_route_status_notifs';
  static const String _kVibrateKey = 'settings_vibrate';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  // ── Bus Approaching ───────────────────────────────────────────────────────

  Future<void> showBusApproachingNotification({
    required String stopName,
    required int minutesAway,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kBusApproachKey) ?? true)) return;

    await init();
    await _plugin.show(
      1001,
      'RouETA – Bus Approaching',
      'YOUR BUS IS $minutesAway MINS AWAY FROM ${stopName.toUpperCase()} BUS STOP',
      _buildDetails(
        channelId: 'bus_approaching',
        channelName: 'Bus Approaching',
        channelDesc: 'Notifies when your bus is about to arrive',
        vibrate: prefs.getBool(_kVibrateKey) ?? true,
      ),
    );
  }

  // ── Occupancy Update ──────────────────────────────────────────────────────

  Future<void> showOccupancyNotification({
    required String routeName,
    required String occupancyLabel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kOccupancyKey) ?? true)) return;

    await init();
    await _plugin.show(
      1002,
      'Occupancy Update',
      '$routeName is now reporting $occupancyLabel',
      _buildDetails(
        channelId: 'occupancy_update',
        channelName: 'Occupancy Updates',
        channelDesc: 'Notifies when bus occupancy changes',
        vibrate: prefs.getBool(_kVibrateKey) ?? true,
      ),
    );
  }

  // ── Route Status Change ───────────────────────────────────────────────────

  Future<void> showRouteStatusNotification({
    required String routeName,
    required String status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kRouteStatusKey) ?? false)) return;

    await init();
    await _plugin.show(
      1003,
      'Route Status Changed',
      '$routeName is $status',
      _buildDetails(
        channelId: 'route_status',
        channelName: 'Route Status Changes',
        channelDesc: 'Notifies when a route changes status',
        vibrate: prefs.getBool(_kVibrateKey) ?? true,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  NotificationDetails _buildDetails({
    required String channelId,
    required String channelName,
    required String channelDesc,
    bool vibrate = true,
  }) {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'RouETA',
      color: const Color(0xFF00BCD4),
      enableVibration: vibrate,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
