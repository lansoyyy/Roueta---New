import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/bus_route.dart';

class RouteStatusCard extends StatelessWidget {
  final BusRoute route;
  final int activeBusCount;
  final VoidCallback onPressed;
  final String actionLabel;

  const RouteStatusCard({
    super.key,
    required this.route,
    required this.activeBusCount,
    required this.onPressed,
    required this.actionLabel,
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

  Color get _occupancyColor {
    switch (route.occupancyStatus) {
      case OccupancyStatus.seatAvailable:
        return AppColors.statusOperating;
      case OccupancyStatus.limitedSeats:
        return AppColors.accent;
      case OccupancyStatus.fullCapacity:
        return AppColors.statusUnavailable;
      case null:
        return AppColors.gray300;
    }
  }

  String get _occupancyLabel {
    switch (route.occupancyStatus) {
      case OccupancyStatus.seatAvailable:
        return 'Seats Available';
      case OccupancyStatus.limitedSeats:
        return 'Limited Seats';
      case OccupancyStatus.fullCapacity:
        return '80% Full';
      case null:
        return activeBusCount > 0 ? 'Live bus detected' : 'No live occupancy';
    }
  }

  int get _filledBars {
    switch (route.occupancyStatus) {
      case OccupancyStatus.seatAvailable:
        return 2;
      case OccupancyStatus.limitedSeats:
        return 4;
      case OccupancyStatus.fullCapacity:
        return 6;
      case null:
        return activeBusCount > 0 ? 1 : 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultVariant = route.defaultVariant;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF7EEE8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.near_me_rounded,
                color: Color(0xFFD2AA8C),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${route.origin} to ${route.destination}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ScheduleChip(
                        label: 'AM ROUTE',
                        value: '${route.amStartTime} - ${route.amEndTime}',
                      ),
                      _ScheduleChip(
                        label: 'PM ROUTE',
                        value: '${route.pmStartTime} - ${route.pmEndTime}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryVeryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          route.code,
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${defaultVariant.stops.length} stops',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.directions_bus_filled_outlined,
                        size: 14,
                        color: _statusColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        activeBusCount == 1
                            ? '1 active bus'
                            : '$activeBusCount active buses',
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _occupancyLabel,
                              style: TextStyle(
                                color: _occupancyColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _OccupancyBars(
                              color: _occupancyColor,
                              filledBars: _filledBars,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: onPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          actionLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  final String label;
  final String value;

  const _ScheduleChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1DBAD3).withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1AAFC7),
              fontWeight: FontWeight.w800,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF158EA2),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _OccupancyBars extends StatelessWidget {
  final Color color;
  final int filledBars;

  const _OccupancyBars({required this.color, required this.filledBars});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (index) {
        final active = index < filledBars;
        return Container(
          width: 4,
          height: 10 + (index * 2),
          margin: EdgeInsets.only(right: index == 5 ? 0 : 3),
          decoration: BoxDecoration(
            color: active ? color : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}