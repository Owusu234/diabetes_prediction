import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to 'light' if no theme is saved
    final String theme = prefs.getString('themeMode') ?? 'light';
    
    if (theme == 'light') _themeMode = ThemeMode.light;
    else if (theme == 'dark') _themeMode = ThemeMode.dark;
    else if (theme == 'system') _themeMode = ThemeMode.system;
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) await prefs.setString('themeMode', 'light');
    else if (mode == ThemeMode.dark) await prefs.setString('themeMode', 'dark');
    else if (mode == ThemeMode.system) await prefs.setString('themeMode', 'system');
  }
}
