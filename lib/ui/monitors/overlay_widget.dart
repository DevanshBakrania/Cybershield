import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../core/theme.dart';

class CyberOverlay extends StatefulWidget {
  const CyberOverlay({super.key});

  @override
  State<CyberOverlay> createState() => _CyberOverlayState();
}

class _CyberOverlayState extends State<CyberOverlay> {
  String _batteryStr = "--%";
  String _ramStr = "-- GB";
  int _fps = 0;

  // Track which layout the user selected
  int _currentStyle = 0;

  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startFpsMonitor();

    FlutterOverlayWindow.overlayListener.listen((event) {
      if (mounted && event is Map) {
        setState(() {
          if (event.containsKey('battery')) _batteryStr = event['battery'];
          if (event.containsKey('ram')) _ramStr = event['ram'];
          if (event.containsKey('style'))
            _currentStyle = event['style']; // Switch style
        });
      }
    });
  }

  void _startFpsMonitor() {
    SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
      _frameCount += timings.length;
      final now = DateTime.now();
      if (now
          .difference(_lastFrameTime)
          .inSeconds >= 1) {
        if (mounted) setState(() => _fps = _frameCount);
        _frameCount = 0;
        _lastFrameTime = now;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: _buildSelectedLayout(),
    );
  }

  Widget _buildSelectedLayout() {
    switch (_currentStyle) {
      case 1:
        return _buildStatusBar(); // 2. The Horizontal Line
      case 2:
        return _buildStealthMinimal(); // 3. No Labels, Just Data
      case 3:
        return _buildTerminalConsole(); // 4. Hacker Console Text
      default:
        return _buildClassicBox(); // 1. The Default Box
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // LAYOUT 0: CLASSIC BOX (Icon + Label + Data stacked vertically)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildClassicBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        border: Border.all(
            color: CyberTheme.primaryAccent.withValues(alpha: 0.6), width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: CyberTheme.primaryAccent.withValues(alpha: 0.3),
              blurRadius: 12)
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconRow(Icons.memory, "RAM:", _ramStr),
          const SizedBox(height: 10),
          _iconRow(Icons.battery_charging_full, "BAT:", _batteryStr),
          const SizedBox(height: 10),
          _iconRow(Icons.speed, "FPS:", "$_fps"),
        ],
      ),
    );
  }

  Widget _iconRow(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: CyberTheme.primaryAccent, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(
            color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // LAYOUT 1: STATUS BAR (Slightly smaller to fit the screen)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      // Reduced padding
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        border: Border.all(
            color: CyberTheme.primaryAccent.withValues(alpha: 0.4), width: 1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.memory, color: CyberTheme.primaryAccent, size: 14),
          // Smaller icons
          const SizedBox(width: 4),
          Text("RAM: $_ramStr", style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          // Smaller text

          const Padding(padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text("|", style: TextStyle(color: Colors.white38))),
          // Tighter spacing

          const Icon(
              Icons.battery_charging_full, color: CyberTheme.primaryAccent,
              size: 14),
          const SizedBox(width: 4),
          Text("BAT: $_batteryStr", style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),

          const Padding(padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text("|", style: TextStyle(color: Colors.white38))),

          const Icon(Icons.speed, color: CyberTheme.primaryAccent, size: 14),
          const SizedBox(width: 4),
          Text("FPS: $_fps", style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // LAYOUT 2: STEALTH MINIMAL (Only Icons & Data, completely removes Labels)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildStealthMinimal() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6), // Very transparent
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stealthRow(Icons.memory, _ramStr),
          const SizedBox(height: 8),
          _stealthRow(Icons.battery_charging_full, _batteryStr),
          const SizedBox(height: 8),
          _stealthRow(Icons.speed, "$_fps"),
        ],
      ),
    );
  }

  Widget _stealthRow(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: CyberTheme.primaryAccent, size: 18),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // LAYOUT 3: NEON RINGS (Circular progress indicators stacked horizontally)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTerminalConsole() {
    // Keeping the method name the same so the switch statement works!
    // Extract numbers to calculate ring percentages
    double ramVal = double.tryParse(_ramStr.split(" ")[0]) ?? 0.0;
    double ramPct = (ramVal / 12.0).clamp(0.0, 1.0); // Assuming 12GB max
    double batPct = (double.tryParse(_batteryStr.replaceAll("%", "")) ?? 0.0) /
        100.0;
    double fpsPct = (_fps / 60.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _neonRing(ramPct, Icons.memory, _ramStr),
          const SizedBox(width: 12),
          _neonRing(batPct, Icons.battery_charging_full, _batteryStr),
          const SizedBox(width: 12),
          _neonRing(fpsPct, Icons.speed, "$_fps"),
        ],
      ),
    );
  }

  Widget _neonRing(double percent, IconData icon, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36, height: 36,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percent,
                backgroundColor: Colors.white10,
                color: CyberTheme.primaryAccent,
                strokeWidth: 3,
              ),
              Center(child: Icon(icon, color: Colors.white70, size: 16)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}