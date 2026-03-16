import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HardwarePage extends StatefulWidget {
  const HardwarePage({super.key});

  @override
  State<HardwarePage> createState() => _HardwarePageState();
}

class _HardwarePageState extends State<HardwarePage> {

  static const platform = MethodChannel("com.cybershield/hardware");

  static const cyan = Color(0xFF00E5FF);
  static const card = Color(0xFF0A0D3A);

  Map cpu = {};
  Map gpu = {};
  Map display = {};
  Map memory = {};
  Map storage = {};
  Map bluetooth = {};
  Map audio = {};
  Map sensors = {};
  Map usb = {};
  Map nfc = {};

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHardware();
  }

  Future<void> loadHardware() async {

    try {

      cpu = Map.from(await platform.invokeMethod("getDeepCpuInfo"));
      gpu = Map.from(await platform.invokeMethod("getGpuFullInfo"));
      display = Map.from(await platform.invokeMethod("getDeepDisplayInfo"));
      memory = Map.from(await platform.invokeMethod("getDeepMemoryInfo"));
      storage = Map.from(await platform.invokeMethod("getDeepStorageInfo"));
      bluetooth = Map.from(await platform.invokeMethod("getBluetoothHardware"));
      audio = Map.from(await platform.invokeMethod("getAudioHardware"));
      sensors = Map.from(await platform.invokeMethod("getSensorHardware"));
      usb = Map.from(await platform.invokeMethod("getUsbHardware"));
      nfc = Map.from(await platform.invokeMethod("getNfcHardware"));

    } catch (e) {
      debugPrint("Hardware error: $e");
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: cyan),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [

        cpuCard(),
        gpuCard(),
        displayCard(),
        memoryCard(),
        storageCard(),
        featureCard("Bluetooth Hardware", Icons.bluetooth, bluetooth),
        featureCard("Audio Hardware", Icons.headphones, audio),
        sensorCard(),
        featureCard("USB Hardware", Icons.usb, usb),
        featureCard("NFC Hardware", Icons.nfc, nfc),

      ],
    );
  }

  /// ---------------- CPU CARD ----------------

  Widget cpuCard() {

    return hardwareCard(
      "CPU Hardware",
      Icons.memory,
      Column(
        children: [

          headerValue(cpu["hardware"] ?? "Unknown CPU"),

          const SizedBox(height: 10),

          chipRow([
            "${cpu["coreCount"] ?? "?"} cores",
            cpu["architecture"] ?? "Unknown"
          ]),

          const SizedBox(height: 16),

          infoRow("Temperature", cpu["cpuTemp"] ?? "Unknown"),

          infoRow("Governor",
              (cpu["governors"] is List && cpu["governors"].isNotEmpty)
                  ? cpu["governors"][0]
                  : "Unknown"),
        ],
      ),
    );
  }

  /// ---------------- GPU CARD ----------------

  Widget gpuCard() {

    return hardwareCard(
      "GPU / OpenGL / Vulkan",
      Icons.graphic_eq,
      Column(
        children: [

          headerValue(gpu["renderer"] ?? "Unknown GPU"),

          const SizedBox(height: 14),

          infoRow("Vendor", gpu["vendor"] ?? "Unknown"),

          infoRow("OpenGL Version", gpu["openglVersion"] ?? "Unknown"),

          infoRow("Vulkan Support",
              gpu["vulkanSupported"] == true ? "Supported" : "Not supported"),
        ],
      ),
    );
  }

  /// ---------------- DISPLAY ----------------

  Widget displayCard() {

    return hardwareCard(
      "Display Hardware",
      Icons.phone_android,
      Column(
        children: [

          headerValue(
              "${display["physicalWidth"]} × ${display["physicalHeight"]}"),

          const SizedBox(height: 14),

          infoRow("Refresh Rate", "${display["refreshRate"]} Hz"),

          infoRow("PPI", "${display["averagePpi"]?.toStringAsFixed(1)}"),

          infoRow("Screen Size",
              "${display["screenInches"]?.toStringAsFixed(2)} inches"),
        ],
      ),
    );
  }

  /// ---------------- MEMORY ----------------

  Widget memoryCard() {

    final total = memory["MemTotal"] ?? 0;
    final free = memory["MemAvailable"] ?? 0;

    return hardwareCard(
      "Memory Hardware",
      Icons.sd_storage,
      Column(
        children: [

          headerValue("${(total / 1073741824).toStringAsFixed(1)} GB RAM"),

          const SizedBox(height: 16),

          infoRow(
              "Available",
              "${(free / 1073741824).toStringAsFixed(2)} GB"),

        ],
      ),
    );
  }

  /// ---------------- STORAGE ----------------

  Widget storageCard() {

    final total = storage["dataTotal"] ?? 0;
    final used = storage["dataUsed"] ?? 0;

    return hardwareCard(
      "Storage Hardware",
      Icons.storage,
      Column(
        children: [

          headerValue("${(total / 1073741824).toStringAsFixed(0)} GB"),

          const SizedBox(height: 14),

          infoRow("Used",
              "${(used / 1073741824).toStringAsFixed(1)} GB"),

        ],
      ),
    );
  }

  /// ---------------- SENSORS ----------------

  Widget sensorCard() {

    return hardwareCard(
      "Sensor Hardware",
      Icons.sensors,
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sensors.entries.map((e) {

          return Chip(
            label: Text(
              e.key,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor:
                e.value ? Colors.green : Colors.red,
          );

        }).toList(),
      ),
    );
  }

  /// ---------------- GENERIC FEATURE CARD ----------------

  Widget featureCard(String title, IconData icon, Map data) {

    return hardwareCard(
      title,
      icon,
      Column(
        children: data.entries
            .map((e) => infoRow(e.key, e.value.toString()))
            .toList(),
      ),
    );
  }

  /// ---------------- UI COMPONENTS ----------------

  Widget hardwareCard(String title, IconData icon, Widget child) {

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cyan),
              ),

              const SizedBox(width: 10),

              Text(
                title,
                style: const TextStyle(
                  color: cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          child
        ],
      ),
    );
  }

  Widget headerValue(String text) {

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: cyan,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget chipRow(List<String> chips) {

    return Wrap(
      spacing: 8,
      children: chips
          .map(
            (c) => Chip(
              label: Text(c),
              backgroundColor: Colors.black26,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          )
          .toList(),
    );
  }

  Widget infoRow(String label, String value) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [

          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
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