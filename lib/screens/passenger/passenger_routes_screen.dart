import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/bus_route.dart';
import '../../providers/app_provider.dart';
import '../../widgets/route_status_card.dart';
import '../route_map_screen.dart';

class PassengerRoutesScreen extends StatelessWidget {
  const PassengerRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final routes = provider.filteredRoutes;

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
                  child: Text(
                    'No routes found',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: routes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PassengerRouteCard(
                    route: routes[i],
                    activeBusCount: provider.getBusLocationsForRoute(
                      routes[i].id,
                    ).length,
                    onStart: () {
                      provider.selectRoute(
                        routes[i],
                        variantId: routes[i].defaultVariantId,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RouteMapScreen(
                            route: routes[i],
                            initialVariantId: routes[i].defaultVariantId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _PassengerRouteCard extends StatelessWidget {
  final BusRoute route;
  final int activeBusCount;
  final VoidCallback onStart;

  const _PassengerRouteCard({
    required this.route,
    required this.activeBusCount,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return RouteStatusCard(
      route: route,
      activeBusCount: activeBusCount,
      onPressed: onStart,
      actionLabel: 'View Route',
    );
  }
}
