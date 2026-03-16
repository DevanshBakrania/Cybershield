import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class NativeNetworkService {
  static const MethodChannel _channel = MethodChannel('com.cybershield/hardware');

  Future<Map<String, dynamic>?> getWifiHardwareSupport() async {
    if (!Platform.isAndroid) return null;
    final res = await _channel.invokeMethod<dynamic>('getWifiHardwareSupport');
    return (res as Map?)?.cast<String, dynamic>();
  }

  Future<Map<String, dynamic>?> getWifiNativeInfo() async {
    if (!Platform.isAndroid) return null;
    final res = await _channel.invokeMethod<dynamic>('getWifiNativeInfo');
    return (res as Map?)?.cast<String, dynamic>();
  }

  Future<Map<String, dynamic>?> getMobileInfo() async {
    if (!Platform.isAndroid) return null;
    final res = await _channel.invokeMethod<dynamic>('getMobileInfo');
    return (res as Map?)?.cast<String, dynamic>();
  }

  Future<Map<String, dynamic>?> getBatteryDetails() async {
    if (!Platform.isAndroid) return null;
    final res = await _channel.invokeMethod<dynamic>('getBatteryDetails');
    return (res as Map?)?.cast<String, dynamic>();
  }
}

