import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/assets.dart';
import '../main_map_screen.dart';
import 'driver_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4DD0E1), Color(0xFF00ACC1), Color(0xFF00838F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // ── Logo ───────────────────────────────────────────────
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: AssetImage(AssetPaths.appLogo),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
              const SizedBox(height: 20),

              // ── App name ───────────────────────────────────────────
              const Text(
                'RouETA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Davao Interim Bus Service Route',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 12),

              // ── Divider ────────────────────────────────────────────
              Container(
                width: 50,
                height: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'How will you use the app today?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 32),

              // ── Cards ──────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Passenger card
                      _RoleCard(
                        icon: Icons.directions_bus_outlined,
                        title: "I'm a Passenger",
                        subtitle:
                            'View live routes, ETAs, and bus occupancy — no login needed.',
                        badgeLabel: 'Public Access',
                        badgeColor: Colors.green.shade600,
                        onTap: () => _enterAsPassenger(context),
                      ),

                      const SizedBox(height: 16),

                      // Driver card
                      _RoleCard(
                        icon: Icons.drive_eta_rounded,
                        title: 'Driver / Konduktor',
                        subtitle:
                            'Manage your active route and update bus occupancy status.',
                        badgeLabel: 'Login Required',
                        badgeColor: Colors.orange.shade700,
                        onTap: () => _enterAsDriver(context),
                      ),

                      const Spacer(),

                      // Bottom note
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          'RouETA helps Davaoenos track buses in real time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _enterAsPassenger(BuildContext context) {
    context.read<AppProvider>().setUserMode(UserMode.passenger);
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainMapScreen()));
  }

  void _enterAsDriver(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (auth.isDriverLoggedIn) {
      // Already authenticated — go straight to map in driver mode
      context.read<AppProvider>().setUserMode(UserMode.driver);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainMapScreen()),
      );
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const DriverLoginScreen()));
    }
  }
}

// ── Role card widget ────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final Color badgeColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryVeryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 30),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
