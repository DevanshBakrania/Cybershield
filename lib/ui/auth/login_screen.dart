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
  // LOAD USER
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

      _msg("User located. Awaiting authentication.", neon);
      setState(() {});
    } catch (_) {
      _user = null;
      _msg("User not found in local registry.", Colors.red);
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
        case "fingerprint":
        case "face_lock":
        case "biometric": // Keeping legacy biometric just in case old users exist
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
      _msg("Draw a valid pattern to proceed.", Colors.orange);
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

    _msg("Authentication 1/2 verified. Proceed to next step.", neon);
    setState(() {});
  }

  Future<void> _onFail() async {
    if (_user == null) return;

    attempts++;

    if (attempts >= 2) {
      IntruderTrapService.capture(_user!.username);

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.dummy,
        arguments: _user!.username,
      );
    } else {
      _msg("Access Denied (1 attempt remaining before lockdown)", Colors.red);
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
        shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(12)
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Emergency Override", style: TextStyle(color: Colors.red)),
          ],
        ),
        content: TextField(
          controller: panicCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter Override PIN",
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Abort", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (panicCtrl.text == "0000") {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.dummy,
                  arguments: _user!.username,
                );
              } else {
                _msg("Override Failed.", Colors.red);
              }
            },
            child: const Text("Execute", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _msg(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  // ─────────────────────────
  // UI
  // ─────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: neon),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security, color: neon, size: 60),
              const SizedBox(height: 16),
              const Text(
                "CYBERSHIELD",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: neon,
                  fontSize: 28,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Secure Node Login",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, letterSpacing: 1.5),
              ),
              const SizedBox(height: 48),

              // BEFORE USER LOAD
              if (_user == null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      _input("Vault Username", userCtrl, icon: Icons.person_outline),
                      const SizedBox(height: 24),
                      _primaryBtn("Initiate Handshake", _loadUser),
                    ],
                  ),
                ),
              ],

              // AFTER USER LOAD
              if (_user != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Target: ${_user!.username}",
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Security Level: ${verified.length} / 2",
                          style: const TextStyle(color: neon, fontSize: 14),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                      tooltip: "Emergency Access",
                      onPressed: _showPanicDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // PROGRESSIVE AUTHENTICATION RENDERER
                _renderCurrentAuthStep(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────
  // METHOD UI - PROGRESSIVE
  // ─────────────────────────
  Widget _renderCurrentAuthStep() {
    // Only fetch the remaining unverified methods
    final pendingMethods = _user!.enabledAuthMethods.where((m) => !verified.contains(m)).toList();

    // If somehow we have no pending methods but haven't routed to dashboard yet
    if (pendingMethods.isEmpty) return const Center(child: CircularProgressIndicator(color: neon));

    // Only render the VERY FIRST unverified method in the list
    final currentMethod = pendingMethods.first;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
          child: child,
        ));
      },
      child: _buildMethodWidget(currentMethod, key: ValueKey(currentMethod)),
    );
  }

  Widget _buildMethodWidget(String method, {Key? key}) {
    switch (method) {
      case "pin":
        return _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Enter 4-Digit PIN", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              _input("PIN", pinCtrl, obscure: true, isNumber: true, icon: Icons.dialpad),
              const SizedBox(height: 16),
              _primaryBtn("Verify Credentials", () => _verify("pin")),
            ],
          ),
          key: key,
        );

      case "password":
        return _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Enter Master Password", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              _input("Password", passCtrl, obscure: true, icon: Icons.password),
              const SizedBox(height: 16),
              _primaryBtn("Verify Credentials", () => _verify("password")),
            ],
          ),
          key: key,
        );

      case "pattern":
        return _card(
          Column(
            children: [
              const Text("Draw Security Pattern", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              SizedBox(
                height: 300, // Constrain the height so it doesn't warp
                width: 300,
                child: PatternInputWidget(onComplete: _onPattern),
              ),
              const SizedBox(height: 24),
              _primaryBtn("Verify Pattern", _verifyPattern),
            ],
          ),
          key: key,
        );

      case "fingerprint":
        return _card(
          Column(
            children: [
              const Icon(Icons.fingerprint, color: neon, size: 64),
              const SizedBox(height: 16),
              const Text("Biometric Scan Required", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              _primaryBtn("Initiate Fingerprint Scan", () => _verify("fingerprint")),
            ],
          ),
          key: key,
        );

      case "face_lock":
        return _card(
          Column(
            children: [
              const Icon(Icons.face, color: neon, size: 64),
              const SizedBox(height: 16),
              const Text("Facial Recognition Required", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              _primaryBtn("Initiate Face Scan", () => _verify("face_lock")),
            ],
          ),
          key: key,
        );

      case "biometric": // Legacy fallback
        return _card(
          Column(
            children: [
              const Icon(Icons.fingerprint, color: neon, size: 64),
              const SizedBox(height: 16),
              const Text("Biometric Scan Required", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              _primaryBtn("Initiate Biometric Scan", () => _verify("biometric")),
            ],
          ),
          key: key,
        );

      default:
        return const SizedBox();
    }
  }

  Widget _card(Widget child, {Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: neon.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: neon.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 2),
          ]
      ),
      child: child,
    );
  }

  Widget _input(String label, TextEditingController c, {bool obscure = false, bool isNumber = false, IconData? icon}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, letterSpacing: 0),
        prefixIcon: icon != null ? Icon(icon, color: neon) : null,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.5),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: neon, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _primaryBtn(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: neon,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
          shadowColor: neon.withValues(alpha: 0.4),
        ),
        onPressed: onTap,
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ),
    );
  }
}