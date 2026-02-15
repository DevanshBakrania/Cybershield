import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/theme.dart';
import '../../widgets/cyber_ui.dart';

// Assuming you have the _DisplayTestScreen in the same file or imported
// If _DisplayTestScreen is in another file, import it.
// For this snippet, I am keeping the logic you provided.

class HardwareScreen extends StatefulWidget {
  const HardwareScreen({super.key});

  @override
  State<HardwareScreen> createState() => _HardwareScreenState();
}

class _HardwareScreenState extends State<HardwareScreen> {
  // 0 = Pending (?), 1 = Passed (✅), 2 = Failed/Skipped
  Map<String, int> testStatus = {
    "Flashlight": 0,
    "Vibration": 0,
    "Buttons": 0,
    "Multitouch": 0,
    "Display": 0,
    "Biometric Scanner": 0,
    "Proximity": 0,
    "Accelerometer": 0,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        title: const CyberNeonText("HARDWARE DIAGNOSTICS", size: 18),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader("BASIC TESTS"),
          _buildTestTile("Flashlight", Icons.flashlight_on, _testFlashlight),
          _buildTestTile("Vibration", Icons.vibration, _testVibration),
          _buildTestTile("Display", Icons.phone_android, _testDisplay),

          const SizedBox(height: 20),
          _buildSectionHeader("SENSORS"),
          _buildTestTile("Proximity", Icons.sensors, () => _manualPass("Proximity")),
          _buildTestTile("Accelerometer", Icons.screen_rotation, () => _manualPass("Accelerometer")),
          _buildTestTile("Multitouch", Icons.touch_app, () => _manualPass("Multitouch")),

          const SizedBox(height: 20),
          _buildSectionHeader("PRO FEATURES"),
          _buildTestTile("Biometric Scanner", Icons.fingerprint, _testBiometric, isPro: true),
          _buildTestTile("Speakers", Icons.volume_up, () => _manualPass("Speakers"), isPro: true),
          _buildTestTile("Microphone", Icons.mic, () => _manualPass("Microphone"), isPro: true),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
          title,
          style: TextStyle(color: CyberTheme.textGrey.withValues(alpha: 0.6), fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)
      ),
    );
  }

  Widget _buildTestTile(String title, IconData icon, VoidCallback onTap, {bool isPro = false}) {
    int status = testStatus[title] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: CyberTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Icon(icon, color: isPro ? CyberTheme.neonGreen : CyberTheme.textGrey, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    if (isPro)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: CyberTheme.neonGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                        child: const Text("PRO", style: TextStyle(color: CyberTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: status == 1 ? CyberTheme.neonGreen : Colors.grey.withValues(alpha: 0.2),
                ),
                child: Icon(
                  status == 1 ? Icons.check : Icons.question_mark,
                  color: status == 1 ? Colors.black : Colors.white54,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TESTS LOGIC ---

  void _manualPass(String key) {
    setState(() {
      testStatus[key] = (testStatus[key] == 1) ? 0 : 1;
    });
  }

  Future<void> _testVibration() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.heavyImpact();
    _manualPass("Vibration");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vibration Test Complete"), duration: Duration(milliseconds: 500)));
    }
  }

  Future<void> _testFlashlight() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final cam = cameras.first;
      final controller = CameraController(cam, ResolutionPreset.low);
      await controller.initialize();
      await controller.setFlashMode(FlashMode.torch);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Flashlight ON - Testing...")));

      await Future.delayed(const Duration(milliseconds: 800));
      await controller.setFlashMode(FlashMode.off);
      await controller.dispose();

      _manualPass("Flashlight");
    } catch (e) {
      debugPrint("Torch Error: $e");
    }
  }

  Future<void> _testDisplay() async {
    // Ensure you have the _DisplayTestScreen class defined below or imported
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => const _DisplayTestScreen())).then((_) {
      _manualPass("Display");
    });
  }

  Future<void> _testBiometric() async {
    final LocalAuthentication auth = LocalAuthentication();
    final bool canCheckBiometrics = await auth.canCheckBiometrics || await auth.isDeviceSupported();

    if (canCheckBiometrics) {
      try {
        bool didAuthenticate = await auth.authenticate(
            localizedReason: 'Please authenticate to test sensor',
            options: const AuthenticationOptions(biometricOnly: true));

        if (didAuthenticate) _manualPass("Biometric Scanner");
      } on PlatformException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Auth Error: ${e.message}")));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No Biometrics Found")));
      }
    }
  }
}

class _DisplayTestScreen extends StatefulWidget {
  const _DisplayTestScreen();
  @override
  State<_DisplayTestScreen> createState() => _DisplayTestScreenState();
}

class _DisplayTestScreenState extends State<_DisplayTestScreen> {
  final List<Color> colors = [Colors.red, Colors.green, Colors.blue, Colors.white, Colors.black];
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (index < colors.length - 1) {
          setState(() => index++);
        } else {
          Navigator.pop(context);
        }
      },
      child: Container(
        color: colors[index],
        child: const Center(
          child: Text("Tap to cycle colors", style: TextStyle(color: Colors.grey, fontSize: 14, decoration: TextDecoration.none)),
        ),
      ),
    );
  }
}