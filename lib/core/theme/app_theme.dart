import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF0BA360);
  static const accent = Color(0xFF3CBA92);
  static const surface = Color(0xFFF5F7FB);

  static final light = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
    ),
    scaffoldBackgroundColor: surface,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF4F6FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
      ),
    ),
    useMaterial3: true,
  );
}
