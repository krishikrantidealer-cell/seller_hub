import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Palette (Agri Emerald)
  static const Color primary = Color(0xFF10B981);
  static const Color secondary = Color(0xFF059669);
  static const Color accent = Color(0xFFF59E0B);

  // Background & Surface
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color backgroundDark = Color(0xFF0A0F1D);
  static const Color surfaceDark = Color(0xFF161E2E);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF334155);
  static const Color textMutedLight = Color(0xFF64748B);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFE2E8F0);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // Borders
  static const Color outlineLight = Color(0xFFE2E8F0);
  static const Color outlineDark = Color(0xFF334155);

  static ThemeData createTheme({required bool isDark}) {
    final fontFamily = GoogleFonts.plusJakartaSans().fontFamily;
    final mutedTextColor = isDark ? textMutedDark : textMutedLight;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark ? backgroundDark : backgroundLight,
      fontFamily: fontFamily,
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: primary,
              secondary: secondary,
              surface: surfaceDark,
              error: Color(0xFFEF4444),
            )
          : const ColorScheme.light(
              primary: secondary,
              secondary: primary,
              surface: surfaceLight,
              error: Color(0xFFDC2626),
            ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF161E2E) : const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFF059669), width: 1.6),
        ),
        hintStyle: TextStyle(
          color: mutedTextColor,
          fontSize: 13,
          fontFamily: fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            fontFamily: fontFamily,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => createTheme(isDark: false);
  static ThemeData get darkTheme => createTheme(isDark: true);
}
