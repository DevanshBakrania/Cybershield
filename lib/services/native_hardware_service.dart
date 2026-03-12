import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeHardwareService {
  // This channel name MUST match the one in MainActivity.kt
  static const MethodChannel _channel = MethodChannel('com.cybershield/hardware');

  /// Fetches exact RAM, ZRAM, Buffers, and Cached memory directly from Linux /proc/meminfo
  static Future<Map<String, int>> getDeepMemoryInfo() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getDeepMemoryInfo');
      return result.cast<String, int>();
    } catch (e) {
      debugPrint("Failed to get deep memory info: $e");
      return {};
    }
  }

  /// Fetches CPU cores, hardware name, and sysfs frequencies
  static Future<Map<String, dynamic>> getDeepCpuInfo() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getDeepCpuInfo');
      return result.cast<String, dynamic>();
    } catch (e) {
      debugPrint("Failed to get deep CPU info: $e");
      return {};
    }
  }

  /// Uses Java Reflection to pull the manufacturer's true declared Battery Capacity (mAh)
  static Future<double> getDesignCapacity() async {
    try {
      final double capacity = await _channel.invokeMethod('getDesignCapacity');
      return capacity;
    } catch (e) {
      debugPrint("Failed to get battery design capacity: $e");
      return 0.0;
    }
  }

  /// Grabs live Voltage, Health, and Charging Status (AC/USB) directly from hardware intent
  static Future<Map<String, dynamic>> getLiveBatteryHardware() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getLiveBatteryHardware');
      return result.cast<String, dynamic>();
    } catch (e) {
      debugPrint("Failed to get live battery hardware: $e");
      return {};
    }
  }

  /// Fetches Wi-Fi SSID, Link Speed, IP, and SIM Operator status
  static Future<Map<String, dynamic>> getDeepNetworkInfo() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getDeepNetworkInfo');
      return result.cast<String, dynamic>();
    } catch (e) {
      debugPrint("Failed to get deep network info: $e");
      return {};
    }
  }

  /// Calculates actual Physical vs Logical screen resolution and diagonal inches
  static Future<Map<String, dynamic>> getDeepDisplayInfo() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getDeepDisplayInfo');
      return result.cast<String, dynamic>();
    } catch (e) {
      debugPrint("Failed to get deep display info: $e");
      return {};
    }
  }

  static Future<Map<String, dynamic>> getWidgetRealData() async {
    try {
      // Make sure 'platform' or '_channel' matches whatever you named your MethodChannel at the top of the file!
      final Map<dynamic, dynamic>? result = await const MethodChannel('com.cybershield/hardware').invokeMethod('getWidgetRealData');
      return result != null ? Map<String, dynamic>.from(result) : {};
    } catch (e) {
      debugPrint("Error fetching widget real data: $e");
      return {};
    }
  }

  static Future<List<dynamic>> getDeepCameraInfo() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getDeepCameraInfo');
      return result;
    } catch (e) {
      debugPrint("Failed to fetch camera info: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> getDeepStorageInfo() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getDeepStorageInfo');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      debugPrint("Failed to fetch storage info: $e");
      return {};
    }
  }

  // ✨ FETCH DEEP OS DATA
  static Future<Map<String, dynamic>> getDeepOsInfo() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getDeepOsInfo');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      debugPrint("Failed to fetch OS info: $e");
      return {};
    }
  }

  // ✨ NEW: FETCH LIVE NETWORK BYTES FOR SPEEDOMETER
  static Future<List<int>> getLiveNetworkBytes() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getLiveNetworkBytes');

      // Need to cast to int safely because Kotlin returns Longs
      return result.map((e) => (e as num).toInt()).toList();
    } catch (e) {
      debugPrint("Failed to get live network bytes: $e");
      return [0, 0];
    }
  }
}