import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/vault_item.dart';
import '../storage/hive_boxes.dart';
import '../security/key_manager.dart';
import '../security/encryption.dart';

class IntruderTrapService {
  static CameraController? _controller;
  static bool _initialised = false;

  /// Call ONCE after user is known
  static Future<void> init(String username) async {
    if (_initialised) return;

    try {
      final cameras = await availableCameras();
      final frontCam = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCam,
        ResolutionPreset.medium, // Bumped to medium so the face is actually recognizable
        enableAudio: false,
      );

      await _controller!.initialize();
      _initialised = true;
    } catch (e) {
      debugPrint("Intruder camera init failed: $e");
    }
  }

  /// Capture & store evidence FOR USER
  static Future<void> capture(String username) async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        debugPrint("Camera not ready!");
        return;
      }

      // Allow camera exposure to settle before snapping (Prevents black photos/crashes)
      await Future.delayed(const Duration(milliseconds: 400));

      final XFile shot = await _controller!.takePicture();

      final dir = await getApplicationDocumentsDirectory();
      final evidenceDir = Directory('${dir.path}/intruder_evidence/$username');
      if (!evidenceDir.existsSync()) {
        await evidenceDir.create(recursive: true);
      }

      final filePath = '${evidenceDir.path}/intruder_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(shot.path).copy(filePath);

      final key = await KeyManager().getOrGenerateKey();
      final encryption = EncryptionService();
      encryption.init(key);

      final encryptedPath = encryption.encrypt(filePath);
      final boxName = 'vault_$username';

      // Check if box is open before opening (Prevents Hive errors)
      final vaultBox = Hive.isBoxOpen(boxName)
          ? Hive.box<VaultItem>(boxName)
          : await Hive.openBox<VaultItem>(boxName);

      await vaultBox.add(
        VaultItem(
          username: username,
          title: "⚠️ INTRUDER DETECTED",
          content: encryptedPath,
          category: "Evidence",
          createdAt: DateTime.now(),
        ),
      );

      debugPrint("📸 Intruder caught and path encrypted successfully!");
    } catch (e) {
      debugPrint("Intruder capture failed: $e");
    }
  }
}