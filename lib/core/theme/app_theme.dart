import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_palettes.dart';

class AppTheme {
  static ThemeData createTheme({
    required PaletteConfig palette,
    required bool isDark,
    double borderRadius = 10.0,
  }) {
    final fontFamily = GoogleFonts.plusJakartaSans().fontFamily;

    final ColorScheme colorScheme = isDark
        ? ColorScheme.dark(
            primary: palette.primary,
            onPrimary: Colors.white,
            primaryContainer: palette.primary.withValues(alpha: 0.22),
            onPrimaryContainer: palette.primary,
            secondary: palette.secondary,
            onSecondary: Colors.white,
            secondaryContainer: palette.secondary.withValues(alpha: 0.22),
            surface: palette.surfaceDark,
            onSurface: const Color(0xFFF8FAFC),
            onSurfaceVariant: const Color(0xFFCBD5E1),
            error: const Color(0xFFEF4444),
            onError: Colors.white,
            outline: const Color(0xFF334155),
            outlineVariant: const Color(0xFF475569),
          )
        : ColorScheme.light(
            primary: palette.primary,
            onPrimary: Colors.white,
            primaryContainer: palette.primary.withValues(alpha: 0.12),
            onPrimaryContainer: palette.secondary,
            secondary: palette.secondary,
            onSecondary: Colors.white,
            secondaryContainer: palette.secondary.withValues(alpha: 0.12),
            surface: palette.surfaceLight,
            onSurface: const Color(0xFF0F172A),
            onSurfaceVariant: const Color(0xFF475569),
            error: const Color(0xFFDC2626),
            onError: Colors.white,
            outline: const Color(0xFFE2E8F0),
            outlineVariant: const Color(0xFFCBD5E1),
          );

    final roundedBorder = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? palette.backgroundDark : palette.backgroundLight,
      fontFamily: fontFamily,
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: roundedBorder.copyWith(
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: isDark ? 0.7 : 0.8),
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF161E2E) : const Color(0xFFF1F5F9),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          fontFamily: fontFamily,
        ),
        hintStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontFamily: fontFamily,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Color(0xFF059669), width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: roundedBorder,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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

  static ThemeData get lightTheme => createTheme(palette: AppPalettes.agriEmerald, isDark: false);
  static ThemeData get darkTheme => createTheme(palette: AppPalettes.agriEmerald, isDark: true);
}
