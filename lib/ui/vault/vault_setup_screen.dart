import 'package:flutter/material.dart';
import '../../models/user_model.dart';

import '../auth/pattern_input_widget.dart';
import '../auth/auth_hash.dart';
import 'vault_unlock_screen.dart';

class VaultSetupScreen extends StatefulWidget {
  final UserModel user;
  const VaultSetupScreen({super.key, required this.user});

  @override
  State<VaultSetupScreen> createState() => _VaultSetupScreenState();
}

class _VaultSetupScreenState extends State<VaultSetupScreen> {
  final pinCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  List<int> pattern = [];

  bool usePin = false;
  bool usePassword = false;
  bool usePattern = false;
  bool useBiometric = false;

  static const Color highlight = Color(0xFFCCFF00); // neon green

  // 🔐 Screenshot protection
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    pinCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────
  // SAVE (ONE LOGIC – UNTOUCHED)
  // ─────────────────────────
  void _save() async {
    final vaultMethods = <String>[];

    if (usePin) vaultMethods.add("pin");
    if (usePassword) vaultMethods.add("password");
    if (usePattern) vaultMethods.add("pattern");
    if (useBiometric) vaultMethods.add("biometric");

    if (vaultMethods.length < 2) {
      _err("Select at least 2 methods");
      return;
    }

    if (usePin && pinCtrl.text.length != 4) {
      _err("Invalid 4-digit PIN");
      return;
    }

    if (usePassword && passCtrl.text.length < 6) {
      _err("Password too short");
      return;
    }

    if (usePattern && pattern.length < 3) {
      _err("Invalid pattern");
      return;
    }

    widget.user
      ..vaultSetupComplete = true
      ..vaultAuthMethods = vaultMethods
      ..vaultPinHash = usePin ? hashValue(pinCtrl.text) : ""
      ..vaultPasswordHash = usePassword ? hashValue(passCtrl.text) : ""
      ..vaultPatternHash = usePattern ? hashValue(pattern.join()) : ""
      ..vaultBiometricEnabled = useBiometric;

    await widget.user.save();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VaultUnlockScreen(user: widget.user),
      ),
    );
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _switchTile({
    required bool value,
    required String title,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: highlight,
      title: Text(title, style: const TextStyle(color: Colors.white)),
    );
  }

  // ─────────────────────────
  // BUILD
  // ─────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Vault Setup"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            "Secure Your Vault",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Choose at least two authentication methods",
            style: TextStyle(color: Colors.white54),
          ),

          const SizedBox(height: 24),

          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _switchTile(
                  value: usePin,
                  title: "PIN",
                  onChanged: (v) => setState(() => usePin = v),
                ),
                if (usePin)
                  TextField(
                    controller: pinCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "4-Digit Vault PIN",
                    ),
                  ),
              ],
            ),
          ),

          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _switchTile(
                  value: usePassword,
                  title: "Password",
                  onChanged: (v) => setState(() => usePassword = v),
                ),
                if (usePassword)
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Vault Password",
                    ),
                  ),
              ],
            ),
          ),

          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _switchTile(
                  value: usePattern,
                  title: "Pattern",
                  onChanged: (v) => setState(() => usePattern = v),
                ),
                if (usePattern)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: PatternInputWidget(
                      onComplete: (p) => pattern = p,
                    ),
                  ),
              ],
            ),
          ),

          _card(
            child: _switchTile(
              value: useBiometric,
              title: "Biometric",
              onChanged: (v) => setState(() => useBiometric = v),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: highlight,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                "Save Vault Setup",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
