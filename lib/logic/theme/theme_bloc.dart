import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_palettes.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState.initial()) {
    on<InitTheme>(_onInitTheme);
    on<ToggleDarkMode>(_onToggleDarkMode);
    on<ChangePalette>(_onChangePalette);
    add(InitTheme());
  }

  Future<void> _onInitTheme(InitTheme event, Emitter<ThemeState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(AppConstants.prefThemeMode) ?? false;
      emit(state.copyWith(isDark: isDark));
    } catch (_) {}
  }

  Future<void> _onToggleDarkMode(ToggleDarkMode event, Emitter<ThemeState> emit) async {
    final nextDark = !event.currentIsDark;
    emit(state.copyWith(isDark: nextDark));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefThemeMode, nextDark);
    } catch (_) {}
  }

  void _onChangePalette(ChangePalette event, Emitter<ThemeState> emit) {
    final palette = AppPalettes.getById(event.paletteId);
    emit(state.copyWith(currentPalette: palette));
  }
}
