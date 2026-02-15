import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../models/vault_item.dart';
import '../storage/hive_boxes.dart';
import '../security/vault_service.dart';

class IntruderTrapService {
  static CameraController? _controller;
  static bool _initialised = false;

  static final VaultService _vault = VaultService();

  /// Call ONCE after user is known
  static Future<void> init(String username) async {
    if (_initialised) return;

    try {
      // 🔐 init vault encryption for this user
      await _vault.init(username);

      final cameras = await availableCameras();
      final frontCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCam,
        ResolutionPreset.low,
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
      if (_controller == null || !_controller!.value.isInitialized) return;

      final XFile shot = await _controller!.takePicture();

      final dir = await getApplicationDocumentsDirectory();
      final evidenceDir = Directory('${dir.path}/intruder_evidence/$username');
      await evidenceDir.create(recursive: true);

      final filePath =
          '${evidenceDir.path}/intruder_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await File(shot.path).copy(filePath);

      // 🔐 ENCRYPT PATH (CRITICAL FIX)
      final encryptedPath = _vault.encrypt(filePath);

      await HiveBoxes.vault.add(
        VaultItem(
          username: username, // 🔥 user-separated
          title: "⚠️ INTRUDER DETECTED",
          content: encryptedPath,
          category: "Evidence", // 🔥 stays separate
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint("Intruder capture failed: $e");
    }
  }

  static void dispose() {
    _controller?.dispose();
    _controller = null;
    _initialised = false;
  }
}
