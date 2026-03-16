import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:app_settings/app_settings.dart';

import '../../widgets/info_tile.dart';
import '../../services/native_network_service.dart';

class BatteryPage extends StatefulWidget {
  const BatteryPage({super.key});

  @override
  State<BatteryPage> createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage>
    with SingleTickerProviderStateMixin {

  final Battery _battery = Battery();
  final NativeNetworkService _native = NativeNetworkService();

  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;
  Map<String, dynamic>? _batteryDetails;

  Timer? _pollTimer;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _initBatteryInfo();

    _battery.onBatteryStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _batteryState = state);
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshBatteryDetails());

    unawaited(_refreshBatteryDetails());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _initBatteryInfo() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;

    if (!mounted) return;

    setState(() {
      _batteryLevel = level;
      _batteryState = state;
    });
  }

  Future<void> _refreshBatteryDetails() async {
    final details = await _native.getBatteryDetails();
    if (!mounted) return;

    setState(() {
      _batteryDetails = details;
      final percent = details?['percent'];
      if (percent is num) {
        _batteryLevel = percent.round();
      }
    });
  }

  Future<void> _openBatterySettings() async {
    if (!Platform.isAndroid) return;

    const actions = [
      'android.settings.BATTERY_USAGE_SUMMARY',
      'android.settings.POWER_USAGE_SUMMARY',
      'android.settings.BATTERY_SAVER_SETTINGS',
      'android.settings.BATTERY_SETTINGS',
    ];

    for (final action in actions) {
      try {
        await AndroidIntent(
          action: action,
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        ).launch();
        return;
      } catch (_) {}
    }

    await AppSettings.openAppSettings();
  }

  String _statusLine() {
    final nativeStatus = _batteryDetails?['status'] as String?;
    final plug = _batteryDetails?['plugType'] as String?;

    if (nativeStatus == null) {
      return _batteryState.toString().split('.').last;
    }

    if (plug != null && plug != 'Battery') {
      return '$nativeStatus $plug';
    }

    return nativeStatus;
  }

  double? _tempC() => (_batteryDetails?['temperatureC'] as num?)?.toDouble();
  double? _voltageV() => (_batteryDetails?['voltageV'] as num?)?.toDouble();
  double? _powerW() => (_batteryDetails?['powerW'] as num?)?.toDouble();
  double? _currentMa() => (_batteryDetails?['currentMa'] as num?)?.toDouble();

  @override
  Widget build(BuildContext context) {
    final neonGreen = const Color(0xFF00E5FF);
    final surface = Theme.of(context).colorScheme.surface;

    final temp = _tempC();
    final volt = _voltageV();
    final power = _powerW();
    final current = _currentMa();

    final tempLabel = temp != null ? '${temp.toStringAsFixed(0)}°C' : '—';
    final voltLabel = volt != null ? '${volt.toStringAsFixed(3)} V' : '—';
    final powerLabel = power != null ? '${power.toStringAsFixed(1)} W' : '0.0 W';
    final currentLabel =
    current != null ? '${current.round().abs()} mA' : '—';

    final tech = (_batteryDetails?['technology'] as String?) ?? 'Unknown';
    final health = (_batteryDetails?['health'] as String?) ?? 'Unknown';

  
    final batterySaver = _batteryDetails?['batterySaver'] as bool?;
    final batteryProtection =
        _batteryDetails?['batteryProtection'] as bool?;

    final saverLabel = batterySaver == null
        ? 'Unknown'
        : batterySaver
            ? 'Enabled'
            : 'Disabled';

    final protectionLabel = batteryProtection == null
        ? 'Unavailable'
        : batteryProtection
            ? 'Enabled'
            : 'Disabled';

    final chargeCounterMah =
        (_batteryDetails?['chargeCounterMah'] as num?)?.toDouble();
    final estimatedFullMah =
        (_batteryDetails?['estimatedFullCapacityMah'] as num?)?.toDouble();

    final designCapacityLabel =
        estimatedFullMah != null ? '${estimatedFullMah.round()} mAh' : 'Unknown';

    final estimatedCapacityLabel = estimatedFullMah != null
        ? '${estimatedFullMah.round()} mAh'
        : 'Learning… Charge until full';

    final chargeCounterLabel =
        chargeCounterMah != null ? '${chargeCounterMah.round()} mAh' : 'Unknown';

    // ETA Logic (UNCHANGED)
    String etaText = 'Not available';
    String rateText = '-- %/m';

    final statusNative = _batteryDetails?['status'] as String?;
    final isCharging = statusNative == 'Charging';
    final isDischarging = statusNative == 'Discharging';
    if (estimatedFullMah != null &&
    chargeCounterMah != null &&
    current != null &&
    current != 0)  {

      final percentPerMinute =
          (current / estimatedFullMah) * 100 / 60;

      rateText =
          '${percentPerMinute.abs().toStringAsFixed(2)}%/m';
        debugPrint('RATE_DEBUG -> ' 'current: $current, ''estimatedFullMah: $estimatedFullMah, ''percentPerMinute: $percentPerMinute',
);
      

      if (isCharging && current > 0) {
        final remainingMah =
            (estimatedFullMah - chargeCounterMah)
                .clamp(0.0, estimatedFullMah);

        final hours = remainingMah / current;

        if (hours > 0 && hours < 24) {
          final totalMinutes = (hours * 60).round();
          final h = totalMinutes ~/ 60;
          final m = totalMinutes % 60;
          etaText =
              h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m';
        } else {
          etaText = 'Calculating...';
        }
      } else if (isDischarging && current < 0) {
        final hours = chargeCounterMah / current.abs();

        if (hours > 0 && hours < 24) {
          final totalMinutes = (hours * 60).round();
          final h = totalMinutes ~/ 60;
          final m = totalMinutes % 60;
          etaText =
              h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m';
        } else {
          etaText = 'Calculating...';
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      children: [

        /// ================= MAIN STATUS CARD =================
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.settings, size: 18),
                    onPressed: _openBatterySettings,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    '$_batteryLevel%',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00E5FF),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          _statusLine(),
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          etaText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 2),

                        const Text(
                          'Time until full',
                          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'Slow $rateText',
                          style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Text(tempLabel, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 16),
                  Text(voltLabel, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 16),
                  Text(powerLabel, style: const TextStyle(fontSize: 12)),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00012B).withOpacity(0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        const Text(
                          'Current',
                          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
                        ),
                        const Spacer(),
                        Text(
                          currentLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {

                          final absCurrent = (current ?? 0).abs();
                          final dynamicPart =
                              (absCurrent / 1500.0).clamp(0.0, 0.85);
                          final intensity = 0.15 + dynamicPart;

                          return CustomPaint(
                            painter: _BatteryWavePainter(
                              phase: _waveController.value,
                              intensity: intensity.clamp(0.1, 1.0),
                              color: neonGreen,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        /// ================= INFO CARD (IMPROVED) =================
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                'Info',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _InfoPair(label: 'Technology', value: tech)),
                  Expanded(child: _InfoPair(label: 'Health', value: health)),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(child: _InfoPair(label: 'Battery protection', value: protectionLabel)),
                  Expanded(child: _InfoPair(label: 'Battery saver', value: saverLabel)),
                ],
              ),

              const SizedBox(height: 20),
              Divider(color: const Color(0xFFFFFFFF).withOpacity(0.08)),
              const SizedBox(height: 20),

              const Text(
                'Capacity & health',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _InfoPair(label: 'Design capacity', value: designCapacityLabel)),
                  Expanded(child: _InfoPair(label: 'Capacity (estimated)', value: estimatedCapacityLabel)),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(child: _InfoPair(label: 'Charge counter', value: chargeCounterLabel)),
                  const Expanded(child: _InfoPair(label: 'Charge cycles', value: 'NA')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
class _InfoPair extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPair({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
class _BatteryWavePainter extends CustomPainter {
  final double phase;
  final double intensity;
  final Color color;

  _BatteryWavePainter({
    required this.phase,
    required this.intensity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final midY = size.height * 0.6;
    final amp = size.height * 0.25 * intensity;

    for (double x = 0; x <= size.width; x += 2) {
      final t = (x / size.width * 2 * math.pi) + phase * 2 * math.pi;
      final y = midY - amp * math.sin(t);

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BatteryWavePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.intensity != intensity ||
        oldDelegate.color != color;
  }
}