import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// --- MAIN SCREEN ---

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

enum TestStatus { untouched, running, passed, failed }

class HardwareTestScreen extends StatefulWidget {
  const HardwareTestScreen({super.key});

  @override
  State<HardwareTestScreen> createState() => _HardwareTestScreenState();
}

class _HardwareTestScreenState extends State<HardwareTestScreen> {
  late List<HardwareTestItem> _tests;
  CameraController? _cameraController;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initCamera();
    _tests = [
      _buildVibrationTest(),
      _buildFlashlightTest(),
      _buildBiometricTest(),
      _buildAccelerometerTest(),
      _buildChargingTest(),
      _buildDisplayTest(),
      _buildMultitouchTest(),
      _buildSpeakerTest(),
      _buildMicrophoneTest(),
      _buildSensorsTest(),
      _buildProximityTest(),
      _buildLightSensorTest(),
      _buildWiFiSignalTest(),
      _buildHeadsetTest(),
      _buildEarpieceTest(),
      _buildButtonsTest(),
      _buildBacklightTest(),
      _buildCameraTest(),
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
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    FlutterVolumeController.removeListener();
    super.dispose();
  }

  void _updateTestStatus(int index, TestStatus newStatus) {
    if (mounted) {
      setState(() {
        _tests[index].status = newStatus;
      });
    }
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
          icon: const Icon(Icons.arrow_back_ios, color: CyberTheme.neonGreen),
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
      case TestStatus.passed: statusColor = CyberTheme.neonGreen; statusIcon = Icons.check_circle; break;
      case TestStatus.failed: statusColor = CyberTheme.dangerRed; statusIcon = Icons.cancel; break;
      case TestStatus.running: statusColor = Colors.yellowAccent; statusIcon = Icons.hourglass_empty; break;
      default: statusColor = Colors.grey; statusIcon = Icons.help_outline; break;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      leading: Icon(item.icon, color: CyberTheme.neonGreen.withValues(alpha: 0.7), size: 28),
      title: Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing: item.status == TestStatus.running
          ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: statusColor))
          : Icon(statusIcon, color: statusColor, size: 28),
      onTap: item.status == TestStatus.running
          ? null
          : () => item.onTestFunc(context, (s) => _updateTestStatus(index, s)),
    );
  }

  // --- TESTS ---

  HardwareTestItem _buildVibrationTest() {
    return HardwareTestItem(
      name: "Vibration",
      icon: Icons.vibration,
      onTestFunc: (ctx, updateStatus) async {
        updateStatus(TestStatus.running);
        if (await Vibration.hasVibrator() == true) {
          Vibration.vibrate(pattern: [0, 200, 100, 200]);
          if (!ctx.mounted) return;
          _showConfirmationDialog(ctx, "Did it vibrate?", updateStatus);
        } else {
          updateStatus(TestStatus.failed);
        }
      },
    );
  }

  HardwareTestItem _buildFlashlightTest() {
    return HardwareTestItem(
      name: "Flashlight",
      icon: Icons.flashlight_on,
      onTestFunc: (ctx, updateStatus) async {
        if (_cameraController == null) { updateStatus(TestStatus.failed); return; }
        updateStatus(TestStatus.running);
        try {
          await _cameraController!.setFlashMode(FlashMode.torch);
          await Future.delayed(const Duration(seconds: 2));
          await _cameraController!.setFlashMode(FlashMode.off);
          if (!ctx.mounted) return;
          _showConfirmationDialog(ctx, "Did it turn on?", updateStatus);
        } catch (_) { updateStatus(TestStatus.failed); }
      },
    );
  }

  HardwareTestItem _buildBiometricTest() {
    return HardwareTestItem(
      name: "Biometric Scanner",
      icon: Icons.fingerprint,
      onTestFunc: (ctx, updateStatus) async {
        updateStatus(TestStatus.running);
        try {
          final auth = LocalAuthentication();
          bool didAuth = await auth.authenticate(
            localizedReason: 'Scan to verify',
            options: const AuthenticationOptions(stickyAuth: true),
          );
          updateStatus(didAuth ? TestStatus.passed : TestStatus.failed);
        } catch (e) {
          debugPrint("Biometric Error: $e");
          if (ctx.mounted) _showErrorSnackBar(ctx, "Auth Error: $e");
          updateStatus(TestStatus.failed);
        }
      },
    );
  }

  HardwareTestItem _buildAccelerometerTest() {
    return HardwareTestItem(
      name: "Accelerometer",
      icon: Icons.screen_rotation,
      onTestFunc: (ctx, updateStatus) async {
        updateStatus(TestStatus.running);
        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Shake your phone!"), backgroundColor: CyberTheme.neonGreen));

        bool passed = false;
        final sub = accelerometerEventStream().listen((event) {
          if ((event.x.abs() > 15 || event.y.abs() > 15) && !passed) {
            passed = true;
            updateStatus(TestStatus.passed);
          }
        });

        Future.delayed(const Duration(seconds: 4), () {
          sub.cancel();
          if (!passed) updateStatus(TestStatus.failed);
        });
      },
    );
  }

  HardwareTestItem _buildChargingTest() {
    return HardwareTestItem(
      name: "Charging Port",
      icon: Icons.electrical_services,
      onTestFunc: (ctx, updateStatus) async {
        updateStatus(TestStatus.running);
        final battery = Battery();
        if ((await battery.batteryState) == BatteryState.charging) { updateStatus(TestStatus.passed); return; }

        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Plug in charger now..."), backgroundColor: CyberTheme.neonGreen));

        Timer.periodic(const Duration(seconds: 1), (timer) async {
          if ((await battery.batteryState) == BatteryState.charging) {
            timer.cancel();
            updateStatus(TestStatus.passed);
          }
          if (timer.tick > 8) {
            timer.cancel();
            updateStatus(TestStatus.failed);
          }
        });
      },
    );
  }

  HardwareTestItem _buildDisplayTest() {
    return HardwareTestItem(
      name: "Display (Dead Pixel)",
      icon: Icons.smartphone,
      onTestFunc: (ctx, updateStatus) async {
        final result = await Navigator.push(ctx, MaterialPageRoute(builder: (c) => const DisplayTestScreen()));
        updateStatus(result == true ? TestStatus.passed : TestStatus.failed);
      },
    );
  }

  HardwareTestItem _buildMultitouchTest() {
    return HardwareTestItem(
      name: "Multitouch",
      icon: Icons.touch_app,
      onTestFunc: (ctx, updateStatus) async {
        final result = await Navigator.push(ctx, MaterialPageRoute(builder: (c) => const MultitouchTestScreen()));
        updateStatus(result == true ? TestStatus.passed : TestStatus.failed);
      },
    );
  }

  HardwareTestItem _buildSpeakerTest() {
    return HardwareTestItem(
      name: "Speakers",
      icon: Icons.volume_up,
      onTestFunc: (ctx, updateStatus) async {
        updateStatus(TestStatus.running);
        try {
          await _audioPlayer.play(AssetSource('sounds/test_beep.mp3'));
          if (!ctx.mounted) return;
          _showConfirmationDialog(ctx, "Did you hear a BEEP?", updateStatus);
        } catch (_) {
          if(ctx.mounted) _showErrorSnackBar(ctx, "Missing 'assets/sounds/test_beep.mp3'");
          updateStatus(TestStatus.failed);
        }
      },
    );
  }

  HardwareTestItem _buildMicrophoneTest() {
    return HardwareTestItem(
      name: "Microphone",
      icon: Icons.mic,
      onTestFunc: (ctx, updateStatus) async {
        updateStatus(TestStatus.running);
        if (!await Permission.microphone.request().isGranted) { updateStatus(TestStatus.failed); return; }

        try {
          final dir = await getTemporaryDirectory();
          final path = '${dir.path}/mic_test.m4a';

          if (await _audioRecorder.hasPermission()) {
            await _audioRecorder.start(const RecordConfig(), path: path);
            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Recording... Speak!"), backgroundColor: CyberTheme.neonGreen));

            await Future.delayed(const Duration(seconds: 2));
            await _audioRecorder.stop();

            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Playing back..."), backgroundColor: Colors.blueAccent));
            await _audioPlayer.play(DeviceFileSource(path));

            await Future.delayed(const Duration(seconds: 3));
            if (!ctx.mounted) return;
            _showConfirmationDialog(ctx, "Did you hear yourself?", updateStatus);
          }
        } catch (_) { updateStatus(TestStatus.failed); }
      },
    );
  }

  HardwareTestItem _buildSensorsTest() {
    return HardwareTestItem(
      name: "Sensor Suite",
      icon: Icons.sensors,
      onTestFunc: (ctx, updateStatus) async {
        updateStatus(TestStatus.running);
        bool detected = false;
        final sub = gyroscopeEventStream().listen((e) { if (e.x != 0) detected = true; });
        await Future.delayed(const Duration(seconds: 2));
        await sub.cancel();
        updateStatus(detected ? TestStatus.passed : TestStatus.failed);
      },
    );
  }

  HardwareTestItem _buildProximityTest() {
    return HardwareTestItem(
      name: "Proximity Sensor",
      icon: Icons.near_me,
      onTestFunc: (ctx, updateStatus) async {
        updateStatus(TestStatus.running);
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
              content: Text("Cover the top of your phone with your hand."),
              backgroundColor: CyberTheme.neonGreen
          ));
        }

        bool passed = false;
        StreamSubscription<int>? sub;

        try {
          // FIX 1: Removed '()' because events is a getter (Stream), not a method.
          sub = ProximitySensor.events.listen((int event) {
            if (!passed) {
              if (event >= 0) {
                passed = true;
                sub?.cancel();
                updateStatus(TestStatus.passed);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text("Proximity Detected!"),
                      backgroundColor: CyberTheme.neonGreen
                  ));
                }
              }
            }
          });

          await Future.delayed(const Duration(seconds: 5));

          if (!passed) {
            sub?.cancel();
            updateStatus(TestStatus.failed);
            if (ctx.mounted) _showErrorSnackBar(ctx, "No object detected.");
          }
        } catch (e) {
          debugPrint("Proximity Error: $e");
          updateStatus(TestStatus.failed);
        }
      },
    );
  }

  HardwareTestItem _buildLightSensorTest() {
    return HardwareTestItem(
      name: "Light Sensor",
      icon: Icons.light_mode,
      onTestFunc: (ctx, updateStatus) async {
        updateStatus(TestStatus.running);
        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Change light conditions..."), backgroundColor: CyberTheme.neonGreen));

        bool passed = false;
        int? startLux;
        StreamSubscription<int>? sub;
        try {
          sub = LightSensor.luxStream().listen((int lux) {
            if (startLux == null) startLux = lux;
            else if ((lux - startLux!).abs() > 5 && !passed) {
              passed = true;
              sub?.cancel();
              updateStatus(TestStatus.passed);
            }
          });
          await Future.delayed(const Duration(seconds: 5));
          if (!passed) { sub?.cancel(); updateStatus(TestStatus.failed); }
        } catch (_) { updateStatus(TestStatus.failed); }
      },
    );
  }

  HardwareTestItem _buildWiFiSignalTest() {
    return HardwareTestItem(
      name: "Wi-Fi Signal",
      icon: Icons.wifi,
      onTestFunc: (ctx, updateStatus) async {
        updateStatus(TestStatus.running);
        final result = await Connectivity().checkConnectivity();
        if (result.contains(ConnectivityResult.wifi)) {
          updateStatus(TestStatus.passed);
        } else {
          updateStatus(TestStatus.failed);
        }
      },
    );
  }

  HardwareTestItem _buildHeadsetTest() {
    return HardwareTestItem(
      name: "Headset / Headphones", // Updated name
      icon: Icons.headset,
      onTestFunc: (ctx, updateStatus) async {
        updateStatus(TestStatus.running);

        try {
          // Use the alias 'session_lib' to avoid conflicts
          final session = await session_lib.AudioSession.instance;
          await session.configure(const session_lib.AudioSessionConfiguration.speech());

          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text("Connect Wired OR Bluetooth Headphones..."), backgroundColor: CyberTheme.neonGreen)
            );
          }

          Timer.periodic(const Duration(seconds: 1), (timer) async {
            final devices = await session.getDevices();

            // Check for ANY type of headphone
            bool hasHeadset = devices.any((device) =>
            device.type == session_lib.AudioDeviceType.wiredHeadset ||
                device.type == session_lib.AudioDeviceType.wiredHeadphones ||
                device.type == session_lib.AudioDeviceType.bluetoothSco ||  // Added Bluetooth
                device.type == session_lib.AudioDeviceType.bluetoothA2dp    // Added Bluetooth High Quality
            );

            if (hasHeadset) {
              timer.cancel();
              updateStatus(TestStatus.passed);
            }

            if (timer.tick > 15) {
              timer.cancel();
              if (ctx.mounted) _showErrorSnackBar(ctx, "No headphones detected.");
              updateStatus(TestStatus.failed);
            }
          });

        } catch (e) {
          debugPrint("Headset Test Error: $e");
          updateStatus(TestStatus.failed);
        }
      },
    );
  }

  HardwareTestItem _buildEarpieceTest() {
    return HardwareTestItem(
      name: "Earpiece",
      icon: Icons.phone_in_talk,
      onTestFunc: (ctx, updateStatus) async {
        updateStatus(TestStatus.running);
        try {
          // FORCE Voice Communication mode (Treats it like a phone call)
          await _audioPlayer.setAudioContext(AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: false,
              stayAwake: true,
              contentType: AndroidContentType.speech, // Changed from music
              usageType: AndroidUsageType.voiceCommunication, // Changed from media
              audioFocus: AndroidAudioFocus.gain,
            ),
            iOS: AudioContextIOS(
              // playAndRecord is required for the receiver (earpiece) on iOS
              category: AVAudioSessionCategory.playAndRecord,
              options: {AVAudioSessionOptions.allowBluetooth}, // Standard options
            ),
          ));

          await _audioPlayer.play(AssetSource('sounds/test_beep.mp3'));

          if (!ctx.mounted) return;
          _showConfirmationDialog(ctx, "Hear sound ONLY from the top earpiece?", updateStatus);
        } catch (_) {
          updateStatus(TestStatus.failed);
        }
      },
    );
  }

  HardwareTestItem _buildButtonsTest() {
    return HardwareTestItem(
      name: "Volume Buttons",
      icon: Icons.volume_up_outlined,
      onTestFunc: (ctx, updateStatus) async {
        updateStatus(TestStatus.running);
        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Press Volume UP then DOWN"), backgroundColor: CyberTheme.neonGreen));

        bool pressedUp = false;
        bool pressedDown = false;
        try {
          double? startVol = await FlutterVolumeController.getVolume();
          startVol ??= 0.5;

          StreamSubscription<double> sub = FlutterVolumeController.addListener((volume) {
            if (volume > startVol!) pressedUp = true;
            if (volume < startVol!) pressedDown = true;
            startVol = volume;
            if (pressedUp && pressedDown) {
              updateStatus(TestStatus.passed);
            }
          });

          await Future.delayed(const Duration(seconds: 10));
          sub.cancel();
          FlutterVolumeController.removeListener();

          if (!(pressedUp && pressedDown)) {
            updateStatus(TestStatus.failed);
          }
        } catch (_) { updateStatus(TestStatus.failed); }
      },
    );
  }

  HardwareTestItem _buildBacklightTest() {
    return HardwareTestItem(
      name: "Screen Backlight",
      icon: Icons.brightness_6,
      onTestFunc: (ctx, updateStatus) async {
        updateStatus(TestStatus.running);
        try {
          final brightness = ScreenBrightness();

          // FIX: Changed 'setApplicationScreenBrightness' to 'setScreenBrightness'
          await brightness.setScreenBrightness(0.0);
          await Future.delayed(const Duration(milliseconds: 800));

          await brightness.setScreenBrightness(1.0);
          await Future.delayed(const Duration(milliseconds: 800));

          // FIX: Changed 'resetApplicationScreenBrightness' to 'resetScreenBrightness'
          await brightness.resetScreenBrightness();

          if (!ctx.mounted) return;
          _showConfirmationDialog(ctx, "Did brightness change?", updateStatus);
        } catch (e) {
          // Check debug console if this fails to see if permissions are missing
          debugPrint("Backlight Test Error: $e");
          updateStatus(TestStatus.failed);
        }
      },
    );
  }

  HardwareTestItem _buildCameraTest() {
    return HardwareTestItem(
      name: "Cameras",
      icon: Icons.camera_alt,
      onTestFunc: (ctx, updateStatus) async {
        final result = await Navigator.push(ctx, MaterialPageRoute(builder: (c) => const CameraTestScreen()));
        updateStatus(result == true ? TestStatus.passed : TestStatus.failed);
      },
    );
  }

  // --- HELPERS ---
  void _showConfirmationDialog(BuildContext ctx, String question, Function(TestStatus) updateStatus) {
    if (!ctx.mounted) return;
    showDialog(context: ctx, barrierDismissible: false, builder: (context) => AlertDialog(
      backgroundColor: CyberTheme.surface,
      title: const Text("Confirm", style: TextStyle(color: CyberTheme.neonGreen)),
      content: Text(question, style: const TextStyle(color: Colors.white)),
      actions: [
        TextButton(onPressed: () { Navigator.pop(context); updateStatus(TestStatus.failed); }, child: const Text("NO", style: TextStyle(color: CyberTheme.dangerRed))),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.neonGreen), onPressed: () { Navigator.pop(context); updateStatus(TestStatus.passed); }, child: const Text("YES", style: TextStyle(color: Colors.black)))
      ],
    ));
  }

  void _showErrorSnackBar(BuildContext ctx, String msg) {
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg), backgroundColor: CyberTheme.dangerRed));
  }
}

