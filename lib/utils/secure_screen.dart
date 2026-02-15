import 'dart:io';
import 'package:flutter/services.dart';

class SecureScreen {
  static const _channel = MethodChannel('secure_screen');

  static Future<void> enable() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod('enable');
    }
  }

  static Future<void> disable() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod('disable');
    }
  }
}
