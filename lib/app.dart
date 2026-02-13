import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'core/theme_provider.dart'; // ✅ Required to recognize 'ThemeProvider' type

// Screens
import 'ui/splash/splash_screen.dart';
import 'ui/auth/pin_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/vault/vault_screen.dart';
import 'ui/dummy/dummy_notes_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/hardware/hardware_screen.dart';
import 'ui/network/network_screen.dart';
import 'ui/feed/security_feed_screen.dart';

class CyberShieldApp extends StatelessWidget {
  final ThemeProvider themeProvider; // ✅ Now this type is known

  const CyberShieldApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CyberShield',

          themeMode: themeProvider.themeMode,
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: CyberTheme.darkTheme, // ✅ Comes from core/theme.dart

          initialRoute: AppRoutes.splash,

          routes: {
            AppRoutes.splash: (context) => const SplashScreen(),
            AppRoutes.pin: (context) => const PinScreen(),
            AppRoutes.dashboard: (context) => const HomeScreen(),
            AppRoutes.vault: (context) => const VaultScreen(),
            AppRoutes.dummy: (context) => const DummyNotesScreen(),
            AppRoutes.settings: (context) => const SettingsScreen(),
            AppRoutes.hardware: (context) => const HardwareScreen(),
            AppRoutes.network: (context) => const NetworkScreen(),
            AppRoutes.feed: (context) => const SecurityFeedScreen(),
          },
        );
      },
    );
  }
}