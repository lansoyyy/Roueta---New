import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isDriverLoggedIn = false;
  String? _driverUsername;
  String? _driverName;
  String? _driverRole;
  String? _driverBadge;
  List<String> _assignedRoutes = [];
  bool _isLoading = false;
  bool _initialized = false;
  String? _lastError;

  bool get isDriverLoggedIn => _isDriverLoggedIn;
  String? get driverUsername => _driverUsername;
  String? get driverName => _driverName;
  String? get driverRole => _driverRole;
  String? get driverBadge => _driverBadge;
  List<String> get assignedRoutes => List.unmodifiable(_assignedRoutes);
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;
  String? get lastError => _lastError;
  String get driverRoleLabel => _driverRole == 'konduktor'
      ? 'Konduktor'
      : _driverRole == 'driver'
      ? 'Driver'
      : 'Driver / Konduktor';

  /// Restore persisted session.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDriverLoggedIn = prefs.getBool('driver_logged_in') ?? false;
    _driverUsername = prefs.getString('driver_username');
    _driverName = prefs.getString('driver_name');
    _driverRole = prefs.getString('driver_role');
    _driverBadge = prefs.getString('driver_badge');
    final encodedRoutes = prefs.getStringList('driver_assigned_routes');
    _assignedRoutes = encodedRoutes ?? [];
    _initialized = true;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);

    // Simulate minimum UI feedback delay.
    await Future.delayed(const Duration(milliseconds: 600));
    try {
      final normalizedUsername = _normalizeUsername(username);
      final data = await FirestoreService().getDriverAccount(
        normalizedUsername,
      );

      if (data == null) {
        _setLoading(false, error: 'No staff account found for that username.');
        return false;
      }

      if (data['isActive'] == false) {
        _setLoading(false, error: 'This staff account is currently inactive.');
        return false;
      }

      final passwordHash = _hashPassword(password);
      final storedHash = data['passwordHash'] as String?;
      final legacyPassword = data['password'] as String?;
      final passwordMatched = storedHash == passwordHash;
      final legacyPasswordMatched =
          legacyPassword != null && legacyPassword == password;

      if (!passwordMatched && !legacyPasswordMatched) {
        _setLoading(false, error: 'Invalid username or password.');
        return false;
      }

      await _hydrateSessionFromAccount(
        data,
        fallbackUsername: normalizedUsername,
      );
      await FirestoreService().updateDriverLastLogin(
        _driverUsername ?? normalizedUsername,
      );

      if (legacyPasswordMatched || (data['role'] as String?) == null) {
        await FirestoreService().upgradeLegacyDriverAccount(
          username: _driverUsername ?? normalizedUsername,
          passwordHash: passwordHash,
          role: _driverRole,
          badge: _driverBadge,
        );
      }

      _setLoading(false);
      return true;
    } catch (_) {
      _setLoading(
        false,
        error: 'Unable to sign in right now. Please try again.',
      );
      return false;
    }
  }

  Future<String?> signUp({
    required String fullName,
    required String username,
    required String password,
    required String role,
    required String badge,
    required List<String> assignedRoutes,
  }) async {
    _setLoading(true);

    final normalizedUsername = _normalizeUsername(username);
    final normalizedRole = _normalizeRole(role);
    final normalizedBadge = _normalizeBadge(badge);
    final normalizedRoutes = assignedRoutes
        .map((routeId) => routeId.trim().toLowerCase())
        .where((routeId) => routeId.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (fullName.trim().isEmpty) {
      _setLoading(false, error: 'Full name is required.');
      return _lastError;
    }
    if (normalizedUsername.isEmpty) {
      _setLoading(false, error: 'Username is required.');
      return _lastError;
    }
    if (normalizedBadge.isEmpty) {
      _setLoading(false, error: 'Bus badge is required.');
      return _lastError;
    }
    if (normalizedRoutes.isEmpty) {
      _setLoading(false, error: 'Select at least one assigned route.');
      return _lastError;
    }

    try {
      final service = FirestoreService();
      final usernameAvailable = await service.isDriverUsernameAvailable(
        normalizedUsername,
      );
      if (!usernameAvailable) {
        _setLoading(false, error: 'That username is already taken.');
        return _lastError;
      }

      final badgeAvailable = await service.isDriverBadgeAvailable(
        normalizedBadge,
      );
      if (!badgeAvailable) {
        _setLoading(false, error: 'That bus badge is already in use.');
        return _lastError;
      }

      final passwordHash = _hashPassword(password);
      await service.createDriverAccount(
        username: normalizedUsername,
        passwordHash: passwordHash,
        name: fullName.trim(),
        role: normalizedRole,
        badge: normalizedBadge,
        assignedRoutes: normalizedRoutes,
      );

      await _hydrateSessionFromAccount({
        'username': normalizedUsername,
        'name': fullName.trim(),
        'role': normalizedRole,
        'badge': normalizedBadge,
        'assignedRoutes': normalizedRoutes,
      });

      _setLoading(false);
      return null;
    } on StateError catch (error) {
      _setLoading(false, error: error.message);
      return _lastError;
    } catch (_) {
      _setLoading(
        false,
        error: 'Unable to create your staff account right now.',
      );
      return _lastError;
    }
  }

  Future<String?> updateStaffAccount({
    required String fullName,
    required String role,
    required String badge,
    required List<String> assignedRoutes,
  }) async {
    if (!_isDriverLoggedIn || _driverUsername == null) {
      _setLoading(
        false,
        error: 'You need to sign in again to update this account.',
      );
      return _lastError;
    }

    _setLoading(true);

    final normalizedRole = _normalizeRole(role);
    final normalizedBadge = _normalizeBadge(badge);
    final normalizedRoutes = assignedRoutes
        .map((routeId) => routeId.trim().toLowerCase())
        .where((routeId) => routeId.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (fullName.trim().isEmpty) {
      _setLoading(false, error: 'Full name is required.');
      return _lastError;
    }
    if (normalizedBadge.isEmpty) {
      _setLoading(false, error: 'Bus badge is required.');
      return _lastError;
    }
    if (normalizedRoutes.isEmpty) {
      _setLoading(false, error: 'Select at least one assigned route.');
      return _lastError;
    }

    try {
      await FirestoreService().updateDriverAccount(
        username: _driverUsername!,
        name: fullName.trim(),
        role: normalizedRole,
        currentBadge: _driverBadge ?? '',
        newBadge: normalizedBadge,
        assignedRoutes: normalizedRoutes,
      );

      _driverName = fullName.trim();
      _driverRole = normalizedRole;
      _driverBadge = normalizedBadge;
      _assignedRoutes = normalizedRoutes;
      await _persistSession();

      _setLoading(false);
      return null;
    } on StateError catch (error) {
      _setLoading(false, error: error.message);
      return _lastError;
    } catch (_) {
      _setLoading(
        false,
        error: 'Unable to update this staff account right now.',
      );
      return _lastError;
    }
  }

  Future<void> _hydrateSessionFromAccount(
    Map<String, dynamic> found, {
    String? fallbackUsername,
  }) async {
    _isDriverLoggedIn = true;
    _driverUsername =
        (found['username'] as String?)?.trim().toLowerCase() ??
        fallbackUsername;
    _driverName = (found['name'] as String?)?.trim();
    _driverRole = _normalizeRole(found['role'] as String?);
    _driverBadge = _normalizeBadge(found['badge'] as String?);
    final routes = found['assignedRoutes'];
    _assignedRoutes = routes is List
        ? routes
              .whereType<String>()
              .map((routeId) => routeId.trim().toLowerCase())
              .where((routeId) => routeId.isNotEmpty)
              .toSet()
              .toList(growable: false)
        : <String>[];

    await _persistSession();
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('driver_logged_in', true);
    await prefs.setString('driver_username', _driverUsername ?? '');
    await prefs.setString('driver_name', _driverName ?? '');
    await prefs.setString('driver_role', _driverRole ?? '');
    await prefs.setString('driver_badge', _driverBadge ?? '');
    await prefs.setStringList('driver_assigned_routes', _assignedRoutes);
  }

  void _setLoading(bool isLoading, {String? error}) {
    _isLoading = isLoading;
    _lastError = error;
    notifyListeners();
  }

  String _normalizeUsername(String? username) =>
      (username ?? '').trim().toLowerCase();

  String _normalizeBadge(String? badge) => (badge ?? '').trim().toUpperCase();

  String _normalizeRole(String? role) {
    final normalized = (role ?? '').trim().toLowerCase();
    return normalized == 'konduktor' ? 'konduktor' : 'driver';
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<void> logout() async {
    _isDriverLoggedIn = false;
    _driverUsername = null;
    _driverName = null;
    _driverRole = null;
    _driverBadge = null;
    _assignedRoutes = [];
    _lastError = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('driver_logged_in');
    await prefs.remove('driver_username');
    await prefs.remove('driver_name');
    await prefs.remove('driver_role');
    await prefs.remove('driver_badge');
    await prefs.remove('driver_assigned_routes');

    notifyListeners();
  }

  Future<String?> deleteAccount() async {
    if (!_isDriverLoggedIn || _driverUsername == null) {
      return 'You need to sign in to delete your account.';
    }
    _setLoading(true);
    final username = _driverUsername!;
    final badge = _driverBadge ?? '';
    try {
      await FirestoreService().deleteDriverAccount(
        username: username,
        badge: badge,
      );
      await logout();
      return null;
    } catch (_) {
      _setLoading(
        false,
        error: 'Unable to delete your account right now. Please try again.',
      );
      return _lastError;
    }
  }
}
