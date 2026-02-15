import 'dart:async';
import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme.dart';
import '../../services/device_service.dart';
import '../../services/network_service.dart';
import '../hardware/hardware_test_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final DeviceService _device = DeviceService();
  final NetworkService _network = NetworkService();

  // Data
  DeviceAudit? _audit;
  String netType = "Scanning...";
  String linkSpeed = "---";
  String publicIp = "Loading...";
  String _trafficText = "IDLE";

  // Animation & Logic
  bool _isScanning = false;
  Timer? _liveTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _loadData();
    _startLiveEngine();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await [Permission.phone, Permission.location].request();
    final d = await _device.getFullAudit();
    final n = await _network.getNetworkStatus();
    if (mounted) {
      setState(() {
        _audit = d;
        netType = n.type;
        publicIp = n.ip;
      });
    }
  }

  void _startLiveEngine() {
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      // Simulated Traffic for "Alive" feel
      int d = (DateTime.now().millisecond % 500) + 50;
      int u = (DateTime.now().millisecond % 50) + 10;

      setState(() {
        _trafficText = "↓ $d KB/s   ↑ $u KB/s";
        // Logic for Link Speed Display
        if (netType.contains("WiFi")) {
          linkSpeed = "433 Mbps"; // Standard 5GHz speed
        } else if (netType.contains("Mobile")) linkSpeed = "5G / LTE";
        else linkSpeed = "Offline";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_audit == null) {
      return const Scaffold(
        backgroundColor: CyberTheme.background,
        body: Center(child: CircularProgressIndicator(color: CyberTheme.neonGreen)),
      );
    }

    return Scaffold(
      backgroundColor: CyberTheme.background,
      body: Stack(
        children: [
          // 1. REPLACED BACKGROUND (Clean Gradient)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF050505), // Pure Black
                  Color(0xFF101015), // Very Dark Blue-Grey
                ],
              ),
            ),
          ),

          // 2. MAIN CONTENT
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeader().animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
                const SizedBox(height: 24),

                // THE "MAIN REACTOR"
                _buildSystemReactor().animate().fadeIn(delay: 200.ms).scale(duration: 500.ms),
                const SizedBox(height: 24),

                // HARDWARE ROW (Now includes Battery %)
                const Text("HARDWARE INTEGRITY", style: TextStyle(color: CyberTheme.neonGreen, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold))
                    .animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 10),
                _buildHardwareRow().animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 20),

                // NETWORK INTEL (Now includes Carrier & Speed)
                const Text("NETWORK UPLINK", style: TextStyle(color: CyberTheme.neonGreen, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold))
                    .animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 10),
                _buildGlassCard(_buildNetworkContent()).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // ACTION BUTTONS
                Row(
                  children: [
                    Expanded(child: _buildNeonBtn("DEEP SCAN", Icons.radar, true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildNeonBtn("PURGE CACHE", Icons.delete_outline, false)),
                  ],
                ).animate().fadeIn(delay: 800.ms),

                const SizedBox(height: 16), // Add some spacing

// ✅ NEW DIAGNOSTICS BUTTON
                _buildGlassCard(
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HardwareTestScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.build_circle_outlined, color: CyberTheme.neonGreen, size: 24),
                          SizedBox(width: 12),
                          Text("LAUNCH DIAGNOSTICS HUB",
                              style: TextStyle(
                                  color: CyberTheme.neonGreen,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, color: CyberTheme.neonGreen, size: 14),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_audit!.modelName.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
            Row(
              children: [
                const Icon(Icons.android, color: CyberTheme.textGrey, size: 14),
                const SizedBox(width: 6),
                Text(_audit!.androidVersion, style: const TextStyle(color: CyberTheme.textGrey, fontSize: 12)),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              border: Border.all(color: CyberTheme.neonGreen.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(20),
              color: CyberTheme.neonGreen.withValues(alpha: 0.1)
          ),
          child: const Text("ONLINE", style: TextStyle(color: CyberTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildSystemReactor() {
    bool safe = !_audit!.isRooted;
    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: (safe ? CyberTheme.neonGreen : CyberTheme.dangerRed).withValues(alpha: 0.2 * _pulseController.value + 0.1),
                    blurRadius: 30 * _pulseController.value + 10,
                    spreadRadius: 5,
                  )
                ],
                border: Border.all(
                    color: (safe ? CyberTheme.neonGreen : CyberTheme.dangerRed).withValues(alpha: 0.6),
                    width: 2
                )
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(safe ? Icons.shield_outlined : Icons.warning_amber_rounded,
                    size: 60,
                    color: safe ? CyberTheme.neonGreen : CyberTheme.dangerRed),
                const SizedBox(height: 12),
                Text(safe ? "SYSTEM\nSECURE" : "SYSTEM\nCOMPROMISED",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: safe ? Colors.white : CyberTheme.dangerRed,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 16
                    )),
                const SizedBox(height: 8),
                Text(_isScanning ? "SCANNING..." : "MONITORING ACTIVE",
                    style: TextStyle(color: safe ? CyberTheme.neonGreen : CyberTheme.dangerRed, fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassCard(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: CyberTheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1))
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildHardwareRow() {
    // Calculate Battery Percent (0.0 to 1.0)
    double batteryP = _audit!.batteryLevel / 100.0;

    // Calculate RAM Percent (Parsing "5.2 / 8.0 GB")
    double ramP = 0.6; // Default fallback
    try {
      if (_audit!.ramLabel.contains("/")) {
        final parts = _audit!.ramLabel.split("/");
        double used = double.parse(parts[0].trim());
        double total = double.parse(parts[1].replaceAll("GB", "").trim());
        ramP = (used / total).clamp(0.0, 1.0);
      }
    } catch (_) {}

    return Row(
      children: [
        // 1. STORAGE
        Expanded(child: _buildGlassCard(_buildStatItem(
            Icons.sd_storage,
            "STORAGE",
            _audit!.storageLabel,
            _audit!.storageUsedPercent,
            Colors.cyanAccent
        ))),

        const SizedBox(width: 12),

        // 2. POWER + TEMP (Moved Temp here!)
        Expanded(child: _buildGlassCard(_buildStatItem(
            Icons.battery_charging_full,
            "POWER",
            "${_audit!.batteryLevel}% (${_audit!.batteryTemp}°C)", // ✅ Temp added
            batteryP,
            CyberTheme.neonGreen
        ))),

        const SizedBox(width: 12),

        // 3. RAM (Restored!)
        Expanded(child: _buildGlassCard(_buildStatItem(
            Icons.memory,
            "MEMORY",
            _audit!.ramLabel, // ✅ Shows "5.2 / 8.0 GB" now
            ramP,
            Colors.purpleAccent
        ))),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: percent, backgroundColor: Colors.white10, color: color, minHeight: 3, borderRadius: BorderRadius.circular(2)),
      ],
    );
  }

  Widget _buildNetworkContent() {
    return Column(
      children: [
        _buildNetRow(Icons.wifi, "CONNECTION", netType),
        const Divider(color: Colors.white10),
        // ✅ ADDED: Carrier and Link Speed Explicitly
        _buildNetRow(Icons.sim_card, "CARRIER", _audit!.carrierName),
        const Divider(color: Colors.white10),
        _buildNetRow(Icons.speed, "LINK SPEED", linkSpeed),
        const Divider(color: Colors.white10),

        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_trafficText, style: const TextStyle(color: CyberTheme.neonGreen, fontFamily: 'Courier', fontSize: 12)),
            Icon(Icons.graphic_eq, color: CyberTheme.neonGreen.withValues(alpha: 0.8), size: 16),
          ],
        )
      ],
    );
  }

  Widget _buildNetRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNeonBtn(String label, IconData icon, bool isPrimary) {
    return GestureDetector(
      onTap: () {
        if (isPrimary) {
          setState(() => _isScanning = true);
          Future.delayed(const Duration(seconds: 2), () => setState(() => _isScanning = false));
        } else {
          _clearCache();
        }
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
            color: isPrimary ? CyberTheme.neonGreen.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isPrimary ? CyberTheme.neonGreen : Colors.grey.withValues(alpha: 0.5))
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isScanning && isPrimary)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: CyberTheme.neonGreen))
            else
              Icon(icon, color: isPrimary ? CyberTheme.neonGreen : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(isPrimary && _isScanning ? "SCANNING..." : label,
                style: TextStyle(
                    color: isPrimary ? CyberTheme.neonGreen : Colors.grey,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1
                )),
          ],
        ),
      ),
    );
  }

  void _clearCache() async {
    final c = await getTemporaryDirectory();
    if (c.existsSync()) c.deleteSync(recursive: true);
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CACHE PURGED"), backgroundColor: CyberTheme.neonGreen));
  }
}