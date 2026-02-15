import 'package:flutter/material.dart';
import 'app.dart';
import 'storage/hive_boxes.dart';
import 'core/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ─────────────────────────
    // ✅ INIT HIVE (CRITICAL)
    // ─────────────────────────
    await HiveBoxes.init();

    

    // ─────────────────────────
    // 🎨 THEME
    // ─────────────────────────
    final themeProvider = ThemeProvider();

    runApp(
      CyberShieldApp(
        themeProvider: themeProvider,
      ),
    );
  } catch (e, stack) {
    debugPrint("🔴 CRITICAL STARTUP ERROR: $e");
    debugPrint("$stack");

    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Text(
              "Startup Failed.\nCheck console logs.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
