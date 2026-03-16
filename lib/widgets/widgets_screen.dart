import 'package:flutter/material.dart';
import '../../core/theme.dart';

class WidgetsScreen extends StatelessWidget {
  const WidgetsScreen({super.key});

  final Color widgetBg = const Color(0xFF0A0D3A); // Midnight Blue
  final Color widgetCyan = const Color(0xFF00E5FF); // Neon Cyan

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

          // ──────────────────────────────────────────────────────────────────
          // WIDGET 1: THE CYBER STRIP (4x1)
          // ──────────────────────────────────────────────────────────────────
          _buildPreviewContainer(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _stripItem("[⚙️] RAM:", " 68%"),
                const Text("|", style: TextStyle(color: Colors.white38)),
                _stripItem("[⚡] BAT:", " 85%"),
                const Text("|", style: TextStyle(color: Colors.white38)),
                _stripItem("[🌡️]", " 36°C"),
                Icon(Icons.sync, color: widgetCyan, size: 20),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("The Cyber Strip (4x1) - Sleek horizontal HUD", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 16),

          // ──────────────────────────────────────────────────────────────────
          // WIDGET 2 & 3: POWER NODE & MEMORY NODE (2x2)
          // ──────────────────────────────────────────────────────────────────
          // ✨ FIX: Wrapped in Expanded so they don't overflow the screen!
          Row(
            children: [
              Expanded(
                child: _buildCircularNode(
                  title: "[⚡] PWR_CELL",
                  centerValue: "85%",
                  bottomText: "36°C",
                  progress: 0.85,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCircularNode(
                  title: "[⚙️] SYS_MEM",
                  centerValue: "68%",
                  bottomText: "Storage: 50%",
                  progress: 0.68,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("Power & Memory Nodes (2x2) - Compact circular trackers", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 16),

          // ──────────────────────────────────────────────────────────────────
          // WIDGET 4: NETWORK UPLINK (2x2)
          // ──────────────────────────────────────────────────────────────────
          Center(
            child: _buildPreviewContainer(
              height: 160,
              width: 160,
              child: Stack(
                children: [
                  Align(alignment: Alignment.topRight, child: Icon(Icons.sync, color: widgetCyan, size: 18)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("[🌐] NET_LINK", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      Column(
                        children: [
                          const Text("IP ADDRESS", style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("192.168.1.45", style: TextStyle(color: widgetCyan, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Text("Traffic: 1.2 GB", style: TextStyle(color: Colors.white, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("Network Uplink (2x2) - Live IP and Traffic", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 16),

          // ──────────────────────────────────────────────────────────────────
          // WIDGET 5: THE MASTER CONSOLE (4x3) (✨ Completely Redesigned)
          // ──────────────────────────────────────────────────────────────────
          _buildPreviewContainer(
            height: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Date, Time & Sync
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("THU, MAR 12", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                        const Text("01:05", style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Icon(Icons.sync, color: widgetCyan, size: 24),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle: Device Info
                Row(
                  children: [
                    Icon(Icons.smartphone, color: widgetCyan, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("My Device", style: TextStyle(color: widgetCyan, fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text("CPH2423", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const Text("Uptime 22h 33m", style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // Middle Bars: RAM & STORAGE
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("RAM", style: TextStyle(color: Colors.white54, fontSize: 10)),
                              Text("68%", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: 0.68, color: widgetCyan, backgroundColor: Colors.white10),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("STORAGE", style: TextStyle(color: Colors.white54, fontSize: 10)),
                              Text("88%", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: 0.88, color: widgetCyan, backgroundColor: Colors.white10),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Bottom Row: Battery, Temp, Data
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("BATTERY", style: TextStyle(color: Colors.white54, fontSize: 10)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.battery_charging_full, color: widgetCyan, size: 14),
                            const SizedBox(width: 4),
                            const Text("40%", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("TEMP", style: TextStyle(color: Colors.white54, fontSize: 10)),
                        const SizedBox(height: 2),
                        const Text("36°C", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("DATA", style: TextStyle(color: Colors.white54, fontSize: 10)),
                        const SizedBox(height: 2),
                        const Text("11.1 GB", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("The Master Console - Full dashboard overview", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
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

  // ──────────────────────────────────────────────────────────────────
  // HELPER UI BUILDERS
  // ──────────────────────────────────────────────────────────────────

  Widget _buildPreviewContainer({required Widget child, required double height, double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: widgetBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: widgetCyan.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(color: widgetCyan.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))
          ]
      ),
      child: child,
    );
  }

  Widget _stripItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: widgetCyan, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCircularNode({required String title, required String centerValue, required String bottomText, required double progress}) {
    // Removed the fixed width so it can expand properly!
    return _buildPreviewContainer(
      height: 160,
      child: Stack(
        children: [
          Align(alignment: Alignment.topRight, child: Icon(Icons.sync, color: widgetCyan, size: 18)),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 60, width: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(value: progress, color: widgetCyan, backgroundColor: Colors.white10, strokeWidth: 5),
                    Center(child: Text(centerValue, style: TextStyle(color: widgetCyan, fontSize: 16, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              Text(bottomText, style: const TextStyle(color: Colors.white, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}