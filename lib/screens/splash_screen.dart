import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/assets.dart';
import 'location_permission_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LocationPermissionScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pre-check location permission
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().requestLocationPermission();
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4DD0E1), Color(0xFF00ACC1), Color(0xFF00838F)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Center content
              Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo circle
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: const DecorationImage(
                              image: AssetImage(AssetPaths.appLogo),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'WELCOME TO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'RouETA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom tagline
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: const Text(
                    'BASTA DABAWENYO, D.CPLINADO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Draws text along a circular arc above the logo
class _ArcText extends StatelessWidget {
  final String text;
  final double radius;

  const _ArcText({required this.text, required this.radius});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2,
      height: radius,
      child: CustomPaint(
        painter: _ArcTextPainter(text: text, radius: radius),
      ),
    );
  }
}

class _ArcTextPainter extends CustomPainter {
  final String text;
  final double radius;

  _ArcTextPainter({required this.text, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final double angleStep = 0.14;
    final double startAngle = -3.14 / 2 - ((text.length - 1) / 2) * angleStep;

    canvas.save();
    canvas.translate(size.width / 2, size.height * 1.2);

    for (int i = 0; i < text.length; i++) {
      final double angle = startAngle + i * angleStep;

      textPainter.text = TextSpan(
        text: text[i],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0,
        ),
      );
      textPainter.layout();

      canvas.save();
      canvas.rotate(angle);
      canvas.translate(0, -radius);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// RouETA logo widget (bus/house icon with text)
class _RouetaLogo extends StatelessWidget {
  final double size;
  const _RouetaLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF006064)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Draw a simplified house/building shape
    final path = Path();
    // Building body
    path.addRect(Rect.fromLTWH(w * 0.2, h * 0.4, w * 0.6, h * 0.5));
    // Roof
    path.moveTo(w * 0.1, h * 0.4);
    path.lineTo(w * 0.5, h * 0.1);
    path.lineTo(w * 0.9, h * 0.4);
    path.close();
    // Door
    final door = Path();
    door.addRect(Rect.fromLTWH(w * 0.38, h * 0.6, w * 0.24, h * 0.3));

    canvas.drawPath(path, paint);
    canvas.drawPath(door, Paint()..color = const Color(0xFF4DD0E1));

    // Draw "ROU" text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'ROU\nETA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: w);
    textPainter.paint(canvas, Offset((w - textPainter.width) / 2, h * 0.5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
