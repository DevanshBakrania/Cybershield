import 'dart:async';
import 'dart:math' as math;
import 'package:csh/widgets/widgets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../tools/tools_screen.dart';
import '../benchmarks/benchmarks_screen.dart';
import '../../core/theme.dart';
import '../../services/device_service.dart';
// ✨ REMOVED the unused 'installed_apps' imports because our Native Kotlin Engine is better!
import '../battery/battery_monitor_screen.dart';
import '../monitors/monitors_screen.dart';
import '../../services/native_hardware_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// Providers
import '../../core/battery_provider.dart';
import '../../core/cpu_provider.dart';
import '../../core/ram_provider.dart';

// Tab Screens
import '../hardware/hardware_test_screen.dart';
import '../feed/security_feed_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _userAppsCount = 0;
  int _systemAppsCount = 0;

  Map<String, dynamic> _netInfo = {};
  Map<String, dynamic> _displayInfo = {};
  Map<String, dynamic> _osInfo = {};
  double _designCapacity = 0.0;

  // Services & Data
  final DeviceService _device = DeviceService();
  DeviceAudit? _audit;
  String _netType = "Scanning...";

  // Animations & Timers
  late AnimationController _waveController;
  StreamSubscription? _netSub;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _loadDeviceData();
    _netSub = Connectivity().onConnectivityChanged.listen((result) async {
      _updateNetworkString(result);

      await Future.delayed(const Duration(milliseconds: 2500));

      if (mounted) {
        final netData = await NativeHardwareService.getDeepNetworkInfo();
        setState(() {
          _netInfo = netData;
        });
      }
    });
  }

  Future<void> _loadDeviceData() async {
    await Permission.phone.request();
    await Permission.location.request();
    final data = await _device.getFullAudit();
    final net = await Connectivity().checkConnectivity();

    // Still fetch once for widget syncs, but NO setStates needed for UI
    final memData = await NativeHardwareService.getDeepMemoryInfo();

    final capacity = await NativeHardwareService.getDesignCapacity();
    final netData = await NativeHardwareService.getDeepNetworkInfo();
    final displayData = await NativeHardwareService.getDeepDisplayInfo();
    final osData = await NativeHardwareService.getDeepOsInfo();

    try {
      final realData = await NativeHardwareService.getWidgetRealData();

      double totalStorageGB = (realData['totalStorage'] ?? 0) / (1024 * 1024 * 1024);
      double usedStorageGB = (realData['usedStorage'] ?? 0) / (1024 * 1024 * 1024);
      int storagePercentInt = totalStorageGB > 0 ? ((usedStorageGB / totalStorageGB) * 100).toInt() : 0;

      double networkMB = (realData['networkBytes'] ?? 0) / (1024 * 1024);
      String networkStr = networkMB > 1024 ? "${(networkMB / 1024).toStringAsFixed(2)} GB" : "${networkMB.toStringAsFixed(1)} MB";

      int uptimeMillis = realData['uptimeMillis'] ?? 0;
      int uptimeHours = (uptimeMillis / (1000 * 60 * 60)).floor();
      int uptimeMins = ((uptimeMillis / (1000 * 60)) % 60).floor();
      String uptimeStr = "Uptime ${uptimeHours}h ${uptimeMins}m";

      double memTotal = (memData["MemTotal"] ?? 0) / 1048576 / 1024;
      double memAvailable = (memData["MemAvailable"] ?? 0) / 1048576 / 1024;
      int ramPercentInt = memTotal > 0 ? (((memTotal - memAvailable) / memTotal) * 100).toInt() : 0;
      int batPercentInt = data.batteryLevel.toInt();
      double batTemp = data.batteryTemp.toDouble();

      await HomeWidget.saveWidgetData<String>('model', realData['model'] ?? "CyberShield Device");
      await HomeWidget.saveWidgetData<String>('uptime', uptimeStr);
      await HomeWidget.saveWidgetData<String>('temp', '${batTemp.toInt()}°C');
      await HomeWidget.saveWidgetData<String>('data', networkStr);

      await HomeWidget.saveWidgetData<int>('ram_pct', ramPercentInt);
      await HomeWidget.saveWidgetData<int>('storage_pct', storagePercentInt);
      await HomeWidget.saveWidgetData<int>('bat_pct', batPercentInt);

      await HomeWidget.updateWidget(name: 'CyberWidgetProvider');
    } catch (e) {
      debugPrint("Widget update failed: $e");
    }

    try {
      final Map<dynamic, dynamic> appCounts = await const MethodChannel('com.cybershield/hardware').invokeMethod('getAppCounts');
      if (mounted) {
        setState(() {
          _userAppsCount = appCounts['userApps'] ?? 0;
          _systemAppsCount = appCounts['systemApps'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Native App Count failed: $e");
    }

    if (mounted) {
      setState(() {
        _audit = data;
        _designCapacity = capacity;
        _netInfo = netData;
        _displayInfo = displayData;
        _osInfo = osData;
        _updateNetworkString(net);
      });
    }
  }

  void _updateNetworkString(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.wifi)) {
      _netType = "Wi-Fi Connected";
    } else if (result.contains(ConnectivityResult.mobile)) {
      _netType = "Mobile Data Active";
    } else {
      _netType = "Offline";
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _netSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_audit == null) {
      return const Scaffold(
        backgroundColor: CyberTheme.background,
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: CyberTheme.primaryAccent),
                SizedBox(height: 16),
                Text("ANALYZING HARDWARE...", style: TextStyle(color: CyberTheme.primaryAccent, letterSpacing: 2, fontSize: 12))
              ],
            )
        ),
      );
    }

    final List<Widget> pages = [
      _buildOverviewTab(),
      const SecurityFeedScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: CyberTheme.background,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0A0A0A),
        selectedItemColor: CyberTheme.primaryAccent,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.security_outlined), activeIcon: Icon(Icons.security), label: "Feed"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DASHBOARD LAYOUT
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final size = MediaQuery.of(context).size;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final screenRes = "${(size.width * pixelRatio).toInt()} x ${(size.height * pixelRatio).toInt()}";

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✨ CENTERED LOGO FIX
          Center(
            child: const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                  "CYBERSHIELD",
                  style: TextStyle(
                      color: CyberTheme.primaryAccent,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0
                  )
              ),
            ),
          ).animate().fadeIn().slideY(),

          // ✨ CPU NOW DRIVEN BY PROVIDER
          Consumer<CpuProvider>(
            builder: (context, cpuProv, child) {
              return _buildCpuHeroCard(cpuProv.cpuFreqs, cpuProv.cpuInfo).animate().fadeIn(delay: 100.ms).slideY();
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Consumer<BatteryProvider>(
                  builder: (context, batteryProv, child) {
                    final batData = batteryProv.batteryData;
                    final int batLevel = batData['level'] ?? _audit?.batteryLevel.toInt() ?? 0;
                    final double batTemp = batData['temperature'] ?? _audit?.batteryTemp.toDouble() ?? 0.0;
                    final String batStatus = batData['status'] ?? "Healthy";

                    return _buildVitalCard(
                        Icons.battery_charging_full,
                        "Battery",
                        "$batLevel%",
                        "${batTemp.toStringAsFixed(1)}°C\n$batStatus",
                        onTap: _showBatteryDetails
                    );
                  },
                ).animate().fadeIn(delay: 200.ms),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildVitalCard(Icons.signal_cellular_alt, "Network", _audit!.carrierName, _netType, onTap: _showNetworkDetails).animate().fadeIn(delay: 300.ms)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildVitalCard(Icons.apps, "Apps", "${_userAppsCount + _systemAppsCount}", "$_userAppsCount User\n$_systemAppsCount System", onTap: _showAppsDetails).animate().fadeIn(delay: 400.ms)),
              const SizedBox(width: 12),
              Expanded(child: _buildVitalCard(Icons.smartphone, "Display", "Active", "$screenRes\nResolution", onTap: () => _showDisplayDetails(screenRes)).animate().fadeIn(delay: 500.ms)),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // ✨ RAM NOW DRIVEN BY PROVIDER
              Expanded(
                child: Consumer<RamProvider>(
                  builder: (context, ramProv, child) {
                    double ramPercent = 0.5;
                    final memInfo = ramProv.memInfo;
                    if (memInfo.isNotEmpty) {
                      double memTotal = (memInfo["MemTotal"] ?? 0) / 1048576 / 1024;
                      double memAvailable = (memInfo["MemAvailable"] ?? 0) / 1048576 / 1024;
                      if (memTotal > 0) ramPercent = ((memTotal - memAvailable) / memTotal).clamp(0.0, 1.0);
                    } else {
                      try {
                        if (_audit!.ramLabel.contains("/")) {
                          final parts = _audit!.ramLabel.split("/");
                          double used = double.parse(parts[0].trim());
                          double total = double.parse(parts[1].replaceAll("GB", "").trim());
                          ramPercent = (used / total).clamp(0.0, 1.0);
                        }
                      } catch (_) {}
                    }
                    return _buildRingVitalCard("RAM", ramPercent, _audit!.ramLabel, onTap: () => _showRamDetails(ramProv.memInfo));
                  },
                ).animate().fadeIn(delay: 600.ms),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildRingVitalCard("Storage", _audit!.storageUsedPercent, _audit!.storageLabel, onTap: _showStorageDetails).animate().fadeIn(delay: 700.ms)),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _buildVitalCard(Icons.explore, "Sensors", "Active", "Live Tracking", onTap: _showSensorsDetails).animate().fadeIn(delay: 750.ms)),
              const SizedBox(width: 12),
              Expanded(child: _buildVitalCard(Icons.camera_alt, "Camera", "Ready", "Hardware Specs", onTap: _showCameraDetails).animate().fadeIn(delay: 750.ms)),
            ],
          ),
          const SizedBox(height: 16),

          _buildActionHub().animate().fadeIn(delay: 800.ms).slideY(),
          const SizedBox(height: 16),

          _buildFooterCard().animate().fadeIn(delay: 900.ms).slideY(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BOTTOM SHEET POP-UPS (THE DETAILS)
  // ─────────────────────────────────────────────────────────────────────────────

  void _showDetailSheet(String title, IconData icon, Widget content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberTheme.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: CyberTheme.primaryAccent, size: 28),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(color: CyberTheme.primaryAccent, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10, height: 1)),

            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: content,
              ),
            ),

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(color: Colors.grey))),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String title, String leftLabel, String rightLabel, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(rightLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: percent, backgroundColor: Colors.white10, color: color, minHeight: 8, borderRadius: BorderRadius.circular(4)),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showOsDetails() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberTheme.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: CyberTheme.primaryAccent))),
    );

    final osData = await NativeHardwareService.getDeepOsInfo();

    if (!mounted) return;
    Navigator.pop(context);

    String androidVer = osData["androidVersion"] ?? "Unknown";
    String sdkInt = (osData["sdkInt"] ?? 0).toString();
    String patch = osData["securityPatch"] ?? "Unknown";
    String kernel = osData["kernel"] ?? "Unknown";
    String selinux = osData["selinux"] ?? "Unknown";
    String baseband = osData["baseband"] ?? "Unknown";
    String oemBuild = osData["oemBuild"] ?? "Unknown";
    String instructionSets = osData["instructionSets"] ?? "Unknown";
    String activeSlot = osData["activeSlot"] ?? "";
    if (activeSlot.isEmpty) activeSlot = "Unknown";

    String codeName = "";
    if (sdkInt == "35") codeName = " (Vanilla Ice Cream)";
    if (sdkInt == "34") codeName = " (Upside Down Cake)";
    if (sdkInt == "33") codeName = " (Tiramisu)";

    if (patch.length == 10 && patch.contains("-")) {
      try {
        DateTime d = DateTime.parse(patch);
        const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        patch = "${months[d.month - 1]} ${d.day}, ${d.year}";
      } catch (_) {}
    }

    _showDetailSheet("Operating System", Icons.android, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow("Android Version", "Android $androidVer$codeName"),
        _buildDetailRow("Security patch", patch),
        _buildDetailRow("Build", oemBuild),
        _buildDetailRow("Kernel", kernel),

        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10, height: 1)),

        const Text("Hardware Architecture", style: TextStyle(color: CyberTheme.primaryAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildDetailRow("Architecture", "${_audit?.architecture} (64-bit)"),
        _buildDetailRow("Instruction sets", instructionSets),
        _buildDetailRow("Active slot", activeSlot),

        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10, height: 1)),

        const Text("Security & Baseband", style: TextStyle(color: CyberTheme.primaryAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildDetailRow("SELinux State", selinux),
        _buildDetailRow("Baseband", baseband),
      ],
    ));
  }

  void _showSensorsDetails() {
    _showDetailSheet("Live Sensors Matrix", Icons.explore, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Accelerometer (m/s²)", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),

        LiveSensorGraph(stream: accelerometerEventStream(), maxY: 20.0),
        const SizedBox(height: 16),

        StreamBuilder<AccelerometerEvent>(
          stream: accelerometerEventStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sensorAxis("X", snapshot.data!.x, Colors.redAccent),
                _sensorAxis("Y", snapshot.data!.y, Colors.greenAccent),
                _sensorAxis("Z", snapshot.data!.z, Colors.blueAccent),
              ],
            );
          },
        ),

        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10, height: 1)),

        const Text("Gyroscope (rad/s)", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),

        LiveSensorGraph(stream: gyroscopeEventStream(), maxY: 10.0),
        const SizedBox(height: 16),

        StreamBuilder<GyroscopeEvent>(
          stream: gyroscopeEventStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sensorAxis("X", snapshot.data!.x, Colors.redAccent),
                _sensorAxis("Y", snapshot.data!.y, Colors.greenAccent),
                _sensorAxis("Z", snapshot.data!.z, Colors.blueAccent),
              ],
            );
          },
        ),
      ],
    ));
  }

  Widget _sensorAxis(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(value.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'monospace')),
      ],
    );
  }

  void _showCameraDetails() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: CyberTheme.primaryAccent))),
    );

    final cameraData = await NativeHardwareService.getDeepCameraInfo();

    if (!mounted) return;
    Navigator.pop(context);

    _showDetailSheet("Camera Hardware", Icons.camera_alt, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Physical Lenses", style: TextStyle(color: CyberTheme.primaryAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        if (cameraData.isEmpty)
          const Text("Could not read camera hardware.", style: TextStyle(color: Colors.white54))
        else
          ...cameraData.map((cam) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(cam["facing"].contains("Front") ? Icons.camera_front : Icons.camera_rear, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text(cam["facing"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailRow("Megapixels", cam["megapixels"]),
                _buildDetailRow("Max Resolution", cam["resolution"]),
                _buildDetailRow("Aperture", cam["apertures"]),
                _buildDetailRow("Focal Length", cam["focalLengths"]),
              ],
            ),
          )),
      ],
    ));
  }

  void _showBatteryDetails() {
    _showDetailSheet("Battery Hardware", Icons.battery_charging_full, Consumer<BatteryProvider>(
      builder: (context, batteryProv, child) {
        final liveBattery = batteryProv.batteryData;
        int level = liveBattery["level"] ?? _audit?.batteryLevel.toInt() ?? 0;
        double temp = liveBattery["temperature"] ?? _audit?.batteryTemp.toDouble() ?? 0.0;
        double voltage = liveBattery["voltage"] ?? 0.0;
        String status = liveBattery["status"] ?? "Unknown";
        String health = liveBattery["health"] ?? "Unknown";
        String technology = liveBattery["technology"] ?? "Unknown";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$level%", style: const TextStyle(color: CyberTheme.primaryAccent, fontSize: 32, fontWeight: FontWeight.bold)),
                    Text(status, style: TextStyle(color: status.contains("Charging") ? CyberTheme.primaryAccent : Colors.white70, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${temp.toStringAsFixed(1)}°C", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text("Temperature", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                )
              ],
            ),

            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10, height: 1)),

            const Text("Live Physics", style: TextStyle(color: CyberTheme.primaryAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildDetailRow("Technology", technology),
            _buildDetailRow("Voltage", "${voltage.toStringAsFixed(3)} V"),

            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10, height: 1)),

            const Text("Hardware Specs", style: TextStyle(color: CyberTheme.primaryAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildDetailRow("Status", status),
            _buildDetailRow("Health", health),
            _buildDetailRow("Design Capacity", _designCapacity > 0 ? "${_designCapacity.toInt()} mAh" : "Unknown"),
          ],
        );
      },
    ));
  }

  void _showNetworkDetails() {
    String ssid = _netInfo["ssid"] ?? "Unknown";
    int linkSpeed = _netInfo["linkSpeed"] ?? 0;
    int rssi = _netInfo["rssi"] ?? 0;

    String wifiIp = _netInfo["wifi_ip"] ?? "Disconnected";
    String cellIp = _netInfo["cellular_ip"] ?? "Disconnected";

    String phoneType = _netInfo["phoneType"] ?? "Unknown";
    String mobileDataStatus = _netInfo["mobileDataStatus"] ?? "Unknown";
    String operator = _netInfo["operator"] ?? "Unknown";
    String simState = _netInfo["simState"] ?? "Unknown";

    String displaySsid = (ssid == "<unknown ssid>") ? "Location Permission Required" : ssid;

    _showDetailSheet("Network & Connectivity", Icons.wifi_tethering, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Wi-Fi Details", style: TextStyle(color: CyberTheme.primaryAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildDetailRow("Status", _netType.contains("Wi-Fi") ? "Connected" : "Disconnected"),
        _buildDetailRow("Network (SSID)", displaySsid),
        _buildDetailRow("IPv4 Address", wifiIp),
        _buildDetailRow("Link Speed", "$linkSpeed Mbps"),
        _buildDetailRow("Signal Strength", "$rssi dBm"),

        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10, height: 1)),

        const Text("Cellular Data Details", style: TextStyle(color: CyberTheme.primaryAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildDetailRow("Carrier / Operator", operator),
        _buildDetailRow("IPv4 Address", cellIp),
        _buildDetailRow("Data Status", mobileDataStatus),
        _buildDetailRow("Phone Type", phoneType),
        _buildDetailRow("SIM State", simState),
      ],
    ));
  }

  void _showDisplayDetails(String fallbackRes) {
    int pW = _displayInfo["physicalWidth"] ?? 0;
    int pH = _displayInfo["physicalHeight"] ?? 0;
    int lW = _displayInfo["logicalWidth"] ?? 0;
    int lH = _displayInfo["logicalHeight"] ?? 0;

    double exactPpi = _displayInfo["averagePpi"] ?? 0.0;
    int softwareDpi = _displayInfo["densityDpi"] ?? 0;

    double inches = _displayInfo["screenInches"] ?? 0.0;
    double hz = _displayInfo["refreshRate"] ?? 0.0;

    int pMax = math.max(pW, pH);
    int pMin = math.min(pW, pH);
    String physicalRes = pMax > 0 ? "$pMax x $pMin" : fallbackRes;

    int lMax = math.max(lW, lH);
    int lMin = math.min(lW, lH);
    String logicalRes = lMax > 0 ? "$lMax x $lMin" : "Unknown";

    int mm = (inches * 25.4).round();
    String screenSize = inches > 0 ? "${inches.toStringAsFixed(1)} in / $mm mm" : "Unknown";

    String hardwareDensity = exactPpi > 0 ? "${exactPpi.toStringAsFixed(1)} ppi" : "Unknown";
    String softwareDensity = softwareDpi > 0 ? "$softwareDpi dpi" : "Unknown";
    String refresh = hz > 0 ? "${hz.toInt()} Hz" : "Unknown";
    String gpu = "Mali-G610 MC6";

    _showDetailSheet("Display & Graphics", Icons.smartphone, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow("GPU", gpu),
        _buildDetailRow("Resolution", physicalRes),
        _buildDetailRow("Hardware Density", hardwareDensity),
        _buildDetailRow("Screen size (estimated)", screenSize),
        _buildDetailRow("Frame rate", refresh),

        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10, height: 1)),

        const Text("Software Metrics (Logical)", style: TextStyle(color: CyberTheme.primaryAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildDetailRow("Logical Resolution", logicalRes),
        _buildDetailRow("Logical Density", softwareDensity),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.white54, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text("Hardware Density is the exact physical LED count per inch. Logical Density is how the Android OS scales text and UI elements.", style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4))),
            ],
          ),
        )
      ],
    ));
  }

  void _showCpuDetails(Map<String, dynamic> cpuInfo) {
    int cores = cpuInfo["coreCount"] ?? 0;
    List<dynamic> curFreqs = cpuInfo["currentFreqs"] ?? [];
    List<dynamic> maxFreqs = cpuInfo["maxFreqs"] ?? [];
    String hardware = cpuInfo["hardware"] ?? "Unknown SoC";

    _showDetailSheet("CPU Details", Icons.memory, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow("SoC Model", hardware == "Unknown SoC" ? _audit!.processor : hardware),
        _buildDetailRow("Architecture", _audit?.architecture ?? "Unknown"),
        _buildDetailRow("Hardware Cores", "$cores"),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text("Live Core Frequencies", style: TextStyle(color: CyberTheme.primaryAccent, fontWeight: FontWeight.bold)),
        ),

        ...List.generate(cores, (index) {
          double current = 0;
          double max = 1;

          if (index < curFreqs.length && curFreqs[index] > 0) current = (curFreqs[index] / 1000);
          if (index < maxFreqs.length && maxFreqs[index] > 0) max = (maxFreqs[index] / 1000);

          double percent = (current / max).clamp(0.0, 1.0);
          bool isRestricted = (index < curFreqs.length && curFreqs[index] <= 0);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text("Core $index", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: isRestricted ? 1.0 : percent,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isRestricted ? Colors.white10 : CyberTheme.primaryAccent
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                      isRestricted ? "OS Locked" : "${current.toInt()} MHz",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: isRestricted ? Colors.redAccent : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold
                      )
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3))),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, color: Colors.redAccent, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text("Android 8+ restricts live CPU frequency and thermal reading to prevent side-channel timing attacks. Root access is required to bypass this OS security lock.", style: TextStyle(color: Colors.redAccent, fontSize: 11))),
            ],
          ),
        )
      ],
    ));
  }

  void _showRamDetails(Map<String, int> memInfo) {
    const double bytesToGB = 1000000000.0;

    double memTotal = (memInfo["MemTotal"] ?? 0) / bytesToGB;
    double memAvailable = (memInfo["MemAvailable"] ?? 0) / bytesToGB;
    double memFree = (memInfo["MemFree"] ?? 0) / bytesToGB;
    double cached = (memInfo["Cached"] ?? 0) / bytesToGB;
    double buffers = (memInfo["Buffers"] ?? 0) / bytesToGB;

    double memUsed = memTotal - memAvailable;
    double realRamPercent = memTotal > 0 ? (memUsed / memTotal) : 0;

    double zramTotal = (memInfo["SwapTotal"] ?? 0) / bytesToGB;
    double zramFree = (memInfo["SwapFree"] ?? 0) / bytesToGB;
    double zramUsed = zramTotal - zramFree;
    double zramPercent = zramTotal > 0 ? (zramUsed / zramTotal) : 0;

    _showDetailSheet("Memory (RAM & ZRAM)", Icons.memory, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow("Total RAM", "${memTotal.toStringAsFixed(2)} GB"),
        const SizedBox(height: 16),

        _buildProgressBar("System RAM", "${memUsed.toStringAsFixed(2)} GB used", "${memAvailable.toStringAsFixed(2)} GB free", realRamPercent, CyberTheme.primaryAccent),

        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white10, height: 1)),

        const Text("Deep Linux Status", style: TextStyle(color: CyberTheme.primaryAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildDetailRow("Available", "${memAvailable.toStringAsFixed(2)} GB"),
        _buildDetailRow("Free", "${memFree.toStringAsFixed(2)} GB"),
        _buildDetailRow("Cached", "${cached.toStringAsFixed(2)} GB"),
        _buildDetailRow("Buffers", "${buffers.toStringAsFixed(2)} GB"),

        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10, height: 1)),

        if (zramTotal > 0) ...[
          _buildProgressBar("ZRAM (Swap)", "${zramUsed.toStringAsFixed(2)} GB used", "${zramFree.toStringAsFixed(2)} GB free", zramPercent, Colors.lightBlue),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.white54, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text("ZRAM is a compressed block of virtual memory inside your physical RAM. Android uses it to store background apps efficiently so it doesn't have to kill them.", style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4))),
              ],
            ),
          )
        ]
      ],
    ));
  }

  void _showStorageDetails() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberTheme.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: CyberTheme.primaryAccent))),
    );

    final storageData = await NativeHardwareService.getDeepStorageInfo();

    if (!mounted) return;
    Navigator.pop(context);

    const double bytesToGB = 1000000000.0;

    double dataTotal = (storageData["dataTotal"] ?? 0) / bytesToGB;
    double dataUsed = (storageData["dataUsed"] ?? 0) / bytesToGB;
    double dataFree = (storageData["dataFree"] ?? 0) / bytesToGB;
    double dataPercent = dataTotal > 0 ? (dataUsed / dataTotal) : 0;

    double sysTotal = (storageData["systemTotal"] ?? 0) / bytesToGB;
    double sysUsed = (storageData["systemUsed"] ?? 0) / bytesToGB;
    double sysFree = (storageData["systemFree"] ?? 0) / bytesToGB;
    double sysPercent = sysTotal > 0 ? (sysUsed / sysTotal) : 0;

    _showDetailSheet("Internal Storage", Icons.storage, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressBar("User Data (/data)", "${dataUsed.toStringAsFixed(2)} GB used", "${dataFree.toStringAsFixed(2)} GB free", dataPercent, CyberTheme.primaryAccent),

        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white10, height: 1)),

        _buildProgressBar("System OS (/root)", "${sysUsed.toStringAsFixed(2)} GB used", "${sysFree.toStringAsFixed(2)} GB free", sysPercent, Colors.orangeAccent),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.white54, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text("Why is your total storage lower than advertised? Manufacturers sell phones using Base-10 (1 GB = 1,000,000,000 bytes). Android OS reads memory in Base-2 (1 GiB = 1,073,741,824 bytes). This means a '256GB' phone physically reads as ~238GB inside the operating system.", style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4))),
            ],
          ),
        )
      ],
    ));
  }

  void _showAppsDetails() {
    int total = _userAppsCount + _systemAppsCount;
    double userRatio = total > 0 ? (_userAppsCount / total) : 0;

    _showDetailSheet("Installed Apps", Icons.apps, Column(
      children: [
        SizedBox(
          height: 180,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 140, height: 140,
                  child: CircularProgressIndicator(value: userRatio, backgroundColor: Colors.white12, color: CyberTheme.primaryAccent, strokeWidth: 20),
                ),
              ),
              Center(
                child: Text("$total\nTotal", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(children: [Icon(Icons.square, color: CyberTheme.primaryAccent, size: 16), const SizedBox(width: 8), Text("User apps ($_userAppsCount)", style: const TextStyle(color: Colors.white70))]),
            Row(children: [const Icon(Icons.square, color: Colors.white12, size: 16), const SizedBox(width: 8), Text("System apps ($_systemAppsCount)", style: const TextStyle(color: Colors.white70))]),
          ],
        )
      ],
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // UI WIDGET BUILDERS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildVitalCard(IconData icon, String title, String mainValue, String subText, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: CyberTheme.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)), const Icon(Icons.more_vert, color: Colors.grey, size: 14)]),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: CyberTheme.primaryAccent, size: 28),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(mainValue, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CyberTheme.primaryAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subText, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3)),
                ])),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRingVitalCard(String title, double percent, String subText, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: CyberTheme.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)), const Icon(Icons.more_vert, color: Colors.grey, size: 14)]),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 45, height: 45,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(value: percent, backgroundColor: Colors.white10, color: CyberTheme.primaryAccent, strokeWidth: 4),
                      Center(child: Text("${(percent * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text("${subText.replaceAll(" / ", " used\n")} total", style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3)))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCpuHeroCard(List<int> cpuFreqs, Map<String, dynamic> cpuInfo) {
    return GestureDetector(
        onTap: () => _showCpuDetails(cpuInfo),
        child: Container(
          height: 160,
          decoration: BoxDecoration(color: CyberTheme.surface, borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Positioned(bottom: 0, left: 0, right: 0, height: 80, child: AnimatedBuilder(animation: _waveController, builder: (context, child) => CustomPaint(painter: CpuWavePainter(_waveController.value)))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("CPU Status (${_audit!.coreCount} Cores)", style: const TextStyle(color: Colors.grey, fontSize: 12)), const Icon(Icons.more_vert, color: Colors.grey, size: 16)]),
                    const Spacer(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_cpuCoreText("${cpuFreqs[0]} MHz"), _cpuCoreText("${cpuFreqs[1]} MHz")]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_cpuCoreText("${cpuFreqs[2]} MHz"), _cpuCoreText("${cpuFreqs[3]} MHz")]),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        )
    );
  }

  Widget _cpuCoreText(String text) {
    return Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _buildActionHub() {
    return Container(
      decoration: BoxDecoration(color: CyberTheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildActionBtn(Icons.checklist, "Tests", onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const HardwareTestScreen())); })),
              _buildDivider(vertical: true),
              Expanded(child: _buildActionBtn(Icons.build, "Tools", onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen())); })),
              _buildDivider(vertical: true),
              Expanded(child: _buildActionBtn(Icons.widgets, "Widgets", onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const WidgetsScreen())); })),
            ],
          ),
          _buildDivider(vertical: false),
          Row(
            children: [
              Expanded(child: _buildActionBtn(Icons.show_chart, "Monitors", onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const MonitorsScreen())); })),
              _buildDivider(vertical: true),
              Expanded(child: _buildActionBtn(Icons.speed, "Benchmarks", onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const BenchmarksScreen())); })),
              _buildDivider(vertical: true),
              Expanded(child: _buildActionBtn(Icons.battery_charging_full, "Battery monitor", onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const BatteryMonitorScreen())); })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(children: [Icon(icon, color: CyberTheme.primaryAccent, size: 24), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11))]),
      ),
    );
  }

  Widget _buildDivider({required bool vertical}) {
    return Container(width: vertical ? 1 : double.infinity, height: vertical ? 70 : 1, color: Colors.white10);
  }

  Widget _buildBrandLogo(String modelName) {
    String name = modelName.toLowerCase();

    if (name.contains("oneplus")) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("1", style: TextStyle(color: Colors.redAccent, fontSize: 26, fontWeight: FontWeight.bold)),
          Text("+", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w300)),
        ],
      );
    } else if (name.contains("pixel") || name.contains("google")) {
      return const Icon(Icons.g_mobiledata, color: Colors.white, size: 54);
    } else if (name.contains("samsung")) {
      return const Text("S", style: TextStyle(color: Colors.blueAccent, fontSize: 32, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic));
    } else if (name.contains("xiaomi") || name.contains("redmi") || name.contains("mi ")) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.orange.shade800, borderRadius: BorderRadius.circular(6)),
        child: const Text("mi", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      );
    } else if (name.contains("poco")) {
      return const Text("POCO", style: TextStyle(color: Colors.yellowAccent, fontSize: 16, fontWeight: FontWeight.bold));
    } else if (name.contains("motorola") || name.contains("moto")) {
      return const Text("M", style: TextStyle(color: Colors.blue, fontSize: 30, fontWeight: FontWeight.w900));
    } else if (name.contains("realme")) {
      return const Text("R", style: TextStyle(color: Colors.yellow, fontSize: 32, fontWeight: FontWeight.bold));
    } else if (name.contains("oppo")) {
      return const Text("oppo", style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold));
    } else if (name.contains("vivo")) {
      return const Text("vivo", style: TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic));
    } else if (name.contains("asus") || name.contains("rog")) {
      return const Text("ROG", style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.w900));
    } else if (name.contains("sony")) {
      return const Text("SONY", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5));
    } else if (name.contains("huawei")) {
      return const Text("H", style: TextStyle(color: Colors.redAccent, fontSize: 32, fontWeight: FontWeight.bold));
    } else if (name.contains("honor")) {
      return const Text("HONOR", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2));
    } else if (name.contains("nothing")) {
      return const Text("N", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'monospace'));
    } else if (name.contains("nokia")) {
      return const Text("NOKIA", style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0));
    } else if (name.contains("lg ")) {
      return const Text("LG", style: TextStyle(color: Colors.pink, fontSize: 24, fontWeight: FontWeight.bold));
    } else if (name.contains("zte") || name.contains("nubia") || name.contains("redmagic")) {
      return const Text("ZTE", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold));
    } else {
      String initial = modelName.isNotEmpty ? modelName[0].toUpperCase() : "D";
      return Text(initial, style: const TextStyle(color: Colors.white38, fontSize: 32, fontWeight: FontWeight.bold));
    }
  }

  Widget _buildFooterCard() {
    String socName = _audit!.processor;
    if (socName.toUpperCase() == "MT6895") socName = "MediaTek Dimensity 8100-MAX";

    String androidVer = _osInfo["androidVersion"] ?? _audit!.androidVersion.replaceAll("Android ", "");
    String oemBuild = _osInfo["oemBuild"] ?? _audit!.androidVersion;

    return InkWell(
      onTap: _showOsDetails,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: CyberTheme.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
              child: Center(child: _buildBrandLogo(_audit!.modelName)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(_audit!.modelName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CyberTheme.primaryAccent, fontSize: 16, fontWeight: FontWeight.bold))), const Icon(Icons.more_vert, color: Colors.grey, size: 16)]),
                  const SizedBox(height: 4),
                  Text(socName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text("Android $androidVer • $oemBuild", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text("Architecture: ${_audit!.architecture}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CpuWavePainter extends CustomPainter {
  final double animationValue;
  CpuWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = CyberTheme.primaryAccent.withValues(alpha: 0.2)..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i += 10) {
      double wave1 = math.sin((i / 30) + (animationValue * 2 * math.pi));
      double wave2 = math.cos((i / 15) + (animationValue * 2 * math.pi));
      double y = size.height - 20 + (wave1 * 10) + (wave2 * 15);
      path.lineTo(i, y.clamp(0.0, size.height));
    }
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
    final strokePaint = Paint()..color = CyberTheme.primaryAccent..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CpuWavePainter oldDelegate) => oldDelegate.animationValue != animationValue;
}

