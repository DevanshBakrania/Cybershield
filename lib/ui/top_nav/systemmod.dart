import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

class DeviceInfoPage extends StatefulWidget {
  const DeviceInfoPage({super.key});

  @override
  State<DeviceInfoPage> createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends State<DeviceInfoPage> {

  static const MethodChannel channel =
      MethodChannel("com.cybershield/hardware");

  Map<String, dynamic> device = {};
  Map<String, dynamic> os = {};
  Map<String, dynamic> cpu = {};
  Map<String, dynamic> updates = {};
  Map<String, dynamic> security = {};
  Map<String, dynamic> runtime = {};
  Map<String, dynamic> environment = {};
  Map<String, dynamic> identifiers = {};
  Map<String, dynamic> drm = {};

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {

    try {

      device = Map<String, dynamic>.from(
          await channel.invokeMethod("getDeviceInfo"));

      os = Map<String, dynamic>.from(
          await channel.invokeMethod("getDeepOsInfo"));

      cpu = Map<String, dynamic>.from(
          await channel.invokeMethod("getDeepCpuInfo"));

      updates = Map<String, dynamic>.from(
          await channel.invokeMethod("getUpdateInfo"));

      security = Map<String, dynamic>.from(
          await channel.invokeMethod("getSecurityInfo"));

      runtime = Map<String, dynamic>.from(
          await channel.invokeMethod("getRuntimeInfo"));

      environment = Map<String, dynamic>.from(
          await channel.invokeMethod("getEnvironmentInfo"));

      identifiers = Map<String, dynamic>.from(
          await channel.invokeMethod("getIdentifiers"));

      drm = Map<String, dynamic>.from(
          await channel.invokeMethod("getDrmInfo"));

    } catch (e) {
      debugPrint("DeviceInfo Error: $e");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        /// DEVICE
        _section(Icons.phone_android, "Device", [

          _row(Icons.smartphone, "Device Name", device["deviceName"]),
          _row(Icons.apartment, "Manufacturer", device["manufacturer"]),
          _row(Icons.devices, "Model", device["model"]),
          _row(Icons.inventory_2, "Product", device["product"]),
          _row(Icons.developer_board, "Device", device["device"]),
          _row(Icons.memory, "Board", device["board"]),
          _row(Icons.precision_manufacturing, "Hardware", device["hardware"]),
          _row(Icons.settings, "Bootloader", device["bootloader"]),
          _row(Icons.qr_code, "Product Code", device["productCode"]),
          _row(Icons.radio, "Radio", device["radio"]),

        ]),

        /// OS
        _section(Icons.android, "Operating System", [

          _row(Icons.phone_android, "Android Version", os["androidVersion"]),
          _row(Icons.code, "SDK Level", os["sdkInt"]),
          _row(Icons.security, "Security Patch", os["securityPatch"]),
          _row(Icons.build, "Kernel", os["kernel"]),
          _row(Icons.shield, "SELinux", os["selinux"]),
          _row(Icons.settings_input_antenna, "Baseband", os["baseband"]),
          _row(Icons.construction, "OEM Build", os["oemBuild"]),
          _row(Icons.architecture, "Instruction Sets", os["instructionSets"]),
          _row(Icons.sync_alt, "Active Slot", os["activeSlot"]),

        ]),

        /// UPDATES
        _section(Icons.system_update, "Updates", [

          _row(Icons.android, "Current Release", updates["currentRelease"]),
          _row(Icons.history, "Initial Release", updates["initialRelease"]),
          _row(Icons.layers, "Project Treble", updates["projectTreble"]),
          _row(Icons.extension, "Project Mainline", updates["projectMainline"]),
          _row(Icons.storage, "Dynamic Partitions", updates["dynamicPartitions"]),
          _row(Icons.update, "Seamless Updates", updates["seamlessUpdates"]),

        ]),

        /// SECURITY
        _section(Icons.security, "Security", [

          _row(Icons.verified_user, "Verified Boot", security["verifiedBoot"]),
          _row(Icons.shield, "Verified Boot State", security["verifiedBootState"]),
          _row(Icons.lock, "dm-verity", security["dmVerity"]),
          _row(Icons.settings, "Bootloader", security["bootloader"]),
          _row(Icons.admin_panel_settings, "Root Access", security["rootAccess"]),

        ]),

        /// RUNTIME
        _section(Icons.memory, "Runtime", [

          _row(Icons.play_circle, "Google Play Services", runtime["playServices"]),
          _row(Icons.terminal, "Toybox", runtime["toybox"]),
          _row(Icons.code, "Java VM", runtime["javaVm"]),
          _row(Icons.lock, "SSL Version", runtime["ssl"]),

        ]),

        /// ENVIRONMENT
        _section(Icons.public, "Environment", [

          _row(Icons.language, "Language", environment["language"]),
          _row(Icons.schedule, "Timezone", environment["timezone"]),
          _row(Icons.usb, "USB Debugging", environment["usbDebugging"]),
          _row(Icons.developer_mode, "Developer Options", environment["developerOptions"]),

        ]),

        /// IDENTIFIERS
        _section(Icons.perm_identity, "Identifiers", [

          _row(Icons.fingerprint, "Device ID", identifiers["deviceId"]),

        ]),

        /// DRM
        _section(Icons.vpn_key, "DRM", [

          _row(Icons.business, "Vendor", drm["vendor"]),
          _row(Icons.info, "Version", drm["version"]),

        ]),

        /// CPU
        _section(Icons.memory_outlined, "CPU", [

          _row(Icons.architecture, "Architecture", cpu["architecture"]),
          _row(Icons.precision_manufacturing, "Hardware", cpu["hardware"]),
          _row(Icons.settings_input_component, "Cores", cpu["coreCount"]),
          _row(Icons.thermostat, "Temperature", cpu["cpuTemp"]),
          _row(Icons.speed, "Governor", (cpu["governors"] as List?)?.join(", ")),

        ]),
      ],
    );
  }

  Widget _section(IconData icon, String title, List<Widget> children) {

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Icon(icon, color: CyberTheme.primaryAccent, size: 20),

              const SizedBox(width: 8),

              Text(
                title,
                style: const TextStyle(
                  color: CyberTheme.primaryAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...children
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, dynamic value) {

    final val = value?.toString() ?? "Unknown";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [

          Icon(icon, size: 16, color: CyberTheme.textGrey),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: CyberTheme.textGrey,
                fontSize: 13,
              ),
            ),
          ),

          Expanded(
            child: Text(
              val,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: CyberTheme.textWhite,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}