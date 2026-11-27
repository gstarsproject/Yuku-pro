import 'package:flutter/material.dart';

class MavoColors {
  static const midnight = Color(0xFF17152C);
  static const violet = Color(0xFF7557FF);
  static const coral = Color(0xFFFF5C7A);
  static const aqua = Color(0xFF27C7D9);
  static const gold = Color(0xFFD6B66C);
  static const background = Color(0xFFF5F6FA);
  static const ink = Color(0xFF211D36);
  static const muted = Color(0xFF777487);
  static const surface = Colors.white;
  static const violetSoft = Color(0xFFF0ECFF);
  static const coralSoft = Color(0xFFFFEEF2);
}

class MAVOColors {
  // Compatibility aliases while the remaining screens are migrated to MAVO.
  static const navy = MavoColors.midnight;
  static const blue = MavoColors.violet;
  static const violet = MavoColors.violet;
  static const background = MavoColors.background;
  static const ink = MavoColors.ink;
  static const muted = MavoColors.muted;
}

class MAVOTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: MavoColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MavoColors.violet,
      primary: MavoColors.violet,
      secondary: MavoColors.coral,
      surface: MavoColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: MavoColors.background,
      foregroundColor: MavoColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: MavoColors.violetSoft,
      labelTextStyle: WidgetStateProperty.resolveWith((states) =>
        TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? MavoColors.violet : MavoColors.muted,
        ),
      ),
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
