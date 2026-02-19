import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../storage/hive_boxes.dart';

import '../dashboard/dashboard_screen.dart';
import '../feed/security_feed_screen.dart';
import '../settings/settings_screen.dart';
import '../vault/vault_entry_router.dart';

// 🔥 ADDED BACK: Import the intruder service
import '../../services/intruder_capture_service.dart';

/// 🔐 GLOBAL VAULT LOCK SIGNAL
final ValueNotifier<bool> vaultLockNotifier = ValueNotifier(false);

const Color cyberGreen = Color(0xFFCCFF00);

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({
    super.key,
    required this.username,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  UserModel? _user;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // 🔥 CHANGED: Made this method 'async' to support your teammate's new code
  Future<void> _loadUser() async {
    try {
      // 1. Find the user first
      final user = HiveBoxes.users.values.firstWhere(
            (u) => u.username == widget.username,
      );

      // 2. Do the async loading steps BEFORE assigning _user
      await HiveBoxes.openSavedNews(user.username);
      IntruderTrapService.init(user.username);

      // 3. Initialize screens
      _screens = [
        const DashboardScreen(),
        SecurityFeedScreen(
          username: user.username,
        ),
        VaultEntryRouter(
          user: user,
          vaultLockNotifier: vaultLockNotifier,
        ),
        const SettingsScreen(),
      ];

      // 4. FINALLY, assign _user and trigger the UI rebuild
      _user = user;
      setState(() {});

    } catch (e) {
      debugPrint("❌ HomeScreen user load failed: $e");
    }
  }

  void _onTabTapped(int index) {
    // 🔐 Leaving VAULT tab → force lock
    if (_currentIndex == 2 && index != 2) {
      vaultLockNotifier.value = true;
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        backgroundColor: CyberTheme.background,
        body: Center(
          child: CircularProgressIndicator(
            color: cyberGreen,
          ),
        ),
      );
    }

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
              // ✅ FIX: Updated from deprecated 'withOpacity' to 'withValues'
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
              icon: Icon(Icons.lock_outline),
              activeIcon: Icon(Icons.lock),
              label: "VAULT",
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