import 'package:flutter/material.dart';
import '../../core/theme.dart';

class WidgetsScreen extends StatelessWidget {
  const WidgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        title: const Text("Widgets BETA", style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: Text("CyberShield Home Widgets", style: TextStyle(color: Colors.white70, fontSize: 16)),
          ),
          const SizedBox(height: 30),

          // Widget Preview 1: The Storage Bar
          _buildPreviewContainer(
            height: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Storage", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("75%", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: 0.75,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                )
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("Show battery, temperature, RAM, ZRAM, storage or SD card usage", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 20),

          // Widget Preview 2: The Large Battery Block
          Center(
            child: _buildPreviewContainer(
              height: 180,
              width: 160,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("My Device", style: TextStyle(color: Colors.white70)),
                  Text("~2 hours", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  Spacer(),
                  Text("75%", style: TextStyle(color: CyberTheme.primaryAccent, fontSize: 40, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("Show battery usage details", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 20),

          // Widget Preview 3: The Full Dashboard Widget
          _buildPreviewContainer(
            height: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Tue, Jul 1", style: TextStyle(color: Colors.white70)),
                    Icon(Icons.refresh, color: Colors.white70, size: 20),
                  ],
                ),
                const Text("19:26", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.smartphone, color: Colors.white54, size: 40),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("My Device", style: TextStyle(color: Colors.white)),
                        Text("Uptime 3d 4h 12m", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                      ],
                    )
                  ],
                ),
                const Spacer(),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("RAM: 75%", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text("Storage: 50%", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("Show comprehensive device info", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.primaryAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Long-press your Home Screen to add widgets!"), backgroundColor: CyberTheme.primaryAccent));
              },
              child: const Text("HOW TO ADD WIDGETS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPreviewContainer({required Widget child, required double height, double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF2A2A3A), // Slightly bluish-grey like the DevCheck widgets
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
          ]
      ),
      child: child,
    );
  }
}