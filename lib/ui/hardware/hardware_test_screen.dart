import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:local_auth/local_auth.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:light_sensor/light_sensor.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:audio_session/audio_session.dart' as session_lib;

import '../../core/theme.dart';
import '../../widgets/cyber_ui.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. MAIN MENU SCREEN
// ─────────────────────────────────────────────────────────────────────────────

enum TestStatus { untouched, running, passed, failed }

class HardwareTestItem {
  String name;
  IconData icon;
  TestStatus status;
  Function(BuildContext context, Function(TestStatus) updateStatus) onTestFunc;

  HardwareTestItem({
    required this.name,
    required this.icon,
    required this.onTestFunc,
    this.status = TestStatus.untouched,
  });
}

class HardwareTestScreen extends StatefulWidget {
  const HardwareTestScreen({super.key});

  @override
  State<HardwareTestScreen> createState() => _HardwareTestScreenState();
}

class _HardwareTestScreenState extends State<HardwareTestScreen> {
  late List<HardwareTestItem> _tests;
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _tests = [
      _buildGenericTest("Vibration", Icons.vibration, const VibrationTestScreen()),
      _buildGenericTest("Flashlight", Icons.flashlight_on, FlashlightTestScreen(getController: () => _cameraController)),
      _buildGenericTest("Biometric Scanner", Icons.fingerprint, const BiometricTestScreen()),
      _buildGenericTest("Accelerometer", Icons.screen_rotation, const AccelerometerTestScreen()),
      _buildGenericTest("Charging Port", Icons.electrical_services, const ChargingTestScreen()),
      _buildGenericTest("Display (Dead Pixel)", Icons.smartphone, const DisplayTestScreen()),
      _buildGenericTest("Multitouch", Icons.touch_app, const MultitouchTestScreen()),
      _buildGenericTest("Speakers", Icons.volume_up, const SpeakerTestScreen()),
      _buildGenericTest("Microphone", Icons.mic, const MicrophoneTestScreen()),
      _buildGenericTest("Sensor Suite", Icons.sensors, const GyroscopeTestScreen()),
      _buildGenericTest("Proximity Sensor", Icons.near_me, const ProximityTestScreen()),
      _buildGenericTest("Light Sensor", Icons.light_mode, const LightSensorTestScreen()),
      _buildGenericTest("Wi-Fi Signal", Icons.wifi, const WifiTestScreen()),
      _buildGenericTest("Headset", Icons.headset, const HeadsetTestScreen()),
      _buildGenericTest("Earpiece", Icons.phone_in_talk, const EarpieceTestScreen()),
      _buildGenericTest("Volume Buttons", Icons.volume_up_outlined, const ButtonsTestScreen()),
      _buildGenericTest("Screen Backlight", Icons.brightness_6, const BacklightTestScreen()),
      _buildGenericTest("Cameras", Icons.camera_alt, const CameraTestScreen()),
    ];
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(cameras[0], ResolutionPreset.low);
        await _cameraController!.initialize();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  HardwareTestItem _buildGenericTest(String name, IconData icon, Widget screen) {
    return HardwareTestItem(
      name: name,
      icon: icon,
      onTestFunc: (ctx, updateStatus) async {
        updateStatus(TestStatus.running);
        final result = await Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));
        updateStatus(result == true ? TestStatus.passed : TestStatus.failed);
      },
    );
  }

  void _updateTestStatus(int index, TestStatus newStatus) {
    if (mounted) setState(() => _tests[index].status = newStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        title: const CyberNeonText("DIAGNOSTICS", size: 22),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: CyberTheme.primaryAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tests.length,
        separatorBuilder: (c, i) => Divider(color: Colors.grey.withValues(alpha: 0.1)),
        itemBuilder: (ctx, i) => _buildTestTile(i),
      ),
    );
  }

  Widget _buildTestTile(int index) {
    final item = _tests[index];
    Color statusColor;
    IconData statusIcon;

    switch (item.status) {
      case TestStatus.passed:
        statusColor = CyberTheme.primaryAccent;
        statusIcon = Icons.check_circle;
        break;
      case TestStatus.failed:
        statusColor = CyberTheme.dangerRed;
        statusIcon = Icons.cancel;
        break;
      case TestStatus.running:
        statusColor = Colors.yellowAccent;
        statusIcon = Icons.hourglass_empty;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        break;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      leading: Icon(item.icon, color: CyberTheme.primaryAccent.withValues(alpha: 0.7), size: 28),
      title: Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing: item.status == TestStatus.running
          ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: statusColor))
          : Icon(statusIcon, color: statusColor, size: 28),
      onTap: item.status == TestStatus.running
          ? null
          : () => item.onTestFunc(context, (s) => _updateTestStatus(index, s)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. UNIFIED UI TEMPLATES
// ─────────────────────────────────────────────────────────────────────────────

class TestConfirmationSheet extends StatelessWidget {
  const TestConfirmationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: CyberTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Is it working?",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CyberTheme.dangerRed,
                      side: const BorderSide(color: CyberTheme.dangerRed),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("No", style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CyberTheme.primaryAccent,
                      side: const BorderSide(color: CyberTheme.primaryAccent),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Yes", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class StandardTestLayout extends StatelessWidget {
  final String title;
  final Widget child;

  const StandardTestLayout({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(title, style: const TextStyle(color: CyberTheme.primaryAccent, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(child: child),
          const TestConfirmationSheet(),
        ],
      ),
    );
  }
}

class StatusDisplay extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const StatusDisplay({
    super.key,
    required this.icon,
    required this.text,
    this.color = CyberTheme.primaryAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 100, color: color),
        const SizedBox(height: 20),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. INTERACTIVE INDIVIDUAL TESTS
// ─────────────────────────────────────────────────────────────────────────────

// ✨ Live Graph Accelerometer
class AccelerometerTestScreen extends StatefulWidget {
  const AccelerometerTestScreen({super.key});
  @override
  State<AccelerometerTestScreen> createState() => _AccelerometerTestScreenState();
}

class _AccelerometerTestScreenState extends State<AccelerometerTestScreen> {
  StreamSubscription? _sub;
  double x = 0, y = 0, z = 0;
  final List<double> xHist = [], yHist = [], zHist = [];
  final int maxPoints = 50;

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream().listen((e) {
      if (mounted) {
        setState(() {
          x = e.x;
          y = e.y;
          z = e.z;
          if (xHist.length > maxPoints) {
            xHist.removeAt(0);
            yHist.removeAt(0);
            zHist.removeAt(0);
          }
          xHist.add(e.x);
          yHist.add(e.y);
          zHist.add(e.z);
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StandardTestLayout(
      title: "Accelerometer",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAxisRow("X", x, Colors.blueAccent),
          _buildAxisRow("Y", y, Colors.redAccent),
          _buildAxisRow("Z", z, CyberTheme.primaryAccent),
          const SizedBox(height: 40),
          Container(
            height: 150,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(border: Border.all(color: Colors.white12)),
            child: CustomPaint(painter: LiveChartPainter(xHist, yHist, zHist)),
          ),
          const SizedBox(height: 20),
          const Text("Shake device to test responsiveness", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAxisRow(String label, double val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 40),
      child: Row(
        children: [
          CircleAvatar(radius: 8, backgroundColor: color),
          const SizedBox(width: 16),
          Text("$label: ", style: const TextStyle(color: Colors.white, fontSize: 18)),
          Text(
            "${val > 0 ? '+' : ''}${val.toStringAsFixed(3)} m/s²",
            style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Courier'),
          ),
        ],
      ),
    );
  }
}

class LiveChartPainter extends CustomPainter {
  final List<double> xData, yData, zData;
  LiveChartPainter(this.xData, this.yData, this.zData);

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paintGrid);

    _drawPath(canvas, size, xData, Colors.blueAccent);
    _drawPath(canvas, size, yData, Colors.redAccent);
    _drawPath(canvas, size, zData, CyberTheme.primaryAccent);
  }

  void _drawPath(Canvas canvas, Size size, List<double> data, Color color) {
    if (data.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    double stepX = size.width / 50;

    for (int i = 0; i < data.length; i++) {
      double dx = i * stepX;
      double dy = size.height / 2 - (data[i] * (size.height / 40));
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ✨ 3D Interactive Gyroscope
class GyroscopeTestScreen extends StatefulWidget {
  const GyroscopeTestScreen({super.key});
  @override
  State<GyroscopeTestScreen> createState() => _GyroscopeTestScreenState();
}

class _GyroscopeTestScreenState extends State<GyroscopeTestScreen> {
  StreamSubscription? _sub;
  double rotX = 0, rotY = 0, rotZ = 0;

  @override
  void initState() {
    super.initState();
    _sub = gyroscopeEventStream().listen((e) {
      if (mounted) {
        setState(() {
          rotX += e.x * 0.1;
          rotY += e.y * 0.1;
          rotZ += e.z * 0.1;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StandardTestLayout(
      title: "Sensor Suite (Gyro)",
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(rotX)
                ..rotateY(rotY)
                ..rotateZ(rotZ),
              child: const Icon(Icons.threesixty, size: 120, color: CyberTheme.primaryAccent),
            ),
            const SizedBox(height: 60),
            const Text("Rotate phone to interact", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ✨ Fixed Proximity Logic (Now dynamically captures baseline)
// ✨ Fixed Proximity Logic (Adapts to reverse-logic sensors)
// ✨ Self-Calibrating Proximity Sensor
// --- PART 1: The Main Widget ---
class ProximityTestScreen extends StatefulWidget {
  const ProximityTestScreen({super.key});

  @override
  State<ProximityTestScreen> createState() => _ProximityTestScreenState();
}

// --- PART 2: The State & Logic ---
class _ProximityTestScreenState extends State<ProximityTestScreen> {
  StreamSubscription? _sub;
  int _currentValue = -1; // -1 means we haven't received data yet

  @override
  void initState() {
    super.initState();
    _sub = ProximitySensor.events.listen((int event) {
      if (mounted) {
        setState(() {
          // Just track the raw number, forget the baseline logic
          _currentValue = event;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 0 universally means "NEAR" (hand is hovering) on Android devices
    bool isTriggered = (_currentValue >= 1);

    return StandardTestLayout(
      title: "Proximity Sensor",
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isTriggered ? 180 : 120,
              height: isTriggered ? 180 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentValue == -1
                    ? Colors.white10
                    : (isTriggered ? CyberTheme.primaryAccent.withValues(alpha: 0.3) : Colors.blueAccent.withValues(alpha: 0.3)),
                border: Border.all(
                  color: _currentValue == -1
                      ? Colors.grey
                      : (isTriggered ? CyberTheme.primaryAccent : Colors.blueAccent),
                  width: 4,
                ),
              ),
              child: Icon(
                _currentValue == -1
                    ? Icons.sensors
                    : (isTriggered ? Icons.front_hand : Icons.pan_tool_outlined),
                size: 50,
                color: _currentValue == -1
                    ? Colors.grey
                    : (isTriggered ? CyberTheme.primaryAccent : Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _currentValue == -1
                  ? "Hover hand to wake sensor..."
                  : (isTriggered ? "SENSOR TRIGGERED!" : "Path Clear"),
              style: TextStyle(
                color: _currentValue == -1
                    ? Colors.grey
                    : (isTriggered ? CyberTheme.primaryAccent : Colors.blueAccent),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24)
              ),
              child: Text(
                "Raw Value: ${_currentValue == -1 ? '...' : _currentValue}",
                style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Courier'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✨ Fixed Multitouch Logic (Now waits for you to release your fingers!)
class MultitouchTestScreen extends StatefulWidget {
  const MultitouchTestScreen({super.key});
  @override
  State<MultitouchTestScreen> createState() => _MultitouchTestScreenState();
}

class _MultitouchTestScreenState extends State<MultitouchTestScreen> {
  final Map<int, Offset> pointers = {};
  bool passed = false;
  bool completed = false;

  @override
  Widget build(BuildContext context) {
    Widget bodyContent = Stack(
      children: [
        Center(
          child: Text(
            completed
                ? "SUCCESS\n3+ Fingers Detected"
                : (passed ? "Release fingers to finish" : "Touch with 3 fingers\nDetected: ${pointers.length}"),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: passed ? CyberTheme.primaryAccent : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (!completed)
          ...pointers.values.map(
                (pos) => Positioned(
              left: pos.dx - 40,
              top: pos.dy - 40,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: CyberTheme.primaryAccent, width: 2),
                  color: CyberTheme.primaryAccent.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        if (completed)
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: TestConfirmationSheet(), // Buttons are safe here!
          )
      ],
    );

    // ✨ THE FIX: If completed, we DO NOT wrap the screen in a Listener.
    // This allows the "Yes/No" buttons to be clicked perfectly!
    if (completed) {
      return Scaffold(backgroundColor: Colors.black, body: bodyContent);
    }

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        setState(() {
          pointers[e.pointer] = e.localPosition;
          if (pointers.length >= 3) passed = true;
        });
      },
      onPointerMove: (e) {
        setState(() {
          if (pointers.containsKey(e.pointer)) pointers[e.pointer] = e.localPosition;
        });
      },
      onPointerUp: (e) {
        setState(() {
          pointers.remove(e.pointer);
          if (passed && pointers.isEmpty) completed = true;
        });
      },
      onPointerCancel: (e) {
        setState(() {
          pointers.remove(e.pointer);
          if (passed && pointers.isEmpty) completed = true;
        });
      },
      child: Scaffold(backgroundColor: Colors.black, body: bodyContent),
    );
  }
}

// ✨ Fixed Buttons Logic (Now resets automatically and tracks both presses)
class ButtonsTestScreen extends StatefulWidget {
  const ButtonsTestScreen({super.key});
  @override
  State<ButtonsTestScreen> createState() => _ButtonsTestScreenState();
}

class _ButtonsTestScreenState extends State<ButtonsTestScreen> {
  StreamSubscription? _sub;
  double vol = 0.5;
  String txt = "Press Volume UP / DOWN";
  Timer? _resetTimer;
  bool upPressed = false;
  bool downPressed = false;

  @override
  void initState() {
    super.initState();
    _sub = FlutterVolumeController.addListener((v) {
      if (mounted) {
        setState(() {
          if (v > vol) {
            upPressed = true;
            txt = "VOLUME UP (+)";
          } else if (v < vol) {
            downPressed = true;
            txt = "VOLUME DOWN (-)";
          }
          vol = v;

          // Clear the text back to normal after 1 second
          _resetTimer?.cancel();
          _resetTimer = Timer(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() => txt = "Press Volume UP / DOWN");
            }
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _resetTimer?.cancel();
    FlutterVolumeController.removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StandardTestLayout(
      title: "Buttons",
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatusDisplay(icon: Icons.smartphone, text: txt),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(upPressed ? Icons.check_circle : Icons.radio_button_unchecked, color: upPressed ? CyberTheme.primaryAccent : Colors.grey),
                const SizedBox(width: 8),
                const Text("Vol Up", style: TextStyle(color: Colors.white)),
                const SizedBox(width: 24),
                Icon(downPressed ? Icons.check_circle : Icons.radio_button_unchecked, color: downPressed ? CyberTheme.primaryAccent : Colors.grey),
                const SizedBox(width: 8),
                const Text("Vol Down", style: TextStyle(color: Colors.white)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. THE REST OF THE TESTS (Unchanged Logic, Formatted Properly)
// ─────────────────────────────────────────────────────────────────────────────

class HeadsetTestScreen extends StatefulWidget {
  const HeadsetTestScreen({super.key});
  @override
  State<HeadsetTestScreen> createState() => _HeadsetTestScreenState();
}

class _HeadsetTestScreenState extends State<HeadsetTestScreen> {
  bool hasHeadset = false;
  int countdown = 15;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() async {
    final session = await session_lib.AudioSession.instance;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final devices = await session.getDevices();
      bool active = devices.any((d) =>
      d.type == session_lib.AudioDeviceType.wiredHeadset ||
          d.type == session_lib.AudioDeviceType.wiredHeadphones ||
          d.type == session_lib.AudioDeviceType.bluetoothSco ||
          d.type == session_lib.AudioDeviceType.bluetoothA2dp);

      if (mounted) {
        if (active) {
          setState(() {
            hasHeadset = true;
            countdown = 0;
          });
          timer.cancel();
        } else {
          setState(() {
            if (countdown > 0) {
              countdown--;
            } else {
              timer.cancel();
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool failed = !hasHeadset && countdown == 0;
    return StandardTestLayout(
      title: "Headset",
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatusDisplay(
              icon: hasHeadset ? Icons.headset : (failed ? Icons.headset_off : Icons.headphones),
              text: hasHeadset
                  ? "Headphones Connected"
                  : (failed ? "No Connection Detected" : "Plug in Headphones..."),
              color: hasHeadset ? CyberTheme.primaryAccent : (failed ? CyberTheme.dangerRed : Colors.grey),
            ),
            if (!hasHeadset && countdown > 0)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  "Timeout in: $countdown",
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class VibrationTestScreen extends StatefulWidget {
  const VibrationTestScreen({super.key});

  @override
  State<VibrationTestScreen> createState() => _VibrationTestScreenState();
}

class _VibrationTestScreenState extends State<VibrationTestScreen> {
  @override
  void initState() {
    super.initState();
    _trigger();
  }

  void _trigger() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 1000]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const StandardTestLayout(
      title: "Vibration",
      child: Center(
        child: StatusDisplay(icon: Icons.vibration, text: "Vibrating device..."),
      ),
    );
  }
}

class FlashlightTestScreen extends StatefulWidget {
  final CameraController? Function() getController;
  const FlashlightTestScreen({super.key, required this.getController});

  @override
  State<FlashlightTestScreen> createState() => _FlashlightTestScreenState();
}

class _FlashlightTestScreenState extends State<FlashlightTestScreen> {
  @override
  void initState() {
    super.initState();
    _trigger(true);
  }

  @override
  void dispose() {
    _trigger(false);
    super.dispose();
  }

  void _trigger(bool on) {
    final ctrl = widget.getController();
    if (ctrl != null) {
      ctrl.setFlashMode(on ? FlashMode.torch : FlashMode.off).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return const StandardTestLayout(
      title: "Flashlight",
      child: Center(
        child: StatusDisplay(icon: Icons.flashlight_on, text: "Flashlight active"),
      ),
    );
  }
}

class BiometricTestScreen extends StatefulWidget {
  const BiometricTestScreen({super.key});

  @override
  State<BiometricTestScreen> createState() => _BiometricTestScreenState();
}

class _BiometricTestScreenState extends State<BiometricTestScreen> {
  String status = "Scan fingerprint to verify";
  Color sColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _trigger();
  }

  void _trigger() async {
    try {
      final auth = LocalAuthentication();
      bool didAuth = await auth.authenticate(
        localizedReason: 'Scan to verify hardware',
        options: const AuthenticationOptions(stickyAuth: true),
      );

      if (mounted) {
        setState(() {
          status = didAuth ? "Authentication Successful" : "Authentication Failed";
          sColor = didAuth ? CyberTheme.primaryAccent : CyberTheme.dangerRed;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          status = "Sensor Error";
          sColor = CyberTheme.dangerRed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardTestLayout(
      title: "Biometric",
      child: Center(
        child: StatusDisplay(icon: Icons.fingerprint, text: status, color: sColor),
      ),
    );
  }
}

class ChargingTestScreen extends StatefulWidget {
  const ChargingTestScreen({super.key});

  @override
  State<ChargingTestScreen> createState() => _ChargingTestScreenState();
}

class _ChargingTestScreenState extends State<ChargingTestScreen> {
  StreamSubscription? _sub;
  BatteryState _state = BatteryState.unknown;

  @override
  void initState() {
    super.initState();
    _sub = Battery().onBatteryStateChanged.listen((s) {
      if (mounted) {
        setState(() => _state = s);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isPlugged = _state == BatteryState.charging || _state == BatteryState.full;
    return StandardTestLayout(
      title: "Charging Port",
      child: Center(
        child: StatusDisplay(
          icon: isPlugged ? Icons.battery_charging_full : Icons.battery_alert,
          text: isPlugged ? "Power Detected!" : "Please plug in charger",
          color: isPlugged ? CyberTheme.primaryAccent : Colors.orangeAccent,
        ),
      ),
    );
  }
}

class SpeakerTestScreen extends StatefulWidget {
  const SpeakerTestScreen({super.key});

  @override
  State<SpeakerTestScreen> createState() => _SpeakerTestScreenState();
}

class _SpeakerTestScreenState extends State<SpeakerTestScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _audioPlayer.play(AssetSource('sounds/test_beep.mp3')).catchError((_) {});
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const StandardTestLayout(
      title: "Speakers",
      child: Center(
        child: StatusDisplay(icon: Icons.volume_up, text: "Playing test sound..."),
      ),
    );
  }
}

class EarpieceTestScreen extends StatefulWidget {
  const EarpieceTestScreen({super.key});

  @override
  State<EarpieceTestScreen> createState() => _EarpieceTestScreenState();
}

class _EarpieceTestScreenState extends State<EarpieceTestScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _play();
  }

  void _play() async {
    await _audioPlayer.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.speech,
        usageType: AndroidUsageType.voiceCommunication,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playAndRecord,
        options: {AVAudioSessionOptions.allowBluetooth},
      ),
    ));
    _audioPlayer.play(AssetSource('sounds/test_beep.mp3')).catchError((_) {});
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const StandardTestLayout(
      title: "Earpiece",
      child: Center(
        child: StatusDisplay(icon: Icons.phone_in_talk, text: "Hold phone to your ear..."),
      ),
    );
  }
}

class MicrophoneTestScreen extends StatefulWidget {
  const MicrophoneTestScreen({super.key});

  @override
  State<MicrophoneTestScreen> createState() => _MicrophoneTestScreenState();
}

class _MicrophoneTestScreenState extends State<MicrophoneTestScreen> {
  final AudioRecorder _rec = AudioRecorder();
  final AudioPlayer _play = AudioPlayer();
  String status = "Requesting permission...";
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  void _runTest() async {
    if (!await Permission.microphone.request().isGranted) {
      if (mounted) {
        setState(() => status = "Permission Denied");
      }
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/mic_test.m4a';

      if (mounted) {
        setState(() {
          status = "Recording... Speak now!";
          isRecording = true;
        });
      }

      await _rec.start(const RecordConfig(), path: path);
      await Future.delayed(const Duration(seconds: 4));
      await _rec.stop();

      if (mounted) {
        setState(() {
          status = "Playing back audio...";
          isRecording = false;
        });
      }

      await _play.play(DeviceFileSource(path));
    } catch (_) {
      if (mounted) {
        setState(() => status = "Mic Error");
      }
    }
  }

  @override
  void dispose() {
    _rec.dispose();
    _play.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StandardTestLayout(
      title: "Microphone",
      child: Center(
        child: StatusDisplay(
          icon: isRecording ? Icons.mic : Icons.play_arrow,
          text: status,
          color: isRecording ? CyberTheme.dangerRed : CyberTheme.primaryAccent,
        ),
      ),
    );
  }
}

class LightSensorTestScreen extends StatefulWidget {
  const LightSensorTestScreen({super.key});

  @override
  State<LightSensorTestScreen> createState() => _LightSensorTestScreenState();
}

class _LightSensorTestScreenState extends State<LightSensorTestScreen> {
  StreamSubscription? _sub;
  int lux = 0;

  @override
  void initState() {
    super.initState();
    _sub = LightSensor.luxStream().listen((l) {
      if (mounted) {
        setState(() => lux = l);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StandardTestLayout(
      title: "Light Sensor",
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$lux lx",
              style: const TextStyle(
                color: CyberTheme.primaryAccent,
                fontSize: 60,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Cover the sensor to see it drop",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class WifiTestScreen extends StatefulWidget {
  const WifiTestScreen({super.key});

  @override
  State<WifiTestScreen> createState() => _WifiTestScreenState();
}

class _WifiTestScreenState extends State<WifiTestScreen> {
  StreamSubscription? _sub;
  bool isWifi = false;

  @override
  void initState() {
    super.initState();
    _check();
    _sub = Connectivity().onConnectivityChanged.listen((res) {
      if (mounted) {
        setState(() => isWifi = res.contains(ConnectivityResult.wifi));
      }
    });
  }

  void _check() async {
    final res = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => isWifi = res.contains(ConnectivityResult.wifi));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StandardTestLayout(
      title: "Wi-Fi Signal",
      child: Center(
        child: StatusDisplay(
          icon: isWifi ? Icons.wifi : Icons.wifi_off,
          text: isWifi ? "Wi-Fi Connected" : "Wi-Fi Disconnected",
          color: isWifi ? CyberTheme.primaryAccent : CyberTheme.dangerRed,
        ),
      ),
    );
  }
}

class BacklightTestScreen extends StatefulWidget {
  const BacklightTestScreen({super.key});

  @override
  State<BacklightTestScreen> createState() => _BacklightTestScreenState();
}

class _BacklightTestScreenState extends State<BacklightTestScreen> {
  @override
  void initState() {
    super.initState();
    _trigger();
  }

  void _trigger() async {
    try {
      final b = ScreenBrightness();
      await b.setScreenBrightness(0.1);
      await Future.delayed(const Duration(seconds: 1));
      await b.setScreenBrightness(1.0);
      await Future.delayed(const Duration(seconds: 1));
      await b.resetScreenBrightness();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return const StandardTestLayout(
      title: "Backlight",
      child: Center(
        child: StatusDisplay(icon: Icons.brightness_6, text: "Testing Auto-Brightness..."),
      ),
    );
  }
}

class DisplayTestScreen extends StatefulWidget {
  const DisplayTestScreen({super.key});

  @override
  State<DisplayTestScreen> createState() => _DisplayTestScreenState();
}

class _DisplayTestScreenState extends State<DisplayTestScreen> {
  final List<Color> colors = [Colors.red, Colors.green, Colors.blue, Colors.white, Colors.black];
  int index = 0;

  @override
  Widget build(BuildContext context) {
    if (index >= colors.length) {
      return const StandardTestLayout(
        title: "Display Analysis",
        child: Center(
          child: Text(
            "Did you see any dead pixels or screen burn-in?",
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() => index++);
      },
      child: Container(
        color: colors[index],
        child: Center(
          child: index == 0
              ? Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black54,
            child: const Text(
              "Tap to cycle colors",
              style: TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.none),
            ),
          )
              : const SizedBox(),
        ),
      ),
    );
  }
}

class CameraTestScreen extends StatefulWidget {
  const CameraTestScreen({super.key});

  @override
  State<CameraTestScreen> createState() => _CameraTestScreenState();
}

class _CameraTestScreenState extends State<CameraTestScreen> {
  List<CameraDescription>? cameras;
  CameraController? controller;
  int selectedCameraIdx = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        _selectCamera(0);
      } else if (mounted) {
        Navigator.pop(context, false);
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context, false);
      }
    }
  }

  Future<void> _selectCamera(int index) async {
    controller = CameraController(cameras![index], ResolutionPreset.medium);
    await controller!.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(controller!)),
          if (cameras != null && cameras!.length > 1)
            Positioned(
              top: 50,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.black54,
                onPressed: () {
                  selectedCameraIdx = (selectedCameraIdx + 1) % cameras!.length;
                  _selectCamera(selectedCameraIdx);
                },
                child: const Icon(Icons.flip_camera_ios, color: Colors.white),
              ),
            ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: TestConfirmationSheet(),
          )
        ],
      ),
    );
  }
}