import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/native_hardware_service.dart';

class NetworkProvider extends ChangeNotifier {
  Timer? _timer;
  int _lastRx = 0;
  int _lastTx = 0;

  double _downloadSpeed = 0.0;
  double _uploadSpeed = 0.0;
  String _downloadUnit = "KB/s";
  String _uploadUnit = "KB/s";

  double get downloadSpeed => _downloadSpeed;
  double get uploadSpeed => _uploadSpeed;
  String get downloadUnit => _downloadUnit;
  String get uploadUnit => _uploadUnit;

  NetworkProvider() {
    _startPolling();
  }

  void _startPolling() async {
    // 1. Get initial baseline
    final initial = await NativeHardwareService.getLiveNetworkBytes();
    if (initial.length == 2) {
      _lastRx = initial[0];
      _lastTx = initial[1];
    }

    // 2. Check exact traffic difference every 1 second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateSpeed());
  }

  Future<void> _calculateSpeed() async {
    final current = await NativeHardwareService.getLiveNetworkBytes();
    if (current.length == 2) {
      int currentRx = current[0];
      int currentTx = current[1];

      int rxDiff = currentRx - _lastRx;
      int txDiff = currentTx - _lastTx;

      // Failsafe for device reboot / counter reset
      if (rxDiff < 0) rxDiff = 0;
      if (txDiff < 0) txDiff = 0;

      _lastRx = currentRx;
      _lastTx = currentTx;

      _formatSpeed(rxDiff, true);
      _formatSpeed(txDiff, false);

      notifyListeners();
    }
  }

  void _formatSpeed(int bytesPerSec, bool isDownload) {
    double speed;
    String unit;

    if (bytesPerSec >= 1024 * 1024) {
      speed = bytesPerSec / (1024 * 1024);
      unit = "MB/s";
    } else {
      speed = bytesPerSec / 1024;
      unit = "KB/s";
    }

    if (isDownload) {
      _downloadSpeed = speed;
      _downloadUnit = unit;
    } else {
      _uploadSpeed = speed;
      _uploadUnit = unit;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}