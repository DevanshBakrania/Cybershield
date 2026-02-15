import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../storage/hive_boxes.dart';
import '../../models/user_model.dart';

const Color cyberGreen = Color.fromARGB(255, 51, 243, 17);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final users = HiveBoxes.users.values.toList();
    if (users.isNotEmpty) {
      // 🔐 Last logged-in / active user
      currentUser = users.last;
    }
  }

  /// Logic for the Wipe Data (Self-Destruct)
  void _confirmSelfDestruct() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberTheme.surface,
        title: const Text(
          "⚠️ SELF DESTRUCT",
          style: TextStyle(
            color: CyberTheme.dangerRed,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "This will permanently delete ALL encrypted data.\n\nThe app will close immediately.",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberTheme.dangerRed,
            ),
            onPressed: () async {
              await HiveBoxes.vault.clear();
              await HiveBoxes.dummy.clear();
              await HiveBoxes.users.clear();
              SystemNavigator.pop();
            },
            child: const Text(
              "CONFIRM WIPE",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        title: const Text(
          "SETTINGS",
          style: TextStyle(letterSpacing: 2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildProfileHeader(),

          const SizedBox(height: 20),

          _buildSectionHeader("ACCOUNT OPERATIONS"),

          _buildTile(
            Icons.logout,
            "Logout",
            "Return to login screen",
            () => Navigator.of(context, rootNavigator: true)
                .pushReplacementNamed(AppRoutes.login),
          ),

          const Divider(color: Colors.white10, indent: 16, endIndent: 16),

          ListTile(
            leading: const Icon(
              Icons.delete_forever,
              color: CyberTheme.dangerRed,
              size: 30,
            ),
            title: const Text(
              "Wipe All Data",
              style: TextStyle(
                color: CyberTheme.dangerRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              "Permanent Self-Destruct",
              style: TextStyle(color: Colors.grey),
            ),
            onTap: _confirmSelfDestruct,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─────────────────────────
  // UI HELPERS
  // ─────────────────────────

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: CyberTheme.surface,
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: cyberGreen,
            child: Icon(
              Icons.person,
              color: Colors.black,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentUser?.fullName ?? "Unknown User",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "@${currentUser?.username ?? 'unknown'}",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: cyberGreen,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTile(
    IconData icon,
    String title,
    String sub,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(sub, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
