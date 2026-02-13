import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'storage/hive_boxes.dart';
import 'core/theme_provider.dart';
import 'models/vault_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Initialize Hive
    await Hive.initFlutter();

    // 2. Safe Adapter Registration
    // We try to register ONLY if it's not already there.
    // We check both ID 0 and ID 1 to cover potential mismatches in your generated file.
    if (!Hive.isAdapterRegistered(0) && !Hive.isAdapterRegistered(1)) {
      try {
        Hive.registerAdapter(VaultItemAdapter());
      } catch (e) {
        debugPrint("⚠️ Adapter already registered or ID conflict: $e");
      }
    }

    // 3. Open Boxes
    await Hive.openBox('settings');
    await Hive.openBox('passwords');
    await Hive.openBox('notes');
    await Hive.openBox('files');
    await Hive.openBox('saved_news');

    // 4. Initialize Custom Storage
    await HiveBoxes.init();

    // 5. Create Provider
    final themeProvider = ThemeProvider();

    // 6. Run App
    runApp(CyberShieldApp(themeProvider: themeProvider));

  } catch (e) {
    debugPrint("🔴 CRITICAL STARTUP ERROR: $e");
    // Fallback UI if main app fails
    runApp(const MaterialApp(home: Scaffold(body: Center(child: Text("Startup Failed. Check Console.")))));
  }
}