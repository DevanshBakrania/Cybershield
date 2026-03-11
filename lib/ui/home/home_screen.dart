import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme.dart';

import '../dashboard/dashboard_screen.dart';
import '../feed/security_feed_screen.dart';
import '../settings/settings_screen.dart';

const Color cyberGreen = Color(0xFFCCFF00);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const SecurityFeedScreen(),
    const SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,

      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: cyberGreen.withValues(alpha: 0.2),
            ),
          ),
          color: CyberTheme.background,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: CyberTheme.background,
          selectedItemColor: cyberGreen,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: "DASHBOARD",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rss_feed),
              label: "FEED",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: "SETTINGS",
            ),
          ],
        ),
      ).animate().slideY(
        begin: 1,
        duration: 500.ms,
        curve: Curves.easeOut,
      ),
    );
  }
}