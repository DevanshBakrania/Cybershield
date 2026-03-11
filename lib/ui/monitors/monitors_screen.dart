import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../core/theme.dart';
import '../../services/native_hardware_service.dart';

class MonitorsScreen extends StatefulWidget {
  const MonitorsScreen({super.key});

  @override
  State<MonitorsScreen> createState() => _MonitorsScreenState();
}

class _MonitorsScreenState extends State<MonitorsScreen> {
  bool _isOverlayActive = false;
  Timer? _streamTimer;

  @override
  void initState() {
    super.initState();
    _checkOverlayStatus();
  }

  void _checkOverlayStatus() async {
    bool isActive = await FlutterOverlayWindow.isActive();
    if (mounted) setState(() => _isOverlayActive = isActive);
    if (isActive) _startDataStream();
  }

  void _startDataStream() {
    _streamTimer?.cancel();
    _streamTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final bat = await NativeHardwareService.getLiveBatteryHardware();
        final mem = await NativeHardwareService.getDeepMemoryInfo();

        String batStr = "${bat['level'] ?? '--'}%";
        double memTotal = (mem["MemTotal"] ?? 0) / 1048576 / 1024;
        double memAvailable = (mem["MemAvailable"] ?? 0) / 1048576 / 1024;
        String ramStr = "${(memTotal - memAvailable).toStringAsFixed(1)} GB";

        await FlutterOverlayWindow.shareData({
          'battery': batStr,
          'ram': ramStr
        });
      } catch (e) {
        debugPrint("Stream error: $e");
      }
    });
  }

  void _toggleOverlay(bool val) async {
    if (val) {
      bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
      if (!isGranted) {
        bool? req = await FlutterOverlayWindow.requestPermission();
        if (req != true) return;
      }

      await FlutterOverlayWindow.showOverlay(
        height: 450,
        width: 850,
        enableDrag: true,
        overlayTitle: "CyberShield HUD",
        overlayContent: "Hardware Monitor Active",
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.center,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.none,
      );

      if (mounted) setState(() => _isOverlayActive = true);
      _startDataStream();

    } else {
      await FlutterOverlayWindow.closeOverlay();
      if (mounted) setState(() => _isOverlayActive = false);
      _streamTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        title: const Text("Floating Monitors", style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: CyberTheme.primaryAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: CyberTheme.primaryAccent)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: CyberTheme.primaryAccent),
                SizedBox(width: 12),
                Expanded(child: Text("Launch a floating HUD to track live hardware stats while using other apps.", style: TextStyle(color: Colors.white70, fontSize: 12))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(color: CyberTheme.surface, borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              activeColor: CyberTheme.primaryAccent,
              secondary: const Icon(Icons.desktop_windows, color: Colors.white54),
              title: const Text("Master HUD Overlay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text("Shows RAM, Battery %, and FPS", style: TextStyle(color: Colors.white54, fontSize: 12)),
              value: _isOverlayActive,
              onChanged: _toggleOverlay,
            ),
          ),
        ],
      ),
    );
  }
}