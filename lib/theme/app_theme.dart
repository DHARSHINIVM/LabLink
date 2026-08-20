import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF0D4F43);
  static const Color secondary = Color(0xFF176B5B);
  static const Color background = Color(0xFFF7FAF9);
  static const Color text = Color(0xFF16332E);
  static const Color mutedText = Color(0xFF687773);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      fontFamily: 'Arial',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: text,
      ),
    );
  }
}