class Gatekeeper {
  // In a real app, these would be hashed and stored in SecureStorage
  static const String _adminPin = "1234";
  static const String _panicPin = "0000";

  /// Returns true if the PIN grants access to the Vault
  bool verifyAdmin(String input) {
    return input == _adminPin;
  }

  /// Returns true if the PIN should trigger the Decoy/Dummy Mode
  bool isPanic(String input) {
    return input == _panicPin;
  }
}