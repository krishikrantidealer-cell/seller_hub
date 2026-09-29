import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Color Palette
  static const Color primary = Color(0xFF10B981); // Bright Emerald for Dark Mode & Highlights
  static const Color primaryDeep = Color(0xFF0F5132); // Deep Forest Emerald for Light Mode
  static const Color primaryDark = Color(0xFF064E3B);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color accent = Color(0xFF059669);

  // High-Contrast Light Mode Colors
  static const Color lightSurfaceBg = Color(0xFFF1F5F9); // Crisp Slate 100
  static const Color lightCardBg = Colors.white;
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900 (Ultra Sharp)
  static const Color lightTextSecondary = Color(0xFF334155); // Slate 700 (High Legibility)
  static const Color lightTextMuted = Color(0xFF64748B); // Slate 500
  static const Color lightBorder = Color(0xFFCBD5E1); // Slate 300 (Clear Visible Border)
  static const Color lightInputBg = Color(0xFFFFFFFF);
  static const Color lightTabBg = Color(0xFFE2E8F0);
  static const Color lightAccentBg = Color(0xFFE6F4EA);

  // High-Contrast Dark Mode Colors
  static const Color darkSurfaceBg = Color(0xFF0A0F1D); // Deep Navy/Slate
  static const Color darkCardBg = Color(0xFF161F30); // Slate 850
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Pure White (Ultra Crisp)
  static const Color darkTextSecondary = Color(0xFFCBD5E1); // Slate 300 (High Legibility)
  static const Color darkTextMuted = Color(0xFF94A3B8); // Slate 400
  static const Color darkBorder = Color(0xFF334155); // Slate 700
  static const Color darkInputBg = Color(0xFF0B1323);
  static const Color darkTabBg = Color(0xFF0B1323);
  static const Color darkAccentBg = Color(0xFF064E3B);

  // Status Colors
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);

  static ThemeData get lightTheme {
    final fontFamily = GoogleFonts.plusJakartaSans().fontFamily;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightSurfaceBg,
      cardColor: lightCardBg,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.light(
        primary: primaryDeep,
        secondary: accent,
        surface: lightCardBg,
        error: error,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightBorder, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightBorder, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryDeep, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error, width: 1.4),
        ),
        hintStyle: TextStyle(
          color: lightTextMuted,
          fontSize: 14,
          fontFamily: fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: fontFamily,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final fontFamily = GoogleFonts.plusJakartaSans().fontFamily;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkSurfaceBg,
      cardColor: darkCardBg,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: darkCardBg,
        error: error,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error, width: 1.4),
        ),
        hintStyle: TextStyle(
          color: darkTextMuted,
          fontSize: 14,
          fontFamily: fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: fontFamily,
          ),
        ),
      ),
    );
  }
}
