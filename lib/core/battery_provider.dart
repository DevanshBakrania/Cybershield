import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BatteryProvider extends ChangeNotifier {
  static const platform = MethodChannel('com.cybershield/hardware');

  Map<String, dynamic> _batteryData = {
    "level": 0,
    "voltage": 0.0,
    "current": 0,
    "status": "Connecting to Android...",
    "health": "Pending",
    "temperature": 0.0,
    "technology": "Loading...", // ✨ ADDED TECHNOLOGY
  };

  Map<String, dynamic> get batteryData => _batteryData;
  Timer? _timer;

  void startMonitoring() {
    _fetchBatteryData();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchBatteryData());
  }

  void stopMonitoring() {
    _timer?.cancel();
  }

  Future<void> _fetchBatteryData() async {
    try {
      final Map<dynamic, dynamic>? rawData = await platform.invokeMethod('getLiveBatteryHardware');

      if (rawData != null && rawData.isNotEmpty) {
        int newLevel = (rawData["level"] as num?)?.toInt() ?? -1;

        if (newLevel > 0) {
          _batteryData["level"] = newLevel;
          _batteryData["voltage"] = (rawData["voltage"] as num?)?.toDouble() ?? 0.0;
          _batteryData["current"] = (rawData["current"] as num?)?.toInt() ?? 0;
          _batteryData["status"] = rawData["status"]?.toString() ?? _deriveStatus(_batteryData["current"]);
          _batteryData["health"] = rawData["health"]?.toString() ?? "Good";
          _batteryData["temperature"] = (rawData["temperature"] as num?)?.toDouble() ?? 35.0;

          // ✨ CAPTURE TECHNOLOGY
          _batteryData["technology"] = rawData["technology"]?.toString() ?? "Unknown";
        } else {
          _batteryData["status"] = "Kotlin sent 0%";
        }
      } else {
        _batteryData["status"] = "No Data from Kotlin";
      }
    } on PlatformException catch (e) {
      debugPrint("Channel Error: ${e.message}");
      _batteryData["status"] = "Channel Failed (Check Kotlin)";
    } catch (e) {
      debugPrint("Central Brain Crash: $e");
      _batteryData["status"] = "Unknown Error";
    }

    notifyListeners();
  }

  String _deriveStatus(int current) {
    if (current > 10) return "Charging";
    if (current < -10) return "Discharging";
    return "Active";
  }
}