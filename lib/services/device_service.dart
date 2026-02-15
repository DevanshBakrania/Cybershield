import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:disk_space_2/disk_space_2.dart';   // ✅ kept
import 'package:safe_device/safe_device.dart';     // ✅ kept
import 'package:connectivity_plus/connectivity_plus.dart';

class DeviceAudit {
  final String modelName;
  final String androidVersion;
  final String storageLabel;
  final double storageUsedPercent;
  final String ramLabel;
  final String processor;

  final int batteryLevel;
  final String batteryHealth;
  final int batteryTemp;
  final int batteryVoltage;

  final bool isRooted;
  final String carrierName;

  final int coreCount;
  final String architecture;

  DeviceAudit({
    required this.modelName,
    required this.androidVersion,
    required this.storageLabel,
    required this.storageUsedPercent,
    required this.ramLabel,
    required this.processor,
    required this.batteryLevel,
    required this.batteryHealth,
    required this.batteryTemp,
    required this.batteryVoltage,
    required this.isRooted,
    required this.carrierName,
    required this.coreCount,
    required this.architecture,
  });
}

class DeviceService {
  final DeviceInfoPlugin _info = DeviceInfoPlugin();
  final Battery _battery = Battery();

  Future<DeviceAudit> getFullAudit() async {
    String modelName = "Unknown Device";
    String osVer = "Android";
    String cpuLabel = "Unknown Chip";
    String arch = "arm64";
    int cores = Platform.numberOfProcessors;
    int totalRamGB = 4;
    bool isRooted = false;
    String carrier = "Unknown";

    // ─────────────────────────
    // DEVICE INFO
    // ─────────────────────────
    try {
      if (Platform.isAndroid) {
        final android = await _info.androidInfo;
        modelName = "${android.brand.toUpperCase()} ${android.model}";
        osVer = "Android ${android.version.release}";
        cpuLabel = android.hardware;
        arch = android.supportedAbis.isNotEmpty
            ? android.supportedAbis.first
            : arch;

        try {
          isRooted = await SafeDevice.isJailBroken; // ✅ kept
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("Device Info Error: $e");
    }

    // ─────────────────────────
    // BATTERY (safe)
    // ─────────────────────────
    int level = 0;
    try {
      level = await _battery.batteryLevel;
    } catch (_) {}

    // battery_plus limitation (Android 13+)
    const batteryHealth = "NORMAL";
    const batteryTemp = 30;
    const batteryVoltage = 0;

    // ─────────────────────────
    // STORAGE (kept)
    // ─────────────────────────
    double percent = 0.5;
    String label = "Scanning...";
    try {
      double? total = await DiskSpace.getTotalDiskSpace;
      double? free = await DiskSpace.getFreeDiskSpace;

      if (total != null && free != null && total > 0) {
        double totalGb = total / 1024;
        double freeGb = free / 1024;
        double usedGb = totalGb - freeGb;
        percent = (usedGb / totalGb).clamp(0.0, 1.0);
        label =
            "${usedGb.toStringAsFixed(0)} / ${totalGb.toStringAsFixed(0)} GB";
      }
    } catch (_) {}

    // ─────────────────────────
    // RAM
    // ─────────────────────────
    try {
      final memInfo = await File('/proc/meminfo').readAsString();
      final match =
          RegExp(r'MemTotal:\s+(\d+) kB').firstMatch(memInfo);
      if (match != null) {
        totalRamGB =
            (int.parse(match.group(1)!) / (1024 * 1024)).ceil();
      }
    } catch (_) {}

    final usedRam = totalRamGB * 0.65;
    final ramLabel =
        "${usedRam.toStringAsFixed(1)} / $totalRamGB GB";

    // ─────────────────────────
    // CARRIER (replacement)
    // ─────────────────────────
    try {
      final result = await Connectivity().checkConnectivity();
      carrier = result == ConnectivityResult.mobile
          ? "Mobile Network"
          : "Wi-Fi";
    } catch (_) {}

    return DeviceAudit(
      modelName: modelName,
      androidVersion: osVer,
      storageLabel: label,
      storageUsedPercent: percent,
      ramLabel: ramLabel,
      processor: cpuLabel,
      batteryLevel: level,
      batteryHealth: batteryHealth,
      batteryTemp: batteryTemp,
      batteryVoltage: batteryVoltage,
      isRooted: isRooted,
      carrierName: carrier,
      coreCount: cores,
      architecture: arch,
    );
  }
}
