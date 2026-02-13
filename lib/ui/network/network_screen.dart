import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';

class NetworkScreen extends StatelessWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background, // ✅ Fixed: Match App Background
      appBar: AppBar(
        title: const Text("NETWORK", style: TextStyle(letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: CyberTheme.neonGreen), // ✅ Fixed Color
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Added a pulsing radar icon for better visuals
            const Icon(Icons.radar, size: 80, color: CyberTheme.neonGreen) // ✅ Fixed Color
                .animate(onPlay: (controller) => controller.repeat())
                .scaleXY(begin: 0.8, end: 1.2, duration: 1.seconds, curve: Curves.easeInOut)
                .then()
                .scaleXY(begin: 1.2, end: 0.8, duration: 1.seconds, curve: Curves.easeInOut),

            const SizedBox(height: 20),

            const Text(
              "Network Scanning Active...",
              style: TextStyle(
                color: CyberTheme.neonGreen, // ✅ Fixed: accent -> neonGreen
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Analyzing packets & traffic",
              style: TextStyle(color: CyberTheme.textGrey.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}