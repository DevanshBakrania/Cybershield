import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/routes.dart';
import '../../services/biometric_service.dart';
import '../../utils/secure_screen.dart';
import '../auth/auth_hash.dart';
import '../auth/pattern_input_widget.dart';
import 'vault_screen.dart';

class VaultUnlockScreen extends StatefulWidget {
  final UserModel user;
  
  const VaultUnlockScreen({super.key, required this.user});

  @override
  State<VaultUnlockScreen> createState() => _VaultUnlockScreenState();
}

class _VaultUnlockScreenState extends State<VaultUnlockScreen> {
  final pinCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final bio = BiometricService();

  int attempts = 0;
  final verified = <String>{};
  List<int> _pendingPattern = [];

  static const Color highlight = Color(0xFFCCFF00); // neon / lime green

  // 🔐 SCREENSHOT PROTECTION
  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
  }

  @override
  void dispose() {
    pinCtrl.dispose();
    passCtrl.dispose();
    SecureScreen.disable();
    super.dispose();
  }

  // ─────────────────────────
  // VERIFY METHODS (UNCHANGED)
  // ─────────────────────────
  Future<void> _verify(String method) async {
    bool ok = false;

    try {
      switch (method) {
        case "pin":
          ok = hashValue(pinCtrl.text) == widget.user.vaultPinHash;
          break;
        case "password":
          ok = hashValue(passCtrl.text) ==
              widget.user.vaultPasswordHash;
          break;
        case "biometric":
          ok = await bio.authenticate();
          break;
      }
    } catch (_) {
      _msg("Authentication error", Colors.red);
      return;
    }

    ok ? _success(method) : _fail();
  }

  void _onPattern(List<int> p) {
    _pendingPattern = p;
  }

  void _verifyPattern() {
    if (_pendingPattern.length < 3) {
      _msg("Draw pattern first", Colors.orange);
      return;
    }

    if (hashValue(_pendingPattern.join()) ==
        widget.user.vaultPatternHash) {
      _pendingPattern.clear();
      _success("pattern");
    } else {
      _pendingPattern.clear();
      _fail();
    }
  }

  // ─────────────────────────
  // SUCCESS / FAIL (UNCHANGED)
  // ─────────────────────────
  void _success(String m) {
    verified.add(m);
    attempts = 0;
    pinCtrl.clear();
    passCtrl.clear();

    if (verified.length >= 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VaultScreen(user: widget.user),
        ),
      );
      return;
    }
    setState(() {});
  }

  void _fail() {
    attempts++;
    if (attempts >= 2) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.dummy,
        arguments: widget.user.username,
      );
    } else {
      _msg("Invalid authentication", Colors.red);
    }
  }

  void _msg(String m, Color c) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  // ─────────────────────────
  // UI HELPERS (UNCHANGED)
  // ─────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _btn(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: highlight,
        ),
        child: Text(text),
      ),
    );
  }

  Widget _progress() {
    return Row(
      children: List.generate(
        2,
        (i) => Expanded(
          child: Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: verified.length > i
                  ? highlight
                  : Colors.white12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────
  // BUILD
  // ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final methods = widget.user.vaultAuthMethods
        .where((m) => !verified.contains(m))
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              "Unlock Vault",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _progress(),
            const SizedBox(height: 24),

            for (final m in methods)
              if (m == "pin")
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("PIN",
                          style: TextStyle(color: Colors.white70)),
                      TextField(
                        controller: pinCtrl,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Vault PIN",
                        ),
                      ),
                      const SizedBox(height: 12),
                      _btn("Verify PIN", () => _verify("pin")),
                    ],
                  ),
                )
              else if (m == "password")
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Password",
                          style: TextStyle(color: Colors.white70)),
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Vault Password",
                        ),
                      ),
                      const SizedBox(height: 12),
                      _btn("Verify Password",
                          () => _verify("password")),
                    ],
                  ),
                )
              else if (m == "pattern")
                _card(
                  child: Column(
                    children: [
                      PatternInputWidget(onComplete: _onPattern),
                      const SizedBox(height: 8),
                      _btn("Verify Pattern", _verifyPattern),
                    ],
                  ),
                )
              else if (m == "biometric")
                _card(
                  child: _btn(
                    "Use Biometric",
                    () => _verify("biometric"),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
