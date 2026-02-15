import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../storage/hive_boxes.dart';
import '../../core/routes.dart';
import 'pattern_input_widget.dart';
import 'auth_hash.dart';

const Color cyberGreen = Color.fromARGB(255, 51, 243, 17);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final pinCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');

  List<int> pattern = [];

  bool usePin = false;
  bool usePassword = false;
  bool usePattern = false;
  bool useBiometric = false;

  // ─────────────────────────
  // REGISTER (LOGIC UNCHANGED)
  // ─────────────────────────
  Future<void> _register() async {
    final box = HiveBoxes.users;

    final fullName = nameCtrl.text.trim();
    final username = userCtrl.text.trim();

    if (fullName.split(RegExp(r'\s+')).length < 2) {
      _err("Enter full name (first & last)");
      return;
    }

    if (username.isEmpty) {
      _err("Username required");
      return;
    }

    if (box.values.any((u) => u.username == username)) {
      _err("Username already taken");
      return;
    }

    final enabledMethods = <String>[];
    if (usePin) enabledMethods.add("pin");
    if (usePassword) enabledMethods.add("password");
    if (usePattern) enabledMethods.add("pattern");
    if (useBiometric) enabledMethods.add("biometric");

    if (enabledMethods.length < 2) {
      _err("Select at least 2 authentication methods");
      return;
    }

    if (usePin) {
      if (pinCtrl.text.length != 4 || pinCtrl.text == "0000") {
        _err("Invalid PIN (0000 is reserved)");
        return;
      }
    }

    if (usePassword && !passwordRegex.hasMatch(passCtrl.text)) {
      _err("Password must be 8+ chars with letters & numbers");
      return;
    }

    if (usePattern && pattern.length < 3) {
      _err("Draw a valid pattern");
      return;
    }

    final user = UserModel(
      fullName: fullName,
      username: username,
      enabledAuthMethods: enabledMethods,
      pinHash: usePin ? hashValue(pinCtrl.text) : "",
      passwordHash: usePassword ? hashValue(passCtrl.text) : "",
      patternHash: usePattern ? hashValue(pattern.join()) : "",
      biometricEnabled: useBiometric,
    );

    await box.add(user);

    if (!mounted) return;

    if (usePin) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            "Security Notice",
            style: TextStyle(color: cyberGreen),
          ),
          content: const Text(
            "Emergency / Forced Unlock Mode:\n\n"
            "• Enter PIN: 0000\n"
            "• A decoy (dummy) screen will open\n"
            "• Intruder activity may be recorded\n\n"
            "Do NOT share this PIN.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "I Understand",
                style: TextStyle(color: cyberGreen),
              ),
            ),
          ],
        ),
      );
    }

    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
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
          const SizedBox(height: 24),
          const Text(
            "Create Account",
            style: TextStyle(
              color: cyberGreen,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),
          _field(
            label: "Full Name",
            hint: "e.g. Rahul Sharma",
            controller: nameCtrl,
          ),
          _field(
            label: "Username",
            hint: "Choose a unique username",
            controller: userCtrl,
          ),

          const SizedBox(height: 16),
          const Text(
            "Authentication Methods (Select at least 2)",
            style: TextStyle(color: Colors.white70),
          ),

          _toggle("PIN", usePin, (v) => setState(() => usePin = v)),
          _toggle("Password", usePassword, (v) => setState(() => usePassword = v)),
          _toggle("Pattern", usePattern, (v) => setState(() => usePattern = v)),
          _toggle("Biometric", useBiometric, (v) => setState(() => useBiometric = v)),

          const SizedBox(height: 16),

          if (usePin)
            _field(
              label: "4-Digit PIN",
              hint: "Enter a secure 4-digit PIN",
              controller: pinCtrl,
              isPin: true,
              hideCounter: true,
            ),

          if (usePassword)
            _field(
              label: "Password",
              hint: "Min 8 chars, letters & numbers",
              controller: passCtrl,
              isPassword: true,
            ),

          if (usePattern) ...[
            const SizedBox(height: 12),
            const Text(
              "Draw Pattern",
              style: TextStyle(color: Colors.white70),
            ),
            PatternInputWidget(onComplete: (p) => pattern = p),
          ],

          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cyberGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _register,
            child: const Text(
              "Create Account",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: cyberGreen,
      title: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPin = false,
    bool isPassword = false,
    bool hideCounter = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPin || isPassword,
        keyboardType: isPin ? TextInputType.number : TextInputType.text,
        maxLength: isPin ? 4 : null,
        buildCounter: hideCounter
            ? (_, {required currentLength, maxLength, required isFocused}) => null
            : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: cyberGreen),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: cyberGreen),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    userCtrl.dispose();
    pinCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }
}
