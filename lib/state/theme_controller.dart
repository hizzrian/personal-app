import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the light/dark preference.
///
/// Load happens in [load] before `runApp`, not in the constructor, so the app
/// never renders one frame in the wrong theme.
class ThemeController extends ChangeNotifier {
  ThemeController({bool isDarkMode = false}) : _isDarkMode = isDarkMode;

  static const _prefsKey = 'isDarkMode';

  bool _isDarkMode;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Reads the stored preference. Falls back to light mode if preferences are
  /// unavailable rather than failing app startup.
  static Future<ThemeController> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return ThemeController(isDarkMode: prefs.getBool(_prefsKey) ?? false);
    } catch (_) {
      return ThemeController();
    }
  }

  Future<void> toggle() => setDarkMode(!_isDarkMode);

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {
      // The in-memory toggle already applied; persistence is best-effort.
    }
  }
}
