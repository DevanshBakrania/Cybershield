import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'core/theme_provider.dart';

// Screens
import 'ui/splash/splash_screen.dart';
import 'ui/dashboard/dashboard_screen.dart';

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

          routes: {
            AppRoutes.splash: (_) => const SplashScreen(),
            AppRoutes.dashboard: (_) => const DashboardScreen(),
          },
        );
      },
    );
  }
}