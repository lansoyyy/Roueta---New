import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';
import '../utils/assets.dart';
import 'auth/role_selection_screen.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  Future<void> _openSettings(BuildContext context) async {
    final provider = context.read<AppProvider>();

    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location service is disabled, open location settings
      bool opened = await Geolocator.openLocationSettings();
      if (opened && context.mounted) {
        // After opening settings, try requesting permission again
        final granted = await provider.requestLocationPermission();
        if (granted) {
          _navigateToMain(context);
        }
      }
      return;
    }

    // Request location permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      // Permission was permanently denied, open app settings
      bool opened = await Geolocator.openAppSettings();
      if (opened && context.mounted) {
        // After opening settings, check permission again
        final granted = await provider.requestLocationPermission();
        if (granted) {
          _navigateToMain(context);
        }
      }
      return;
    }

    if (permission == LocationPermission.denied) {
      // Permission still denied, open app settings
      bool opened = await Geolocator.openAppSettings();
      if (opened && context.mounted) {
        // After opening settings, check permission again
        final granted = await provider.requestLocationPermission();
        if (granted) {
          _navigateToMain(context);
        }
      }
      return;
    }

    // Permission granted
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      if (context.mounted) {
        _navigateToMain(context);
      }
    }
  }

  void _navigateToMain(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: AssetImage(AssetPaths.appLogo),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
              const SizedBox(height: 36),

              // Main text
              Text(
                'RouETA name needs your precise location to give you the estimated time arrival & bus directions.',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Sub-text
              Text(
                'Go to settings and then',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Instruction row 1
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFF1A73E8),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Turn on Location',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Instruction row 2
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.touch_app,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Tap always or while using',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),

              const Spacer(),

              // Settings button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _openSettings(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Skip / Continue without location
              TextButton(
                onPressed: () {
                  context.read<AppProvider>().setLocationPermissionGranted(
                    false,
                  );
                  _navigateToMain(context);
                },
                child: Text(
                  'Continue without location',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF006064)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path();
    path.addRect(Rect.fromLTWH(w * 0.2, h * 0.4, w * 0.6, h * 0.5));
    path.moveTo(w * 0.1, h * 0.4);
    path.lineTo(w * 0.5, h * 0.1);
    path.lineTo(w * 0.9, h * 0.4);
    path.close();

    canvas.drawPath(path, paint);

    final door = Path();
    door.addRect(Rect.fromLTWH(w * 0.38, h * 0.6, w * 0.24, h * 0.3));
    canvas.drawPath(door, Paint()..color = AppColors.primaryLight);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'ROU\nETA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: w);
    textPainter.paint(canvas, Offset((w - textPainter.width) / 2, h * 0.48));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
