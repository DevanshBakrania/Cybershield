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
        });
      }
    });
  }

  void _startFpsMonitor() {
    SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
      _frameCount += timings.length;
      final now = DateTime.now();
      if (now.difference(_lastFrameTime).inSeconds >= 1) {
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          border: Border.all(color: CyberTheme.primaryAccent.withValues(alpha: 0.6), width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: CyberTheme.primaryAccent.withValues(alpha: 0.3), blurRadius: 12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.memory, color: CyberTheme.primaryAccent, size: 20),
                const SizedBox(width: 8),
                Flexible(child: Text("RAM: $_ramStr", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.battery_charging_full, color: CyberTheme.primaryAccent, size: 20),
                const SizedBox(width: 8),
                Flexible(child: Text("BAT: $_batteryStr", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed, color: CyberTheme.primaryAccent, size: 20),
                const SizedBox(width: 8),
                Flexible(child: Text("FPS: $_fps", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}