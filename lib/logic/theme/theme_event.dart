import 'package:equatable/equatable.dart';
import '../../core/theme/theme_palettes.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class InitTheme extends ThemeEvent {}

class ToggleDarkMode extends ThemeEvent {
  final bool currentIsDark;
  const ToggleDarkMode(this.currentIsDark);

  @override
  List<Object?> get props => [currentIsDark];
}

class ChangePalette extends ThemeEvent {
  final ThemePaletteId paletteId;
  const ChangePalette(this.paletteId);

  @override
  List<Object?> get props => [paletteId];
}
