import 'package:flutter/material.dart';

class MavoColors {
  static const navy = Color(0xFF101A39);
  static const blue = Color(0xFF286BFF);
  static const violet = Color(0xFF8057E8);
  static const background = Color(0xFFF5F7FC);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF697586);
  static const surface = Colors.white;
  static const blueSoft = Color(0xFFEAF0FF);
  static const violetSoft = Color(0xFFF0EBFF);
  static const success = Color(0xFF16865B);
  static const warning = Color(0xFFC47A13);
  static const danger = Color(0xFFC43D4B);

  // Temporary aliases for older screens during the staged redesign.
  static const midnight = navy;
  static const coral = Color(0xFFFF7A85);
  static const aqua = Color(0xFF27AFC2);
  static const gold = Color(0xFFD6B66C);
  static const coralSoft = Color(0xFFFFEEF0);
}

class YukuColors {
  static const navy = MavoColors.navy;
  static const blue = MavoColors.blue;
  static const violet = MavoColors.violet;
  static const background = MavoColors.background;
  static const ink = MavoColors.ink;
  static const muted = MavoColors.muted;
}

class YukuTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: MavoColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MavoColors.blue,
      primary: MavoColors.blue,
      secondary: MavoColors.violet,
      surface: MavoColors.surface,
      error: MavoColors.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: MavoColors.background,
      foregroundColor: MavoColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: MavoColors.blueSoft,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        color: states.contains(WidgetState.selected) ? MavoColors.blue : MavoColors.muted,
      )),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: MavoColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
