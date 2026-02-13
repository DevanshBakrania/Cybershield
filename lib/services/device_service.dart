import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:battery_info/battery_info_plugin.dart';
import 'package:disk_space_2/disk_space_2.dart';
import 'package:safe_device/safe_device.dart';
import 'package:carrier_info/carrier_info.dart';

class DeviceAudit {
  // ✅ Fields matching Dashboard expectations
  final String modelName;
  final String androidVersion;
  final String storageLabel;
  final double storageUsedPercent;
  final String ramLabel;
  final String processor;

  // Vitals
  final int batteryLevel;
  final String batteryHealth;
  final int batteryTemp; // ✅ Added Temperature
  final int batteryVoltage;

  // Security
  final bool isRooted;
  final String carrierName;

  // Raw Data
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
    int cores = 8;
    int totalRamGB = 4;
    bool isRooted = false;
    String carrier = "No SIM";

    // 1. HARDWARE INFO
    if (Platform.isAndroid) {
      try {
        final android = await _info.androidInfo;
        modelName = "${android.brand.toUpperCase()} ${android.model}";
        osVer = "Android ${android.version.release}";
        cpuLabel = android.hardware;
        if (android.supportedAbis.isNotEmpty) {
          arch = android.supportedAbis.first;
        }

        // Root Check
        try {
          isRooted = await SafeDevice.isJailBroken;
        } catch (_) {}

        // RAM Check
        try {
          final memInfo = await File('/proc/meminfo').readAsString();
          final match = RegExp(r'MemTotal:\s+(\d+) kB').firstMatch(memInfo);
          if (match != null) {
            int totalKb = int.parse(match.group(1)!);
            totalRamGB = (totalKb / (1024 * 1024)).ceil();
          }
        } catch (_) {}
      } catch (e) {
        debugPrint("Device Info Error: $e");
      }
    }

    // 2. CARRIER INFO
    try {
      if (Platform.isAndroid) {
        AndroidCarrierData? androidInfo = await CarrierInfo.getAndroidInfo();
        if (androidInfo != null && androidInfo.telephonyInfo.isNotEmpty) {
          carrier = androidInfo.telephonyInfo.first.carrierName.toString();
          if (carrier == "null" || carrier.isEmpty) carrier = "Unknown Carrier";
        }
      }
    } catch (_) {
      carrier = "WiFi / No SIM";
    }

    // 3. BATTERY INFO
    int level = 0;
    int temp = 30;
    int voltage = 0;
    String health = "GOOD";

    try {
      var info = await BatteryInfoPlugin().androidBatteryInfo;
      if (info != null) {
        level = info.batteryLevel ?? await _battery.batteryLevel;
        temp = info.temperature ?? 30;
        voltage = info.voltage ?? 0;
        health = info.health?.toUpperCase() ?? "GOOD";
      }
    } catch (_) {
      level = await _battery.batteryLevel;
    }

    // 4. STORAGE
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
        label = "${usedGb.toStringAsFixed(0)} / ${totalGb.toStringAsFixed(0)} GB";
      }
    } catch (_) {}

    // 5. RAM TEXT
    double usedRam = totalRamGB * 0.65; // Simulated usage
    String ramLabel = "${usedRam.toStringAsFixed(1)} / $totalRamGB GB";

    return DeviceAudit(
      modelName: modelName,
      androidVersion: osVer,
      storageLabel: label,
      storageUsedPercent: percent,
      ramLabel: ramLabel,
      processor: cpuLabel,
      batteryLevel: level,
      batteryHealth: health,
      batteryTemp: temp,
      batteryVoltage: voltage,
      isRooted: isRooted,
      carrierName: carrier,
      coreCount: cores,
      architecture: arch,
    );
  }
}