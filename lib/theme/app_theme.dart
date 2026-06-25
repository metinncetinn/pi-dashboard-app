import 'package:flutter/material.dart';

class AppTheme {
  // Karanlık tema renkleri
  static const Color accent    = Color(0xFFC8FF00); // neon chartreuse
  static const Color accent2   = Color(0xFF00D4FF);
  static const Color bgDark    = Color(0xFF0A0A0A);
  static const Color surfDark  = Color(0xFF111111);
  static const Color surf2Dark = Color(0xFF181818);
  static const Color borderDark= Color(0xFF222222);
  static const Color textDark  = Color(0xFFE8E8E8);
  static const Color mutedDark = Color(0xFF555555);
  static const Color green     = Color(0xFF00E676);
  static const Color red       = Color(0xFFFF4444);

  // Aydınlık tema renkleri
  static const Color accentLight  = Color(0xFF2D7DD2); // okunabilir mavi
  static const Color bgLight      = Color(0xFFF2F2F7);
  static const Color surfLight    = Color(0xFFFFFFFF);
  static const Color surf2Light   = Color(0xFFE8E8ED);
  static const Color borderLight  = Color(0xFFD1D1D6);
  static const Color textLight    = Color(0xFF1C1C1E);
  static const Color mutedLight   = Color(0xFF8E8E93);

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary:   accent,
        secondary: accent2,
        surface:   surfDark,
        error:     red,
        onPrimary: Colors.black,
        onSurface: textDark,
      ),
      fontFamily: 'JetBrainsMono',
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgDark,
        indicatorColor: accent.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: accent, fontSize: 10);
          }
          return const TextStyle(color: mutedDark, fontSize: 10);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: accent);
          }
          return const IconThemeData(color: mutedDark);
        }),
      ),
      cardTheme: const CardThemeData(
        color: surfDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: borderDark),
        ),
      ),
      dividerColor: borderDark,
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary:   accentLight,
        secondary: Color(0xFF0099CC),
        surface:   surfLight,
        error:     red,
        onPrimary: Colors.white,
        onSurface: textLight,
      ),
      fontFamily: 'JetBrainsMono',
      appBarTheme: const AppBarTheme(
        backgroundColor: bgLight,
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfLight,
        indicatorColor: accentLight.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: accentLight, fontSize: 10);
          }
          return const TextStyle(color: mutedLight, fontSize: 10);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: accentLight);
          }
          return const IconThemeData(color: mutedLight);
        }),
      ),
      cardTheme: CardThemeData(
        color: surfLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: borderLight),
        ),
      ),
      dividerColor: borderLight,
    );
  }
}