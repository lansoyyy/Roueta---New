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
  bool _permissionsRequested = false;

  static const AndroidNotificationChannel _busApproachingChannel =
      AndroidNotificationChannel(
        'bus_approaching',
        'Bus Approaching',
        description: 'Notifies when your bus is about to arrive',
        importance: Importance.max,
      );

  static const AndroidNotificationChannel _occupancyChannel =
      AndroidNotificationChannel(
        'occupancy_update',
        'Occupancy Updates',
        description: 'Notifies when bus occupancy changes',
        importance: Importance.high,
      );

  static const AndroidNotificationChannel _routeStatusChannel =
      AndroidNotificationChannel(
        'route_status',
        'Route Status Changes',
        description: 'Notifies when a route changes status',
        importance: Importance.high,
      );

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

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_busApproachingChannel);
    await androidPlugin?.createNotificationChannel(_occupancyChannel);
    await androidPlugin?.createNotificationChannel(_routeStatusChannel);

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await init();
    if (_permissionsRequested) return;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final macOsPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macOsPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    _permissionsRequested = true;
  }

  // ── Bus Approaching ───────────────────────────────────────────────────────

  Future<void> showBusApproachingNotification({
    required String stopName,
    required int minutesAway,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kBusApproachKey) ?? true)) return;

    await requestPermissions();
    await _plugin.show(
      _nextNotificationId(),
      'RouETA – Bus Approaching',
      'YOUR BUS IS $minutesAway MINS AWAY FROM ${stopName.toUpperCase()} BUS STOP',
      _buildDetails(
        channel: _busApproachingChannel,
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

    await requestPermissions();
    await _plugin.show(
      _nextNotificationId(),
      'Occupancy Update',
      '$routeName is now reporting $occupancyLabel',
      _buildDetails(
        channel: _occupancyChannel,
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
    if (!(prefs.getBool(_kRouteStatusKey) ?? true)) return;

    await requestPermissions();
    await _plugin.show(
      _nextNotificationId(),
      'Route Status Changed',
      '$routeName is $status',
      _buildDetails(
        channel: _routeStatusChannel,
        vibrate: prefs.getBool(_kVibrateKey) ?? true,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  NotificationDetails _buildDetails({
    required AndroidNotificationChannel channel,
    bool vibrate = true,
  }) {
    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: Priority.high,
      ticker: 'RouETA',
      color: const Color(0xFF00BCD4),
      channelShowBadge: true,
      enableVibration: vibrate,
      playSound: true,
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

  int _nextNotificationId() {
    return DateTime.now().microsecondsSinceEpoch.remainder(2147483647);
  }
}
