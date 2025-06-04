import 'package:flutter/material.dart';

ThemeData dark_theme(BuildContext context) {
  return ThemeData(
    primaryColor: Colors.black54,
    colorScheme: ColorScheme.dark(
      primary: Colors.white70, // колір тексту кнопок
      onPrimary: Colors.white70,
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
