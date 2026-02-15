import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyThemeMode = 'theme_mode';

/// 0 = system, 1 = light, 2 = dark
class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier() {
    _load();
  }

  int _mode = 0;

  bool get isDarkMode => themeMode == ThemeMode.dark;

  ThemeMode get themeMode {
    switch (_mode) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = prefs.getInt(_keyThemeMode) ?? 0;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final next = mode == ThemeMode.light ? 1 : (mode == ThemeMode.dark ? 2 : 0);
    if (_mode == next) return;
    _mode = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, next);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    await setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleDarkMode() async {
    await setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
}
