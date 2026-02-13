import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CyberTheme {
  // 🎨 Core Color Palette
  static const Color background = Color(0xFF0F0F0F); // Deep Matte Black
  static const Color surface = Color(0xFF1C1C1E);    // Dark Charcoal
  static const Color neonGreen = Color(0xFFCCFF00);  // High-Voltage Neon
  static const Color dangerRed = Color(0xFFFF3B30);  // Critical Alerts
  static const Color textWhite = Color(0xFFFFFFFF);  // Primary Text
  static const Color textGrey = Color(0xFF8E8E93);   // Subtitles

  // 🧬 The Master Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: neonGreen,

      // 1. Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: textWhite),
        headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: textWhite),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: textWhite),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: textGrey),
      ),

      // REMOVED cardTheme to fix the error in your screenshot

      // 2. Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: textGrey.withValues(alpha: 0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: neonGreen, width: 1.5)),
      ),

      // 3. Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: neonGreen,
        secondary: neonGreen,
        surface: surface,
        error: dangerRed,
        onPrimary: Colors.black,
      ),
    );
  }
}