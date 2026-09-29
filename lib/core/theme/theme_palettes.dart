import 'package:flutter/material.dart';

enum ThemePaletteId {
  agriEmerald,
  royalIndigo,
  oceanBlue,
}

class PaletteConfig {
  final ThemePaletteId id;
  final String name;
  final String description;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color backgroundLight;
  final Color surfaceLight;
  final Color backgroundDark;
  final Color surfaceDark;

  const PaletteConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.primary,
    required this.secondary,
    required this.accent,
    this.backgroundLight = const Color(0xFFF8FAFC),
    this.surfaceLight = Colors.white,
    this.backgroundDark = const Color(0xFF0A0F1D),
    this.surfaceDark = const Color(0xFF161E2E),
  });
}

class AppPalettes {
  static const PaletteConfig agriEmerald = PaletteConfig(
    id: ThemePaletteId.agriEmerald,
    name: 'Agri Emerald',
    description: 'Fresh agricultural greens & vibrant emerald shockwave',
    primary: Color(0xFF10B981),
    secondary: Color(0xFF059669),
    accent: Color(0xFFF59E0B),
  );

  static const List<PaletteConfig> all = [agriEmerald];

  static PaletteConfig getById(ThemePaletteId id) {
    return all.firstWhere((p) => p.id == id, orElse: () => agriEmerald);
  }
}
