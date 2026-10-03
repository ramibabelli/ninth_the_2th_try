import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  static const String _localeKey = 'app_locale';

  final SharedPreferences _prefs;
  ThemeMode _themeMode;
  Locale _locale;

  ThemeController(this._prefs)
      : _themeMode = _loadThemeMode(_prefs),
        _locale = _loadLocale(_prefs);

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final value = prefs.getString(_themeKey);
    return switch (value) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  static Locale _loadLocale(SharedPreferences prefs) {
    final value = prefs.getString(_localeKey);
    return value == 'en' ? const Locale('en') : const Locale('ar');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    switch (mode) {
      case ThemeMode.light:
        await _prefs.setString(_themeKey, 'light');
      case ThemeMode.dark:
        await _prefs.setString(_themeKey, 'dark');
      case ThemeMode.system:
        await _prefs.remove(_themeKey);
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    if (locale.languageCode == 'en') {
      await _prefs.setString(_localeKey, 'en');
    } else {
      await _prefs.remove(_localeKey);
    }
    notifyListeners();
  }
}