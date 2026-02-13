import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../feed/security_feed_screen.dart';
import '../vault/vault_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // The 4 main screens available in the tabs
  final List<Widget> _screens = [
    const DashboardScreen(),
    const SecurityFeedScreen(),
    const VaultScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background, // ✅ Fixed: Using correct background color
      // IndexedStack preserves the state of each tab (doesn't reload when switching)
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: CyberTheme.neonGreen.withValues(alpha: 0.2), // ✅ Fixed: accent -> neonGreen
            ),
          ),
          color: CyberTheme.background, // ✅ Fixed
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: CyberTheme.background, // ✅ Fixed
          selectedItemColor: CyberTheme.neonGreen, // ✅ Fixed: accent -> neonGreen
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed, // Ensures labels are always visible
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: "DASHBOARD"
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.rss_feed),
                label: "FEED"
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.lock_outline),
                activeIcon: Icon(Icons.lock),
                label: "VAULT"
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: "SETTINGS"
            ),
          ],
        ),
      ).animate().slideY(begin: 1, duration: 500.ms, curve: Curves.easeOut),
    );
  }
}