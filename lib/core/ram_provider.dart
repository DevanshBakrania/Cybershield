import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/native_hardware_service.dart';

class RamProvider extends ChangeNotifier {
  Map<String, int> _memInfo = {};
  Timer? _timer;

  Map<String, int> get memInfo => _memInfo;

  RamProvider() {
    _startPolling();
  }

  void _startPolling() {
    _fetchData();
    // RAM doesn't change as fast as CPU, so 2 seconds is perfect for battery/performance
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchData());
  }

  Future<void> _fetchData() async {
    final data = await NativeHardwareService.getDeepMemoryInfo();
    if (data.isNotEmpty) {
      _memInfo = data;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}