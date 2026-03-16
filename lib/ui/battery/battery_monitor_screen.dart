import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/battery_provider.dart';
import '../../core/theme.dart';
import '../../services/native_hardware_service.dart';

class BatteryMonitorScreen extends StatefulWidget {
  const BatteryMonitorScreen({super.key});

  @override
  State<BatteryMonitorScreen> createState() => _BatteryMonitorScreenState();
}

class _BatteryMonitorScreenState extends State<BatteryMonitorScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  double _designCap = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _initBatteryData();
  }

  void _initBatteryData() async {
    // 1. Fetch static design capacity just once (it never changes)
    double cap = await NativeHardwareService.getDesignCapacity();
    if (mounted) {
      setState(() {
        _designCap = cap;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        title: const Text("Battery Monitor", style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // ✨ Wrapped the body in a Consumer!
      body: Consumer<BatteryProvider>(
        builder: (context, batteryProv, child) {
          final liveBattery = batteryProv.batteryData;

          String status = liveBattery["status"] ?? "Unknown";
          bool isCharging = status.contains("Charging");
          Color statusColor = isCharging ? CyberTheme.primaryAccent : Colors.orangeAccent;

          int level = liveBattery["level"] ?? 0;
          double temp = liveBattery["temperature"] ?? 0.0;
          double voltage = liveBattery["voltage"] ?? 0.0;
          String health = liveBattery["health"] ?? "Unknown";
          String technology = liveBattery["technology"]?.toString() ?? "Unknown";

          // ✨ ADDED BACK: Live Current Logic
          int current = liveBattery["current"] ?? 0;
          String currentString = current == 0
              ? "OS Locked (Root Req.)"
              : (current > 0 ? "+$current mA" : "$current mA");

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 180 + (_pulseController.value * 20),
                            height: 180 + (_pulseController.value * 20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor.withValues(alpha: 0.1),
                            ),
                          );
                        }
                    ),
                    Container(
                      width: 150, height: 150,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: statusColor, width: 4), color: CyberTheme.surface),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isCharging ? Icons.bolt : Icons.battery_std, size: 40, color: statusColor),
                          Text("$level%", style: TextStyle(color: statusColor, fontSize: 36, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 30),

                Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 40),

                // ✨ The complete, updated list of metrics!
                _buildMetricRow(Icons.thermostat, "Temperature", "$temp °C ($health)"),
                _buildMetricRow(Icons.science, "Technology", technology),
                _buildMetricRow(Icons.speed, "Live Current", currentString), // ✨ ADDED BACK HERE
                _buildMetricRow(Icons.power, "Voltage", "${voltage.toStringAsFixed(3)} V"),
                _buildMetricRow(Icons.battery_full, "Design Capacity", "${_designCap > 0 ? _designCap.toInt() : 5000} mAh"),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: CyberTheme.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16))),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}