import 'package:flutter/material.dart';

class MavoColors {
  // MAVO's core identity: confident blue, clean white, restrained orange.
  static const midnight = Color(0xFF172B4D);
  static const violet = Color(0xFF2563D9); // Legacy name; now the primary MAVO blue.
  static const coral = Color(0xFFF28A36); // Legacy name; now the orange accent.
  static const aqua = Color(0xFF238A9B);
  static const gold = Color(0xFFE6A23C);
  static const background = Color(0xFFF5F8FC);
  static const ink = Color(0xFF1B2A41);
  static const muted = Color(0xFF718096);
  static const surface = Colors.white;
  static const violetSoft = Color(0xFFEAF2FF); // Soft blue surface.
  static const coralSoft = Color(0xFFFFF3E8); // Soft orange surface.
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
