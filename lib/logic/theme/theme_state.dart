import 'package:equatable/equatable.dart';
import '../../core/theme/theme_palettes.dart';

class ThemeState extends Equatable {
  final bool isDark;
  final PaletteConfig currentPalette;
  final String brandName;

  const ThemeState({
    required this.isDark,
    required this.currentPalette,
    this.brandName = 'Seller Hub',
  });

  factory ThemeState.initial() {
    return const ThemeState(
      isDark: false,
      currentPalette: AppPalettes.agriEmerald,
      brandName: 'Seller Hub',
    );
  }

  ThemeState copyWith({
    bool? isDark,
    PaletteConfig? currentPalette,
    String? brandName,
  }) {
    return ThemeState(
      isDark: isDark ?? this.isDark,
      currentPalette: currentPalette ?? this.currentPalette,
      brandName: brandName ?? this.brandName,
    );
  }

  @override
  List<Object?> get props => [isDark, currentPalette, brandName];
}
