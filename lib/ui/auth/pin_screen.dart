import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../services/biometric_service.dart';
import '../../storage/hive_boxes.dart';
import '../../models/vault_item.dart';
import '../../widgets/cyber_ui.dart'; // Import your new UI widgets

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});
  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  // Logic: Replaced String 'pin' with Controller for the TextField
  final TextEditingController _pinController = TextEditingController();

  final BiometricService _bio = BiometricService();
  CameraController? _cameraController;
  int _failedAttempts = 0;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _tryBiometric();
    _initSilentCamera(); // Keeps your Intruder Trap logic alive
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // 📸 SILENT CAMERA SETUP (Logic Preserved)
  Future<void> _initSilentCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCam = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCam,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  // 🚨 CAPTURE INTRUDER (Logic Preserved)
  Future<void> _captureIntruder() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final XFile image = await _cameraController!.takePicture();

        // 1. Get permanent directory
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String intruderPath = '${appDir.path}/intruder_evidence';
        await Directory(intruderPath).create(recursive: true);

        // 2. Create unique permanent path
        final String fileName = "intruder_${DateTime.now().millisecondsSinceEpoch}.jpg";
        final String permanentPath = '$intruderPath/$fileName';

        // 3. Move from temporary cache to permanent storage
        await File(image.path).copy(permanentPath);

        final trapItem = VaultItem(
          title: "⚠️ INTRUDER DETECTED",
          content: permanentPath,
          category: "Evidence",
          createdAt: DateTime.now(),
        );

        await HiveBoxes.vault.add(trapItem);
      } catch (e) {
        debugPrint("Intruder capture failed: $e");
      }
    }
  }

  // 🧬 BIOMETRIC LOGIC (Logic Preserved)
  void _tryBiometric() async {
    final settingsBox = Hive.box('settings');
    bool isBioEnabled = settingsBox.get('biometricsEnabled', defaultValue: false);

    if (isBioEnabled) {
      await Future.delayed(const Duration(milliseconds: 500));
      bool success = await _bio.authenticate();
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    }
  }

  // 🔐 VERIFY PIN (Updated to read from Controller)
  void _verifyPin() async {
    final inputPin = _pinController.text;

    // Loading effect simulation
    await Future.delayed(const Duration(milliseconds: 200));

    // ✅ Real Vault
    if (inputPin == "1234") {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      return;
    }

    // 🎭 Dummy Mode
    if (inputPin == "0000") {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.dummy);
      return;
    }

    // ❌ Wrong PIN Logic
    setState(() {
      _pinController.clear();
      _failedAttempts++;
    });

    if (_failedAttempts >= 2) {
      await _captureIntruder(); // SNAP! 📸
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Redirecting to Notes ...."),
                backgroundColor: Colors.grey,
                duration: Duration(seconds: 1)
            )
        );
        Navigator.pushReplacementNamed(context, AppRoutes.dummy);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("INVALID PASSCODE (1 Attempt Remaining)"),
                backgroundColor: CyberTheme.dangerRed, // Updated to new theme color
                duration: Duration(seconds: 2)
            )
        );
      }
    }
  }

  // 🎨 NEW UI: "Nord VPN" Style
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // 1. Header
              const CyberNeonText("Hi ! Welcome to\nCyberShield", size: 32),
              const SizedBox(height: 12),
              Text(
                "Enter your master PIN to access the secure vault.",
                style: CyberTheme.darkTheme.textTheme.bodyMedium,
              ),

              const SizedBox(height: 48),

              // 2. The "Nord Style" Input Field
              const Text(
                  "Master PIN",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 4
                ),
                decoration: const InputDecoration(
                  hintText: "• • • •",
                  counterText: "", // Hides the 0/4 counter
                  prefixIcon: Icon(Icons.lock_outline, color: CyberTheme.textGrey),
                ),
                onSubmitted: (_) => _verifyPin(), // Allows "Enter" key on keyboard
              ),

              const SizedBox(height: 32),

              // 3. The Big Neon Action Button
              CyberButton(
                text: "Unlock Vault",
                onTap: _verifyPin,
              ),

              const SizedBox(height: 20),

              // 4. Ghost / Biometric Option
              Center(
                child: TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint, color: CyberTheme.neonGreen),
                  label: const Text(
                    "Biometric Login",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const Spacer(),

              // 5. Footer
              Center(
                child: Text(
                  "Secured by AES-256 Encryption",
                  style: TextStyle(
                      color: CyberTheme.textGrey.withValues(alpha: 0.3),
                      fontSize: 12
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}