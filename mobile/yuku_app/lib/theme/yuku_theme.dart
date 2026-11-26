import 'package:flutter/material.dart';

class YukuColors {
  static const navy = Color(0xFF101A39);
  static const blue = Color(0xFF286BFF);
  static const violet = Color(0xFF8057E8);
  static const background = Color(0xFFF5F7FC);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF697586);
}

class YukuTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: YukuColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: YukuColors.blue,
      primary: YukuColors.blue,
      secondary: YukuColors.violet,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: YukuColors.background,
      foregroundColor: YukuColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
