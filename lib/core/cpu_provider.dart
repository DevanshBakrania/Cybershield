import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../services/native_hardware_service.dart';

class CpuProvider extends ChangeNotifier {
  Map<String, dynamic> _cpuInfo = {};
  List<int> _cpuFreqs = [2000, 2000, 1600, 1600];
  Timer? _timer;

  Map<String, dynamic> get cpuInfo => _cpuInfo;
  List<int> get cpuFreqs => _cpuFreqs;

  CpuProvider() {
    _startPolling();
  }

  void _startPolling() {
    _fetchData(); // Initial fetch
    _timer = Timer.periodic(const Duration(milliseconds: 800), (_) => _fetchData());
  }

  Future<void> _fetchData() async {
    final data = await NativeHardwareService.getDeepCpuInfo();
    _cpuInfo = Map<String, dynamic>.from(data);

    // Jitter for visual effect (Kept exactly from your original logic)
    _cpuFreqs = _cpuFreqs.map((freq) {
      int change = (math.Random().nextInt(300) - 150);
      return (freq + change).clamp(800, 3200);
    }).toList();

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}