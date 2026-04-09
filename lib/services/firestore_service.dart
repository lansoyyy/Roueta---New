import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Central Firestore service — all collection reads/writes go through here.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Bus Locations ─────────────────────────────────────────────────────────

  Future<bool> activateBusLocation({
    required String driverBadge,
    required String driverName,
    required String routeId,
    required String variantId,
    required double lat,
    required double lng,
    required int currentStopIndex,
  }) async {
    try {
      await _db.collection('bus_locations').doc(driverBadge).set({
        'driverBadge': driverBadge,
        'driverName': driverName,
        'routeId': routeId,
        'variantId': variantId,
        'lat': lat,
        'lng': lng,
        'currentStopIndex': currentStopIndex,
        'isActive': true,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (_) {}
    return false;
  }

  Future<void> updateBusLocation({
    required String driverBadge,
    required String driverName,
    required String routeId,
    required String variantId,
    required double lat,
    required double lng,
    required int currentStopIndex,
  }) async {
    try {
      await _db.collection('bus_locations').doc(driverBadge).update({
        'driverBadge': driverBadge,
        'driverName': driverName,
        'routeId': routeId,
        'variantId': variantId,
        'lat': lat,
        'lng': lng,
        'currentStopIndex': currentStopIndex,
        'isActive': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> updateBusOccupancy({
    required String driverBadge,
    required String routeId,
    required String variantId,
    required String occupancyStatus,
  }) async {
    try {
      await _db.collection('bus_locations').doc(driverBadge).update({
        'driverBadge': driverBadge,
        'routeId': routeId,
        'variantId': variantId,
        'occupancyStatus': occupancyStatus,
        'occupancyLastUpdated': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> clearBusLocation(String driverBadge) async {
    try {
      await _db.collection('bus_locations').doc(driverBadge).set({
        'driverBadge': driverBadge,
        'isActive': false,
        'occupancyStatus': FieldValue.delete(),
        'occupancyLastUpdated': FieldValue.delete(),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Stream<QuerySnapshot> streamActiveBusLocations() {
    return _db
        .collection('bus_locations')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  Stream<QuerySnapshot> streamBusLocationsForRoute(String routeId) {
    return _db
        .collection('bus_locations')
        .where('routeId', isEqualTo: routeId)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  // ── Route Status & Occupancy ──────────────────────────────────────────────

  Future<void> updateRouteStatusAndOccupancy({
    required String routeId,
    String? status,
    String? occupancyStatus,
    String? updatedBy,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'routeId': routeId,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'lastUpdatedBy': updatedBy ?? 'system',
      };
      if (status != null) data['status'] = status;
      if (occupancyStatus != null) {
        data['occupancyStatus'] = occupancyStatus;
        data['occupancyLastUpdated'] = FieldValue.serverTimestamp();
      }
      await _db
          .collection('route_status')
          .doc(routeId)
          .set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  Stream<QuerySnapshot> streamAllRouteStatuses() {
    return _db.collection('route_status').snapshots();
  }

  // ── Feedback ──────────────────────────────────────────────────────────────

  Future<void> submitFeedback({
    required String category,
    required String subject,
    required String message,
    required int rating,
  }) async {
    await _db.collection('feedback').add({
      'category': category,
      'subject': subject,
      'message': message,
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
      'platform': 'android',
      'appVersion': '1.0.0',
    });
  }

  // ── Polyline Cache ────────────────────────────────────────────────────────

  Future<List<LatLng>?> getCachedPolyline(
    String routeId,
    String variantId, {
    int cacheVersion = 1,
  }) async {
    try {
      final doc = await _db
          .collection('polyline_cache')
          .doc('v${cacheVersion}_${routeId}_$variantId')
          .get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      final points = data['points'] as List<dynamic>?;
      if (points == null || points.isEmpty) return null;
      return points.map((p) {
        final map = p as Map<String, dynamic>;
        return LatLng(
          (map['lat'] as num).toDouble(),
          (map['lng'] as num).toDouble(),
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> cachePolyline(
    String routeId,
    String variantId,
    List<LatLng> points, {
    int cacheVersion = 1,
  }) async {
    try {
      await _db
          .collection('polyline_cache')
          .doc('v${cacheVersion}_${routeId}_$variantId')
          .set({
            'routeId': routeId,
            'variantId': variantId,
            'cacheVersion': cacheVersion,
            'points': points
                .map((p) => {'lat': p.latitude, 'lng': p.longitude})
                .toList(),
            'cachedAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {}
  }

  // ── Driver Accounts ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getDriverAccount(String username) async {
    try {
      final doc = await _db
          .collection('driver_accounts')
          .doc(username.trim().toLowerCase())
          .get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  Future<bool> isDriverUsernameAvailable(String username) async {
    try {
      final normalizedUsername = username.trim().toLowerCase();
      if (normalizedUsername.isEmpty) return false;
      final doc = await _db
          .collection('driver_accounts')
          .doc(normalizedUsername)
          .get();
      return !doc.exists;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isDriverBadgeAvailable(String badge) async {
    try {
      final normalizedBadge = badge.trim().toUpperCase();
      if (normalizedBadge.isEmpty) return false;

      final badgeDoc = await _db
          .collection('driver_badges')
          .doc(normalizedBadge)
          .get();
      if (badgeDoc.exists) return false;

      final legacyMatch = await _db
          .collection('driver_accounts')
          .where('badge', isEqualTo: normalizedBadge)
          .limit(1)
          .get();
      return legacyMatch.docs.isEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> createDriverAccount({
    required String username,
    required String passwordHash,
    required String name,
    required String role,
    required String badge,
    required List<String> assignedRoutes,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedBadge = badge.trim().toUpperCase();
    final normalizedRole = role.trim().toLowerCase();
    final normalizedRoutes = assignedRoutes
        .map((routeId) => routeId.trim().toLowerCase())
        .where((routeId) => routeId.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedUsername.isEmpty) {
      throw StateError('Username is required.');
    }
    if (normalizedBadge.isEmpty) {
      throw StateError('Bus badge is required.');
    }

    final badgeAvailable = await isDriverBadgeAvailable(normalizedBadge);
    if (!badgeAvailable) {
      throw StateError('This bus badge is already in use.');
    }

    final accountRef = _db
        .collection('driver_accounts')
        .doc(normalizedUsername);
    final badgeRef = _db.collection('driver_badges').doc(normalizedBadge);

    await _db.runTransaction((transaction) async {
      final existingAccount = await transaction.get(accountRef);
      if (existingAccount.exists) {
        throw StateError('This username is already taken.');
      }

      final existingBadge = await transaction.get(badgeRef);
      if (existingBadge.exists) {
        throw StateError('This bus badge is already in use.');
      }

      transaction.set(accountRef, {
        'username': normalizedUsername,
        'passwordHash': passwordHash,
        'name': name.trim(),
        'role': normalizedRole,
        'badge': normalizedBadge,
        'assignedRoutes': normalizedRoutes,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      transaction.set(badgeRef, {
        'badge': normalizedBadge,
        'username': normalizedUsername,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateDriverLastLogin(String username) async {
    try {
      await _db.collection('driver_accounts').doc(username).set({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> updateDriverAccount({
    required String username,
    required String name,
    required String role,
    required String currentBadge,
    required String newBadge,
    required List<String> assignedRoutes,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedCurrentBadge = currentBadge.trim().toUpperCase();
    final normalizedNewBadge = newBadge.trim().toUpperCase();
    final normalizedRole = role.trim().toLowerCase();
    final normalizedRoutes = assignedRoutes
        .map((routeId) => routeId.trim().toLowerCase())
        .where((routeId) => routeId.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedUsername.isEmpty) {
      throw StateError('Unable to update an unknown account.');
    }
    if (name.trim().isEmpty) {
      throw StateError('Full name is required.');
    }
    if (normalizedNewBadge.isEmpty) {
      throw StateError('Bus badge is required.');
    }
    if (normalizedRoutes.isEmpty) {
      throw StateError('Select at least one assigned route.');
    }

    final accountRef = _db
        .collection('driver_accounts')
        .doc(normalizedUsername);
    final newBadgeRef = _db.collection('driver_badges').doc(normalizedNewBadge);
    final oldBadgeRef = normalizedCurrentBadge.isEmpty
        ? null
        : _db.collection('driver_badges').doc(normalizedCurrentBadge);

    await _db.runTransaction((transaction) async {
      final accountDoc = await transaction.get(accountRef);
      if (!accountDoc.exists) {
        throw StateError('Staff account no longer exists.');
      }

      if (normalizedCurrentBadge != normalizedNewBadge) {
        final newBadgeDoc = await transaction.get(newBadgeRef);
        if (newBadgeDoc.exists) {
          throw StateError('This bus badge is already in use.');
        }
      }

      transaction.set(accountRef, {
        'name': name.trim(),
        'role': normalizedRole,
        'badge': normalizedNewBadge,
        'assignedRoutes': normalizedRoutes,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(newBadgeRef, {
        'badge': normalizedNewBadge,
        'username': normalizedUsername,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (oldBadgeRef != null && normalizedCurrentBadge != normalizedNewBadge) {
        transaction.delete(oldBadgeRef);
      }
    });

    if (normalizedCurrentBadge.isNotEmpty &&
        normalizedCurrentBadge != normalizedNewBadge) {
      await clearBusLocation(normalizedCurrentBadge);
    }
  }

  Future<void> upgradeLegacyDriverAccount({
    required String username,
    required String passwordHash,
    String? role,
    String? badge,
  }) async {
    try {
      final normalizedUsername = username.trim().toLowerCase();
      final normalizedBadge = badge?.trim().toUpperCase();
      final normalizedRole = role?.trim().toLowerCase();

      await _db.collection('driver_accounts').doc(normalizedUsername).set({
        'passwordHash': passwordHash,
        'role': normalizedRole,
        'updatedAt': FieldValue.serverTimestamp(),
        'password': FieldValue.delete(),
      }, SetOptions(merge: true));

      if (normalizedBadge != null && normalizedBadge.isNotEmpty) {
        await _db.collection('driver_badges').doc(normalizedBadge).set({
          'badge': normalizedBadge,
          'username': normalizedUsername,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Future<void> deleteDriverAccount({
    required String username,
    required String badge,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedBadge = badge.trim().toUpperCase();

    final accountRef = _db
        .collection('driver_accounts')
        .doc(normalizedUsername);
    final badgeRef = normalizedBadge.isNotEmpty
        ? _db.collection('driver_badges').doc(normalizedBadge)
        : null;

    await _db.runTransaction((transaction) async {
      transaction.delete(accountRef);
      if (badgeRef != null) {
        transaction.delete(badgeRef);
      }
    });

    if (normalizedBadge.isNotEmpty) {
      await clearBusLocation(normalizedBadge);
    }
  }
}
