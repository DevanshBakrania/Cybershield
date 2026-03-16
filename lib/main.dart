import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'ui/monitors/overlay_widget.dart';
import 'core/battery_provider.dart';
import 'core/theme_provider.dart';
import 'core/cpu_provider.dart';
import 'core/ram_provider.dart';
import 'core/network_provider.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: CyberOverlay(),
      ),
    ),
  ));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✨ WAKE UP HIVE DATABASES
    await Hive.initFlutter();
    await Hive.openBox('savedNews');
    await Hive.openBox('benchmarkLogs'); // ✨ ENGINE 4: Benchmark History

    final themeProvider = ThemeProvider();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => BatteryProvider()..startMonitoring(),
          ),
          ChangeNotifierProvider(
            create: (_) => CpuProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => RamProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => NetworkProvider(),
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