// --- VISUAL TEST CLASSES ---

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
    return GestureDetector(
      onTap: () {
        if (index < colors.length - 1) setState(() => index++);
        else Navigator.pop(context, true);
      },
      child: Container(
        color: colors[index],
        child: const Center(child: Text("Tap to cycle colors", style: TextStyle(color: Colors.grey, fontSize: 14, decoration: TextDecoration.none))),
      ),
    );
  }
}

class MultitouchTestScreen extends StatefulWidget {
  const MultitouchTestScreen({super.key});
  @override
  State<MultitouchTestScreen> createState() => _MultitouchTestScreenState();
}

class _MultitouchTestScreenState extends State<MultitouchTestScreen> {
  // Map of pointer ID to position
  final Map<int, Offset> pointers = {};
  bool passed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) {
        setState(() {
          pointers[e.pointer] = e.localPosition;
          if (pointers.length >= 3) passed = true;
        });
      },
      onPointerMove: (e) {
        setState(() {
          if (pointers.containsKey(e.pointer)) {
            pointers[e.pointer] = e.localPosition;
          }
        });
      },
      onPointerUp: (e) => setState(() => pointers.remove(e.pointer)),
      onPointerCancel: (e) => setState(() => pointers.remove(e.pointer)),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Instructions
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Touch with 3 fingers\nDetected: ${pointers.length}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: passed ? CyberTheme.neonGreen : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (passed)
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.neonGreen),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("FINISH", style: TextStyle(color: Colors.black))
                    )
                ],
              ),
            ),
            // Draw circles for every touch point
            ...pointers.values.map((pos) => Positioned(
              left: pos.dx - 30,
              top: pos.dy - 30,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent, width: 2),
                  color: Colors.blueAccent.withOpacity(0.3),
                ),
              ),
            )),
          ],
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
      } else { if(mounted) Navigator.pop(context, false); }
    } catch (_) { if(mounted) Navigator.pop(context, false); }
  }

  Future<void> _selectCamera(int index) async {
    controller = CameraController(cameras![index], ResolutionPreset.medium);
    await controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() { controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(controller!)),
          Positioned(bottom: 30, left: 0, right: 0, child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(heroTag: "fail", backgroundColor: Colors.red, onPressed: () => Navigator.pop(context, false), child: const Icon(Icons.close)),
              if (selectedCameraIdx < cameras!.length - 1)
                FloatingActionButton(heroTag: "next", backgroundColor: Colors.blue, onPressed: () { selectedCameraIdx++; _selectCamera(selectedCameraIdx); }, child: const Icon(Icons.flip_camera_ios)),
              FloatingActionButton(heroTag: "pass", backgroundColor: Colors.green, onPressed: () => Navigator.pop(context, true), child: const Icon(Icons.check)),
            ],
          ))
        ],
      ),
    );
  }
}