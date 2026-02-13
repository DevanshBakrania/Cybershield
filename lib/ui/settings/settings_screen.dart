import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../storage/hive_boxes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  /// Logic for the Wipe Data (Self-Destruct)
  void _confirmSelfDestruct() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberTheme.surface, // ✅ Fixed: cardColor -> surface
        title: const Text("⚠️ SELF DESTRUCT",
            style: TextStyle(color: CyberTheme.dangerRed, fontWeight: FontWeight.bold)), // ✅ Fixed: danger -> dangerRed
        content: const Text(
          "This will permanently delete ALL encrypted data and keys.\n\nThe app will close immediately.",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.dangerRed), // ✅ Fixed
            onPressed: () async {
              // Clear all Hive boxes
              await HiveBoxes.vault.clear();
              await HiveBoxes.dummy.clear();
              // Exit app
              SystemNavigator.pop();
            },
            child: const Text("CONFIRM WIPE", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background, // ✅ Fixed: Match App Background
      appBar: AppBar(
        title: const Text("SETTINGS", style: TextStyle(letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // 1. PROFILE HEADER
          _buildProfileHeader(),

          const SizedBox(height: 20),

          // 2. ACCOUNT & DANGER ZONE
          _buildSectionHeader("ACCOUNT OPERATIONS"),

          // Logout Tile
          _buildTile(
            Icons.logout,
            "Logout",
            "Return to login screen",
                () => Navigator.of(context, rootNavigator: true).pushReplacementNamed(AppRoutes.pin),
          ),

          const Divider(color: Colors.white10, indent: 16, endIndent: 16),

          // Wipe All Data Tile
          ListTile(
            leading: const Icon(Icons.delete_forever, color: CyberTheme.dangerRed, size: 30), // ✅ Fixed
            title: const Text("Wipe All Data",
                style: TextStyle(color: CyberTheme.dangerRed, fontWeight: FontWeight.bold)), // ✅ Fixed
            subtitle: const Text("Permanent Self-Destruct", style: TextStyle(color: Colors.grey)),
            onTap: _confirmSelfDestruct,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: CyberTheme.surface, // ✅ Fixed: cardColor -> surface
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: CyberTheme.neonGreen, // ✅ Fixed: accent -> neonGreen
            child: Icon(Icons.person, color: Colors.black, size: 30),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Devansh Bakrania", // Updated Name based on User
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text("@dev_cyber", style: TextStyle(color: Colors.grey)),
            ],
          )
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
              color: CyberTheme.neonGreen, // ✅ Fixed
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5
          )
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, String sub, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(sub, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}