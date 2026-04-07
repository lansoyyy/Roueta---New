import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/bus_route.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../active_bus_screen.dart';
import 'manage_assigned_routes_screen.dart';

class MyRoutesScreen extends StatefulWidget {
  final int initialTabIndex;

  const MyRoutesScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MyRoutesScreen> createState() => _MyRoutesScreenState();
}

class _MyRoutesScreenState extends State<MyRoutesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Routes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Assigned Routes'),
            Tab(text: 'Trip History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_AssignedRoutesTab(), _TripHistoryTab()],
      ),
    );
  }
}

// ── Assigned Routes Tab ──────────────────────────────────────────────────────
class _AssignedRoutesTab extends StatelessWidget {
  const _AssignedRoutesTab();

  Future<String?> _pickVariant(BuildContext context, BusRoute route) async {
    // Sort AM before PM; within each shift, Outbound before Inbound.
    final sorted = route.orderedVariants.toList()
      ..sort((a, b) {
        final shiftCmp = a.shift.index.compareTo(b.shift.index);
        return shiftCmp != 0
            ? shiftCmp
            : a.direction.index.compareTo(b.direction.index);
      });
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Select Trip Variant',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...sorted.map(
              (v) => ListTile(
                leading: Icon(
                  v.shift == RouteShift.am
                      ? Icons.wb_sunny_outlined
                      : Icons.nightlight_round,
                  color: AppColors.primary,
                ),
                title: Text(v.shortLabel),
                subtitle: Text('${v.stops.length} stops'),
                onTap: () => Navigator.pop(sheetContext, v.id),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();

    // Show only routes assigned to this driver/conductor.
    final assignedIds = auth.assignedRoutes;
    final routes = provider.routes
        .where((r) => assignedIds.contains(r.id))
        .toList(growable: false);

    final isOnDuty = provider.activeDriverRoute != null;

    return Column(
      children: [
        // Driver info strip
        Container(
          width: double.infinity,
          color: AppColors.primaryVeryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.drive_eta_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.driverName ?? 'Driver',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Badge: ${auth.driverBadge ?? '—'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const Spacer(),
              if (isOnDuty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statusOperating,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'On Duty',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (routes.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.route_outlined, size: 54, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    'No assigned routes',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add route access before starting a live trip.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageAssignedRoutesScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.edit_road_outlined, size: 18),
                    label: const Text('Manage Routes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // Routes list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: routes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final route = routes[i];
                final isActive = provider.activeDriverRoute?.id == route.id;
                return _AssignedRouteCard(
                  route: route,
                  isActive: isActive,
                  onTap: () async {
                    if (route.status == RouteStatus.unavailable) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'This route is currently unavailable',
                          ),
                          backgroundColor: AppColors.statusUnavailable,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final variantId = await _pickVariant(context, route);
                    if (variantId == null || !context.mounted) return;

                    provider.setActiveDriverRoute(
                      route,
                      variantId: variantId,
                      driverBadge: auth.driverBadge,
                      driverName: auth.driverName,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActiveBusScreen(
                          route: route,
                          initialVariantId: variantId,
                        ),
                      ),
                    ).then((_) {
                      if (context.mounted) {
                        provider.stopDriverRoute(driverBadge: auth.driverBadge);
                      }
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _AssignedRouteCard extends StatelessWidget {
  final BusRoute route;
  final bool isActive;
  final VoidCallback onTap;

  const _AssignedRouteCard({
    required this.route,
    required this.isActive,
    required this.onTap,
  });

  Color get _statusColor {
    switch (route.status) {
      case RouteStatus.operating:
        return AppColors.statusOperating;
      case RouteStatus.onStandby:
        return AppColors.statusStandby;
      case RouteStatus.unavailable:
        return AppColors.statusUnavailable;
    }
  }

  String get _statusLabel {
    switch (route.status) {
      case RouteStatus.operating:
        return 'Operating';
      case RouteStatus.onStandby:
        return 'On Standby';
      case RouteStatus.unavailable:
        return 'Unavailable';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isActive
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.primaryVeryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.navigation_rounded,
                      color: isActive ? Colors.white : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
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
                                route.code,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${route.defaultVariant.stops.length} stops',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Schedule row
              Row(
                children: [
                  _ScheduleChip(
                    label: 'AM',
                    time: '${route.amStartTime} – ${route.amEndTime}',
                  ),
                  const SizedBox(width: 8),
                  _ScheduleChip(
                    label: 'PM',
                    time: '${route.pmStartTime} – ${route.pmEndTime}',
                  ),
                ],
              ),

              // Start/Continue button
              if (!isActive) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: route.status == RouteStatus.unavailable
                        ? null
                        : onTap,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text(
                      'Start Route',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
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

class _ScheduleChip extends StatelessWidget {
  final String label;
  final String time;
  const _ScheduleChip({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            '$label  $time',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// ── Trip History Tab ──────────────────────────────────────────────────────────
class _TripHistoryTab extends StatelessWidget {
  const _TripHistoryTab();

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<AppProvider>().driverTripHistory;

    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 72,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No trips yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed trips will appear here.',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Stats strip
        Container(
          color: AppColors.primaryVeryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _StatChip(
                label: 'Total Trips',
                value: '${trips.length}',
                icon: Icons.route_rounded,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'This Week',
                value:
                    '${trips.where((t) => DateTime.now().difference(t.startedAt).inDays < 7).length}',
                icon: Icons.calendar_today_rounded,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Stops Done',
                value:
                    '${trips.fold<int>(0, (sum, t) => sum + t.stopsCompleted)}',
                icon: Icons.location_on_rounded,
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _TripCard(trip: trips[i]),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.primaryDark,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final DriverTripRecord trip;
  const _TripCard({required this.trip});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inHours < 24) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryVeryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.routeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
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
                              trip.routeCode,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryVeryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              trip.variantLabel,
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(trip.startedAt),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${_time(trip.startedAt)} – ${_time(trip.endedAt)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Stats row
            Row(
              children: [
                _TripStat(
                  icon: Icons.location_on_rounded,
                  label: 'Stops',
                  value: '${trip.stopsCompleted}/${trip.totalStops}',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 16),
                _TripStat(
                  icon: Icons.people_rounded,
                  label: 'Peak Occupancy',
                  value: _occupancyLabel(trip.peakOccupancy),
                  color: _occupancyColor(trip.peakOccupancy),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }

  String _occupancyLabel(OccupancyStatus? status) {
    switch (status) {
      case OccupancyStatus.seatAvailable:
        return 'Seats Available';
      case OccupancyStatus.limitedSeats:
        return 'Limited Seats';
      case OccupancyStatus.fullCapacity:
        return 'Full Capacity';
      case null:
        return 'Not set';
    }
  }

  Color _occupancyColor(OccupancyStatus? status) {
    switch (status) {
      case OccupancyStatus.seatAvailable:
        return AppColors.statusOperating;
      case OccupancyStatus.limitedSeats:
        return AppColors.accent;
      case OccupancyStatus.fullCapacity:
        return AppColors.statusUnavailable;
      case null:
        return Colors.grey;
    }
  }
}

class _TripStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TripStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
