import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../storage/hive_boxes.dart';
import '../../core/routes.dart';
import '../../services/biometric_service.dart';
import '../../services/intruder_capture_service.dart';
import 'pattern_input_widget.dart';
import 'auth_hash.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ─────────────────────────
  // CONTROLLERS
  // ─────────────────────────
  final userCtrl = TextEditingController();
  final pinCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final BiometricService bio = BiometricService();

  UserModel? _user;

  int attempts = 0;
  final Set<String> verified = {};
  List<int> _pendingPattern = [];

  static const Color neon = Color(0xFFCCFF00);

  // ─────────────────────────
  // LOAD USER (NO AUTO BIOMETRIC)
  // ─────────────────────────
  Future<void> _loadUser() async {
    try {
      final found = HiveBoxes.users.values.firstWhere(
        (u) => u.username == userCtrl.text.trim(),
      );

      _user = found;

      verified.clear();
      attempts = 0;
      pinCtrl.clear();
      passCtrl.clear();
      _pendingPattern.clear();

      await IntruderTrapService.init(found.username);

      _msg("Choose authentication method", neon);
      setState(() {});
    } catch (_) {
      _user = null;
      _msg("User not found", Colors.red);
      setState(() {});
    }
  }

  // ─────────────────────────
  // VERIFY METHODS
  // ─────────────────────────
  Future<void> _verify(String method) async {
    if (_user == null) return;

    bool success = false;

    try {
      switch (method) {
        case "pin":
          success = hashValue(pinCtrl.text) == _user!.pinHash;
          break;
        case "password":
          success = hashValue(passCtrl.text) == _user!.passwordHash;
          break;
        case "biometric":
          success = await bio.authenticate();
          break;
      }
    } catch (_) {
      _msg("Authentication error", Colors.red);
      return;
    }

    success ? _onSuccess(method) : _onFail();
  }

  // ─────────────────────────
  // PATTERN
  // ─────────────────────────
  void _onPattern(List<int> p) {
    _pendingPattern = p;
  }

  void _verifyPattern() {
    if (_user == null) return;

    if (_pendingPattern.length < 3) {
      _msg("Draw pattern first", Colors.orange);
      return;
    }

    final inputHash = hashValue(_pendingPattern.join());

    if (inputHash == _user!.patternHash) {
      _pendingPattern.clear();
      _onSuccess("pattern");
    } else {
      _pendingPattern.clear();
      _onFail();
    }
  }

  // ─────────────────────────
  // SUCCESS / FAIL
  // ─────────────────────────
  void _onSuccess(String method) {
    verified.add(method);

    attempts = 0;
    pinCtrl.clear();
    passCtrl.clear();

    if (verified.length >= 2) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.dashboard,
        arguments: _user!.username,
      );
      return;
    }

    _msg("1 verified. Choose next method.", neon);
    setState(() {});
  }

  Future<void> _onFail() async {
    attempts++;

    if (_user != null) {
      await IntruderTrapService.capture(_user!.username);
    }

    if (attempts >= 2) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.dummy,
        arguments: _user?.username,
      );
    } else {
      _msg("Invalid authentication", Colors.red);
    }
  }

  // ─────────────────────────
  // PANIC PIN
  // ─────────────────────────
  void _showPanicDialog() {
    if (_user == null) return;

    final panicCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "Emergency Access",
          style: TextStyle(color: neon),
        ),
        content: TextField(
          controller: panicCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter Panic PIN",
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: neon)),
            focusedBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: neon)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (panicCtrl.text == "0000") {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.dummy,
                  arguments: _user!.username,
                );
              } else {
                _msg("Invalid Panic PIN", Colors.red);
              }
            },
            child: const Text("Confirm", style: TextStyle(color: neon)),
          ),
        ],
      ),
    );
  }

  void _msg(String m, Color c) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  // ─────────────────────────
  // UI
  // ─────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 32),

          const Text(
            "CyberShield",
            style: TextStyle(
              color: neon,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),
          const Text("Secure Login", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 32),

          // BEFORE USER LOAD
          if (_user == null) ...[
            _input("Username", userCtrl),
            const SizedBox(height: 12),
            _primaryBtn("Continue", _loadUser),
          ],

          // AFTER USER LOAD
          if (_user != null) ...[
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.warning_amber_rounded, color: neon),
                tooltip: "Emergency Access",
                onPressed: _showPanicDialog,
              ),
            ),

            Text(
              "Welcome, ${_user!.fullName}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),
            Text(
              "Authentication ${verified.length} / 2",
              style: const TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 24),
            ..._methodWidgets(),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────
  // METHOD UI
  // ─────────────────────────
  List<Widget> _methodWidgets() {
    final methods = _user!.enabledAuthMethods
        .where((m) => !verified.contains(m))
        .toList();

    return methods.map((m) {
      switch (m) {
        case "pin":
          return _card(
            Column(
              children: [
                _input("PIN", pinCtrl, obscure: true),
                _primaryBtn("Verify PIN", () => _verify("pin")),
              ],
            ),
          );

        case "password":
          return _card(
            Column(
              children: [
                _input("Password", passCtrl, obscure: true),
                _primaryBtn("Verify Password", () => _verify("password")),
              ],
            ),
          );

        case "pattern":
          return _card(
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: SizedBox.expand(
                      child: PatternInputWidget(onComplete: _onPattern),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _primaryBtn("Verify Pattern", _verifyPattern),
              ],
            ),
          );

        case "biometric":
          return _card(
            _primaryBtn("Use Biometric", () => _verify("biometric")),
          );

        default:
          return const SizedBox();
      }
    }).toList();
  }

  Widget _card(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: neon),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _input(String label, TextEditingController c,
      {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder:
              UnderlineInputBorder(borderSide: BorderSide(color: neon)),
          focusedBorder:
              UnderlineInputBorder(borderSide: BorderSide(color: neon)),
        ),
      ),
    );
  }

  Widget _primaryBtn(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: neon,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
