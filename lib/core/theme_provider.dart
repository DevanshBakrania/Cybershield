import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ✅ This file now ONLY handles logic. No Colors. No CyberTheme class.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;

    // Save preference
    var box = Hive.box('settings');
    box.put('darkMode', isOn);

    notifyListeners();
  }

  void _loadTheme() {
    // Safety check in case box isn't open (avoids crashes)
    if (Hive.isBoxOpen('settings')) {
      var box = Hive.box('settings');
      bool isDark = box.get('darkMode', defaultValue: true);
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }
}