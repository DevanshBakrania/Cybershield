class Validators {
  static bool isValidPin(String pin) {
    return pin.length == 4 && int.tryParse(pin) != null;
  }

  static bool isStrongPassword(String pass) {
    return pass.length > 8; // Add regex for symbols/numbers here
  }
}