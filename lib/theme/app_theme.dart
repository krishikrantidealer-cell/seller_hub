import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Color Palette
  static const Color primary = Color(0xFF10B981); // Vibrant Emerald for dark & light visibility
  static const Color primaryDeep = Color(0xFF0F5132); // Deep Forest Emerald
  static const Color primaryDark = Color(0xFF064E3B);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color accent = Color(0xFF20C997);

  // Light Mode Colors
  static const Color lightSurfaceBg = Color(0xFFF8FAFC);
  static const Color lightCardBg = Colors.white;
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightInputBg = Colors.white;
  static const Color lightTabBg = Color(0xFFF1F5F9);
  static const Color lightAccentBg = Color(0xFFECFDF5);

  // Dark Mode Colors
  static const Color darkSurfaceBg = Color(0xFF0B1120); // Slate 950
  static const Color darkCardBg = Color(0xFF1E293B); // Slate 800
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkInputBg = Color(0xFF0F172A);
  static const Color darkTabBg = Color(0xFF0F172A);
  static const Color darkAccentBg = Color(0xFF064E3B);

  // General Colors
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryDeep, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error, width: 1.2),
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
            fontWeight: FontWeight.w600,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error, width: 1.2),
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
