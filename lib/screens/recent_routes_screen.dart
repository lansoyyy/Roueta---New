import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/bus_route.dart';
import '../providers/app_provider.dart';
import 'route_map_screen.dart';

class RecentRoutesScreen extends StatelessWidget {
  const RecentRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final recentEntries = provider.recentRoutes;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Recent Routes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primaryVeryLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 8),
                Text(
                  'Routes you have recently viewed',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: recentEntries.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    itemCount: recentEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final entry = recentEntries[i];
                      final route = provider.routes.firstWhere(
                        (r) => r.id == entry.routeId,
                        orElse: () => provider.routes.first,
                      );

                      return _RecentRouteCard(
                        route: route,
                        variantLabel: entry.variantLabel,
                        visitedLabel: _formatVisitedLabel(entry.viewedAt),
                        onTap: () {
                          provider.selectRoute(
                            route,
                            variantId: entry.variantId,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RouteMapScreen(
                                route: route,
                                initialVariantId: entry.variantId,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatVisitedLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _RecentRouteCard extends StatelessWidget {
  final BusRoute route;
  final String variantLabel;
  final String visitedLabel;
  final VoidCallback onTap;

  const _RecentRouteCard({
    required this.route,
    required this.variantLabel,
    required this.visitedLabel,
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
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryVeryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.route_rounded,
                      color: AppColors.primary,
                      size: 21,
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
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w700,
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
                                variantLabel,
                                style: TextStyle(
                                  fontSize: 10,
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
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        visitedLabel,
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${route.origin} -> ${route.destination}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
                  Text(
                    '${route.defaultVariant.stops.length} stops',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 74,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 14),
            Text(
              'No recent routes yet',
              style: TextStyle(
                fontSize: 19,
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Open a route map and it will appear here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
