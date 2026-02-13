import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';

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
    await Future.delayed(const Duration(seconds: 4)); // Increased slightly to enjoy animation
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background, // ✅ Fixed
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // UPDATED ANIMATION: Loops continuously
            const Icon(Icons.fingerprint, size: 80, color: CyberTheme.neonGreen) // ✅ Fixed: accent -> neonGreen
                .animate(onPlay: (controller) => controller.repeat(reverse: true)) // Loop
                .fadeIn(duration: 600.ms)
                .scaleXY(end: 1.1, duration: 600.ms) // Pulse effect
                .then() // Wait a bit
                .shimmer(color: CyberTheme.dangerRed, duration: 1000.ms), // ✅ Fixed: danger -> dangerRed

            const SizedBox(height: 20),

            Text("CYBERSHIELD",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith( // Changed to headlineMedium to match theme definition
                    color: CyberTheme.neonGreen, // ✅ Fixed
                    letterSpacing: 5,
                    fontWeight: FontWeight.bold
                )
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 10),

            const Text("SYSTEM INTEGRITY CHECK...", style: TextStyle(color: CyberTheme.textWhite)) // ✅ Fixed: textMain -> textWhite
                .animate().fadeIn(delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}