class LiveSensorGraph extends StatefulWidget {
  final Stream<dynamic> stream;
  final double maxY;

  const LiveSensorGraph({super.key, required this.stream, required this.maxY});

  @override
  State<LiveSensorGraph> createState() => _LiveSensorGraphState();
}

class _LiveSensorGraphState extends State<LiveSensorGraph> {
  final int _maxPoints = 40;
  final List<FlSpot> _xSpots = [];
  final List<FlSpot> _ySpots = [];
  final List<FlSpot> _zSpots = [];
  double _time = 0;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.stream.listen((event) {
      if (mounted) {
        setState(() {
          _time += 1;
          _xSpots.add(FlSpot(_time, event.x));
          _ySpots.add(FlSpot(_time, event.y));
          _zSpots.add(FlSpot(_time, event.z));

          if (_xSpots.length > _maxPoints) {
            _xSpots.removeAt(0);
            _ySpots.removeAt(0);
            _zSpots.removeAt(0);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_xSpots.isEmpty) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: CyberTheme.primaryAccent)));

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          clipData: const FlClipData.all(),
          minY: -widget.maxY,
          maxY: widget.maxY,
          minX: _xSpots.first.x,
          maxX: _xSpots.last.x,
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.white10)),
          gridData: const FlGridData(show: false),
          lineBarsData: [
            LineChartBarData(spots: _xSpots, color: Colors.redAccent, isCurved: true, dotData: const FlDotData(show: false), barWidth: 2.5),
            LineChartBarData(spots: _ySpots, color: Colors.greenAccent, isCurved: true, dotData: const FlDotData(show: false), barWidth: 2.5),
            LineChartBarData(spots: _zSpots, color: Colors.blueAccent, isCurved: true, dotData: const FlDotData(show: false), barWidth: 2.5),
          ],
        ),
      ),
    );
  }
}