import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

ThemeData dark_theme(BuildContext context) {
  return ThemeData(
    primaryColor: Colors.black54,
    colorScheme: ColorScheme.dark(
      primary: Colors.white70, // колір тексту кнопок
      onPrimary: Colors.white70,
      secondary: Colors.black,
      error: Colors.deepOrange.shade900, // колір помилок
      onError: Colors.deepOrange.shade900,
      surface: Colors.grey.shade900, // задній фон
      onSurface:
          Colors.white70, // колір тексту на фоні (appbar, text in textfield)
      outline: Colors.brown.shade300, // колір обведення textfield
      surfaceContainerHighest: Colors.red,
      shadow: Colors.white70,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(fontSize: 15, color: Colors.white70),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.white70),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),
    appBarTheme: AppBarTheme(
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 25,
        color: Colors.white70,
      ),
    ),
    useMaterial3: true,
  );
}

ThemeData white_theme(BuildContext context) {
  return ThemeData(
    primaryColor: Colors.white54,
    colorScheme: ColorScheme.light(
      primary: Colors.black87, // колір тексту кнопок
      onPrimary: Colors.black87,
      secondary: Colors.white,
      error: Colors.red, // колір помилок
      onError: Colors.red,
      surface: Colors.grey.shade300, // задній фон
      onSurface:
          Colors.black87, // колір тексту на фоні (appbar, text in textfield)
      outline: Colors.brown.shade700, // колір обведення textfield
      surfaceContainerHighest: Colors.red,
      shadow: Colors.black87,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(fontSize: 15, color: Colors.black87),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.black87),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),
    appBarTheme: AppBarTheme(
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 25,
        color: Colors.black87,
      ),
      backgroundColor: Colors.white,
    ),
    useMaterial3: true,
  );
}

enum AppThemeMode { system, light, dark }

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themeModePrefKey = 'themeMode';

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  bool isCurrentlyDark(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(_themeModePrefKey);

    if (themeModeIndex != null &&
        themeModeIndex >= 0 &&
        themeModeIndex < AppThemeMode.values.length) {
      _themeMode = AppThemeMode.values[themeModeIndex].toMaterialThemeMode();
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModePrefKey, _themeMode.toAppThemeMode().index);
  }
}

extension ThemeModeConverter on ThemeMode {
  AppThemeMode toAppThemeMode() {
    switch (this) {
      case ThemeMode.light:
        return AppThemeMode.light;
      case ThemeMode.dark:
        return AppThemeMode.dark;
      case ThemeMode.system:
        return AppThemeMode.system;
    }
  }
}

extension AppThemeModeConverter on AppThemeMode {
  ThemeMode toMaterialThemeMode() {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
