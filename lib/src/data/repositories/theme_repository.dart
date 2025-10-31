import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class ThemeRepository {
  final SharedPreferences _sharedPreferences;

  ThemeRepository(this._sharedPreferences);

  Future<bool> isDarkMode() async {
    return _sharedPreferences.getBool(AppConstants.isDarkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    await _sharedPreferences.setBool(AppConstants.isDarkModeKey, isDarkMode);
  }
}



