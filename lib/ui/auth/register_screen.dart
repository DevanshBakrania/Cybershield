import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../storage/hive_boxes.dart';
import '../../core/routes.dart';
import 'pattern_input_widget.dart';
import 'auth_hash.dart';

const Color cyberGreen = Color(0xFFCCFF00);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Stepper state
  int _currentStep = 0;

  final nameCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final pinCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');

  List<int> pattern = [];

  bool usePin = false;
  bool usePassword = false;
  bool usePattern = false;

  // Splitting Biometrics into two distinct options
  bool useFingerprint = false;
  bool useFaceLock = false;

  // ─────────────────────────
  // REGISTER (UPDATED FOR FACE & FINGERPRINT)
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
    if (useFingerprint) enabledMethods.add("fingerprint");
    if (useFaceLock) enabledMethods.add("face_lock");

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
      // Passing true if either is selected so your existing model doesn't break
      biometricEnabled: useFingerprint || useFaceLock,
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
      appBar: AppBar(
        title: const Text('CREATE ACCOUNT', style: TextStyle(color: cyberGreen, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: cyberGreen),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: cyberGreen,
            surface: Colors.black,
          ),
        ),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 0) {
              setState(() => _currentStep += 1);
            } else if (_currentStep == 1) {
              setState(() => _currentStep += 1);
            } else {
              _register();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            } else {
              Navigator.pop(context);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cyberGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: details.onStepContinue,
                      child: Text(
                        _currentStep == 2 ? 'Create Account' : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cyberGreen,
                          side: const BorderSide(color: cyberGreen),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: details.onStepCancel,
                        child: const Text('Back', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Profile Info', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              content: Column(
                children: [
                  _field(label: "Full Name", hint: "e.g. Rahul Sharma", controller: nameCtrl),
                  _field(label: "Username", hint: "Choose a unique username", controller: userCtrl),
                ],
              ),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Choose Security Arsenal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select at least 2 methods to secure your vault:", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      _methodCard("PIN", Icons.pin, usePin, (v) => setState(() => usePin = v)),
                      _methodCard("Password", Icons.password, usePassword, (v) => setState(() => usePassword = v)),
                      _methodCard("Pattern", Icons.grid_on, usePattern, (v) => setState(() => usePattern = v)),
                      _methodCard("Fingerprint", Icons.fingerprint, useFingerprint, (v) => setState(() => useFingerprint = v)),
                      _methodCard("Face Lock", Icons.face, useFaceLock, (v) => setState(() => useFaceLock = v)),
                    ],
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Configure Methods', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              content: Column(
                children: [
                  if (!usePin && !usePassword && !usePattern && !useFingerprint && !useFaceLock)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Please go back and select at least 2 methods.", style: TextStyle(color: Colors.redAccent)),
                    ),
                  if (usePin) _field(label: "4-Digit PIN", hint: "Enter a secure 4-digit PIN", controller: pinCtrl, isPin: true, hideCounter: true),
                  if (usePassword) _field(label: "Password", hint: "Min 8 chars, letters & numbers", controller: passCtrl, isPassword: true),
                  if (usePattern) ...[
                    const SizedBox(height: 16),
                    const Text("Draw Unlock Pattern", style: TextStyle(color: cyberGreen, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    PatternInputWidget(onComplete: (p) => pattern = p),
                  ],
                  if (useFaceLock) ...[
                    const SizedBox(height: 16),
                    const Text("Face Lock Setup will be handled by the device.", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                  ],
                  if (useFingerprint) ...[
                    const SizedBox(height: 8),
                    const Text("Fingerprint Setup will be handled by the device.", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                  ]
                ],
              ),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────
  // UI HELPERS
  // ─────────────────────────

  Widget _methodCard(String title, IconData icon, bool isSelected, ValueChanged<bool> onTap) {
    return GestureDetector(
      onTap: () => onTap(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? cyberGreen.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
              color: isSelected ? cyberGreen : Colors.white24,
              width: isSelected ? 2 : 1
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? cyberGreen : Colors.white54, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: isSelected ? cyberGreen : Colors.white54, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
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