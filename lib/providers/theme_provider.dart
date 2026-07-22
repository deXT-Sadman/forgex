import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// Powers the light/dark toggle IconButton in the Home AppBar.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> loadSavedTheme() async {
    final saved = await StorageService.instance.getThemeMode();
    _mode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await StorageService.instance.saveThemeMode(isDark ? 'dark' : 'light');
  }
}
