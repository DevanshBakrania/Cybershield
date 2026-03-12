import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart'; // ✨ ADDED Provider
import '../../core/theme.dart';
import '../../services/native_hardware_service.dart';
import '../../core/network_provider.dart'; // ✨ ADDED Network Provider

class MonitorsScreen extends StatefulWidget {
  const MonitorsScreen({super.key});

  @override
  State<MonitorsScreen> createState() => _MonitorsScreenState();
}

class _MonitorsScreenState extends State<MonitorsScreen> {
  bool _isOverlayActive = false;
  Timer? _streamTimer;

  int _selectedStyle = 0;
  final List<String> _hudStyles = ["Classic Box", "Status Bar", "Stealth Minimal", "Terminal Console"];

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
          'ram': ramStr,
          'style': _selectedStyle
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

  void _updateStyle(int index) {
    setState(() => _selectedStyle = index);
    FlutterOverlayWindow.shareData({'style': _selectedStyle});
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
          // ──────────────────────────────────────────────────────────────────
          // ✨ NEW: LIVE NETWORK SPEEDOMETER
          // ──────────────────────────────────────────────────────────────────
          Consumer<NetworkProvider>(
            builder: (context, netProv, child) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                    color: CyberTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CyberTheme.primaryAccent.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(color: CyberTheme.primaryAccent.withValues(alpha: 0.05), blurRadius: 20)
                    ]
                ),
                child: Column(
                  children: [
                    const Text("LIVE BANDWIDTH TRACKER", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSpeedDial(Icons.download_rounded, "DOWNLOAD", netProv.downloadSpeed, netProv.downloadUnit, CyberTheme.primaryAccent),
                        Container(width: 1, height: 50, color: Colors.white10),
                        _buildSpeedDial(Icons.upload_rounded, "UPLOAD", netProv.uploadSpeed, netProv.uploadUnit, const Color(0xFFB388FF)), // Neon purple
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // ──────────────────────────────────────────────────────────────────
          // EXISTING FLOATING OVERLAY CONTROLS
          // ──────────────────────────────────────────────────────────────────
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
              activeTrackColor: CyberTheme.primaryAccent.withValues(alpha: 0.5),
              activeColor: CyberTheme.primaryAccent,
              secondary: const Icon(Icons.desktop_windows, color: Colors.white54),
              title: const Text("Master HUD Overlay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text("Shows RAM, Battery %, and FPS", style: TextStyle(color: Colors.white54, fontSize: 12)),
              value: _isOverlayActive,
              onChanged: _toggleOverlay,
            ),
          ),

          if (_isOverlayActive) ...[
            const SizedBox(height: 32),
            const Text("HUD LAYOUT STYLE", style: TextStyle(color: CyberTheme.primaryAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
            const SizedBox(height: 16),
            ...List.generate(_hudStyles.length, (index) {
              bool isSelected = _selectedStyle == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => _updateStyle(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? CyberTheme.primaryAccent.withValues(alpha: 0.1) : CyberTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? CyberTheme.primaryAccent : Colors.transparent),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_hudStyles[index], style: TextStyle(color: isSelected ? CyberTheme.primaryAccent : Colors.white70, fontWeight: FontWeight.bold)),
                        if (isSelected) const Icon(Icons.check_circle, color: CyberTheme.primaryAccent, size: 20)
                      ],
                    ),
                  ),
                ),
              );
            })
          ]
        ],
      ),
    );
  }

  // ✨ UI Helper for the Speed Dials
  Widget _buildSpeedDial(IconData icon, String label, double speed, String unit, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(speed.toStringAsFixed(1), style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(unit, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}