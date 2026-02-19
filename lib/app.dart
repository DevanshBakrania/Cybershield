import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'core/theme_provider.dart';

// Screens
import 'ui/splash/splash_screen.dart';
import 'ui/auth/welcome_screen.dart';
import 'ui/auth/login_screen.dart';
import 'ui/auth/register_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/dummy/dummy_notes_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/hardware/hardware_screen.dart';
import 'ui/network/network_screen.dart';
import 'ui/feed/security_feed_screen.dart';

class CyberShieldApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const CyberShieldApp({
    super.key,
    required this.themeProvider,
  });

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
          darkTheme: CyberTheme.darkTheme,

          initialRoute: AppRoutes.splash,

          // ✅ ONLY PURE / STATIC ROUTES
          routes: {
            AppRoutes.splash: (_) => const SplashScreen(),
            AppRoutes.welcome: (_) => const WelcomeScreen(),
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.register: (_) => const RegisterScreen(),

            AppRoutes.hardware: (_) => const HardwareScreen(),
            AppRoutes.network: (_) => const NetworkScreen(),
            

            AppRoutes.settings: (_) => const SettingsScreen(),
            AppRoutes.dummy: (_) => const DummyNotesScreen(),
          },

          // ✅ USER-AWARE ROUTES ONLY
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case AppRoutes.dashboard:
                final username = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (_) => HomeScreen(username: username),
                );

              case AppRoutes.feed:
                final username = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (_) => SecurityFeedScreen(
                    username: username,
                  ),
                );
              default:
                return null;
            }
          },
        );
      },
    );
  }
}
