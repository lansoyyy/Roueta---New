import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        children: [
          // ── Notifications ──────────────────────────────────────────
          _SectionHeader(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
          ),
          _ToggleTile(
            icon: Icons.directions_bus_rounded,
            iconColor: AppColors.primary,
            title: 'Bus Approaching Alerts',
            subtitle: 'Notify when your bus is 2 minutes away',
            value: settings.busApproachNotifs,
            onChanged: (v) {
              settings.busApproachNotifs = v;
              if (v) {
                NotificationService().requestPermissions();
              }
              settings.save();
            },
          ),
          _ToggleTile(
            icon: Icons.people_rounded,
            iconColor: AppColors.accent,
            title: 'Occupancy Updates',
            subtitle: 'Notify when bus occupancy changes significantly',
            value: settings.occupancyNotifs,
            onChanged: (v) {
              settings.occupancyNotifs = v;
              if (v) {
                NotificationService().requestPermissions();
              }
              settings.save();
            },
          ),
          _ToggleTile(
            icon: Icons.route_rounded,
            iconColor: AppColors.statusOperating,
            title: 'Route Status Changes',
            subtitle: 'Notify when routes go on standby or resume',
            value: settings.routeStatusNotifs,
            onChanged: (v) {
              settings.routeStatusNotifs = v;
              if (v) {
                NotificationService().requestPermissions();
              }
              settings.save();
            },
          ),
          _ToggleTile(
            icon: Icons.vibration_rounded,
            iconColor: Colors.blueGrey,
            title: 'Vibration',
            subtitle: 'Vibrate when a notification arrives',
            value: settings.vibrate,
            onChanged: (v) {
              settings.vibrate = v;
              settings.save();
            },
          ),

          const SizedBox(height: 8),

          // ── Map ────────────────────────────────────────────────────
          _SectionHeader(icon: Icons.map_outlined, title: 'Map'),
          _SelectTile(
            icon: Icons.layers_outlined,
            iconColor: Colors.indigo,
            title: 'Map Type',
            value: settings.mapType,
            options: const ['Normal', 'Satellite', 'Terrain', 'Hybrid'],
            onChanged: (v) {
              settings.mapType = v;
              settings.save();
            },
          ),
          _ToggleTile(
            icon: Icons.traffic_rounded,
            iconColor: Colors.orange,
            title: 'Show Traffic Layer',
            subtitle: 'Display real-time traffic conditions on the map',
            value: settings.showTraffic,
            onChanged: (v) {
              settings.showTraffic = v;
              settings.save();
            },
          ),
          _ToggleTile(
            icon: Icons.my_location_rounded,
            iconColor: Colors.blue,
            title: 'Auto-Center on Location',
            subtitle: 'Map re-centers when you open the app',
            value: settings.autoCenter,
            onChanged: (v) {
              settings.autoCenter = v;
              settings.save();
            },
          ),

          const SizedBox(height: 8),

          // ── Location ───────────────────────────────────────────────
          _SectionHeader(icon: Icons.location_on_outlined, title: 'Location'),
          _ToggleTile(
            icon: Icons.gps_fixed_rounded,
            iconColor: Colors.red,
            title: 'High Accuracy Mode',
            subtitle: 'Uses more battery but gives precise location',
            value: settings.highAccuracy,
            onChanged: (v) {
              settings.highAccuracy = v;
              settings.save();
            },
          ),

          const SizedBox(height: 8),

          // ── General ────────────────────────────────────────────────
          _SectionHeader(icon: Icons.tune_rounded, title: 'General'),
          _SelectTile(
            icon: Icons.person_outlined,
            iconColor: AppColors.primaryDark,
            title: 'Default Mode',
            value: settings.defaultMode,
            options: const ['Passenger', 'Driver'],
            onChanged: (v) {
              settings.defaultMode = v;
              settings.save();
            },
          ),
          _SelectTile(
            icon: Icons.language_rounded,
            iconColor: Colors.teal,
            title: 'Language',
            value: settings.language,
            options: const ['English', 'Filipino', 'Cebuano'],
            onChanged: (v) {
              settings.language = v;
              settings.save();
            },
          ),

          const SizedBox(height: 8),

          // ── About ──────────────────────────────────────────────────
          _SectionHeader(icon: Icons.info_outline_rounded, title: 'About'),
          _InfoTile(
            icon: Icons.directions_bus_rounded,
            iconColor: AppColors.primary,
            title: 'App Version',
            subtitle: 'RouETA v1.0.0 (Build 1)',
          ),
          _InfoTile(
            icon: Icons.location_city_rounded,
            iconColor: Colors.blueGrey,
            title: 'Service Coverage',
            subtitle: 'Davao City Interim Bus Service',
          ),
          _ActionTile(
            icon: Icons.security_outlined,
            iconColor: Colors.green,
            title: 'Privacy Policy',
            onTap: () => _showDialog(
              context,
              'Privacy Policy',
              'RouETA collects your device location solely to display your position on the map and calculate the nearest bus stop. No personal data is stored on our servers. Your location is processed entirely on-device.\n\nFor questions, contact: davaobus@roueta.ph',
            ),
          ),
          _ActionTile(
            icon: Icons.description_outlined,
            iconColor: Colors.grey,
            title: 'Terms of Service',
            onTap: () => _showDialog(
              context,
              'Terms of Service',
              'By using RouETA, you agree to use the app only for legitimate personal transport planning within Davao City. The app is provided as-is. The Davao Interim Bus Service Authority is not liable for service disruptions or data inaccuracies.\n\nRouETA v1.0.0 © 2026',
            ),
          ),

          const SizedBox(height: 32),

          // Confirmation snackbar trigger
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Settings saved'),
                    backgroundColor: AppColors.statusOperating,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle tile ───────────────────────────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              )
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ),
    );
  }
}

// ── Select tile ───────────────────────────────────────────────────────────────
class _SelectTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _SelectTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 18,
            ),
          ],
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => _OptionSheet(
              title: title,
              options: options,
              selected: value,
              onSelect: (v) {
                onChanged(v);
                Navigator.pop(ctx);
              },
            ),
          );
        },
      ),
    );
  }
}

class _OptionSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _OptionSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...options.map(
            (o) => ListTile(
              title: Text(o),
              trailing: o == selected
                  ? Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => onSelect(o),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info tile ─────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ),
    );
  }
}

// ── Action tile ───────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey[400],
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}
