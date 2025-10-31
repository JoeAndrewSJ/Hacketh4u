import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/theme_repository.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeRepository _themeRepository;

  ThemeBloc({required ThemeRepository themeRepository})
      : _themeRepository = themeRepository,
        super(const ThemeState()) {
    on<ThemeStarted>(_onThemeStarted);
    on<ThemeToggled>(_onThemeToggled);
  }

  Future<void> _onThemeStarted(
      ThemeStarted event, Emitter<ThemeState> emit) async {
    final isDarkMode = await _themeRepository.isDarkMode();
    emit(state.copyWith(isDarkMode: isDarkMode));
  }

  Future<void> _onThemeToggled(
      ThemeToggled event, Emitter<ThemeState> emit) async {
    final newMode = !state.isDarkMode;
    await _themeRepository.setDarkMode(newMode);
    emit(state.copyWith(isDarkMode: newMode));
  }
}



