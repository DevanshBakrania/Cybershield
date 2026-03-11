import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // ✨ ADDED: Hive Import
import 'package:provider/provider.dart'; // ✨ ADDED: Provider Import
import 'app.dart';
import 'ui/monitors/overlay_widget.dart';
import 'core/battery_provider.dart';
import 'core/theme_provider.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold( // ✨ ADDED Scaffold
      backgroundColor: Colors.transparent,
      body: Center( // ✨ ADDED Center
        child: CyberOverlay(),
      ),
    ),
  ));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✨ ADDED: Wake up Hive and open your saved box
    await Hive.initFlutter();
    await Hive.openBox('savedNews');

    // 🎨 THEME
    final themeProvider = ThemeProvider();

    // ✨ ADDED: Wrapped CyberShieldApp in MultiProvider for the Battery SSOT
    runApp(
      MultiProvider(
        providers: [
          // This creates the central brain and starts the 3-second polling loop
          ChangeNotifierProvider(
            create: (_) => BatteryProvider()..startMonitoring(),
          ),
        ],
        child: CyberShieldApp(
          themeProvider: themeProvider,
        ),
      ),
    );
  } catch (e, stack) {
    debugPrint("CRITICAL STARTUP ERROR: $e");
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