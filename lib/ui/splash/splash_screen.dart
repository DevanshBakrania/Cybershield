import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';

const Color cyberGreen = Color(0xFFCCFF00);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔐 Fingerprint Animation
            const Icon(
              Icons.fingerprint,
              size: 80,
              color: cyberGreen,
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .fadeIn(duration: 600.ms)
                .scaleXY(end: 1.1, duration: 600.ms)
                .then()
                .shimmer(
                  color: CyberTheme.dangerRed,
                  duration: 1000.ms,
                ),

            const SizedBox(height: 20),

            // 🟢 App Name
            Text(
              "CYBERSHIELD",
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                    color: cyberGreen,
                    letterSpacing: 5,
                    fontWeight: FontWeight.bold,
                  ),
            )
                .animate()
                .fadeIn(delay: 500.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 10),

            // 🧠 Status Text
            const Text(
              "SYSTEM INTEGRITY CHECK...",
              style: TextStyle(color: CyberTheme.textWhite),
            )
                .animate()
                .fadeIn(delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}
