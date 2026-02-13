import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> authenticate() async {
    // Check if hardware is available
    final bool canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();

    if (!canCheck) return false;

    try {
      return await auth.authenticate(
        localizedReason: 'Scan to Access CyberShield Vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }
}