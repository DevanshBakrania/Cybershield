import 'dart:io';
import 'package:flutter/services.dart';

class NativeCameraService {

  static const MethodChannel _channel =
      MethodChannel('com.cybershield/hardware');

  Future<List<Map<String, dynamic>>> getCameraInfo() async {

    if (!Platform.isAndroid) return [];

    final result = await _channel.invokeMethod('getDeepCameraInfo');

    return (result as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}