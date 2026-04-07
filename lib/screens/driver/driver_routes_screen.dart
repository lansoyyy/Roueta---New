import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/bus_route.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../active_bus_screen.dart';
import 'manage_assigned_routes_screen.dart';

class DriverRoutesScreen extends StatelessWidget {
  const DriverRoutesScreen({super.key});

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
    final assignedRouteIds = auth.assignedRoutes;
    final routes = provider.filteredRoutes
        .where((route) => assignedRouteIds.contains(route.id))
        .toList(growable: false);

    return Column(
      children: [
        // Banner
        Container(
          width: double.infinity,
          color: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: const Text(
            'SCROLL & CLICK YOUR BUS ROUTE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ),

        // Routes list
        Expanded(
          child: routes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.route_outlined,
                        size: 56,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No assigned routes available',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Update this staff account before starting a route.',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
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
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: routes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final route = routes[i];
                    return _DriverRouteCard(
                      route: route,
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
                        if (!context.mounted) return;

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
                            provider.stopDriverRoute(
                              driverBadge: auth.driverBadge,
                            );
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

class _DriverRouteCard extends StatelessWidget {
  final BusRoute route;
  final VoidCallback onTap;

  const _DriverRouteCard({required this.route, required this.onTap});

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

  OccupancyStatus? get _occupancy => route.occupancyStatus;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Direction icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Route info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _TimeInfo(
                          label: 'AM ROUTE',
                          time:
                              'TIME: ${route.amStartTime} - ${route.amEndTime}',
                        ),
                        const SizedBox(width: 10),
                        _TimeInfo(
                          label: 'PM ROUTE',
                          time:
                              'TIME: ${route.pmStartTime} - ${route.pmEndTime}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 11,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${route.defaultVariant.stops.length} Stops',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Right side: status + occupancy
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Status badge
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
                  const SizedBox(height: 8),
                  // Occupancy bars
                  _OccupancyIndicator(occupancy: _occupancy),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeInfo extends StatelessWidget {
  final String label;
  final String time;

  const _TimeInfo({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        Text(time, style: const TextStyle(fontSize: 9, color: Colors.black87)),
      ],
    );
  }
}

class _OccupancyIndicator extends StatelessWidget {
  final OccupancyStatus? occupancy;
  const _OccupancyIndicator({this.occupancy});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        Color barColor;
        if (occupancy == null) {
          barColor = Colors.grey.shade300;
        } else if (occupancy == OccupancyStatus.seatAvailable) {
          barColor = i < 2 ? AppColors.statusOperating : Colors.grey.shade300;
        } else if (occupancy == OccupancyStatus.limitedSeats) {
          barColor = i < 3 ? AppColors.accent : Colors.grey.shade300;
        } else {
          barColor = AppColors.statusUnavailable;
        }
        return Container(
          width: 6,
          height: 20 - (i % 2 == 0 ? 4 : 0),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
