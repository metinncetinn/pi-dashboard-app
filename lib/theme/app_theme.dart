import 'package:flutter/material.dart';

class AppTheme {
  // Renkler — web arayüzüyle aynı
  static const Color accent   = Color(0xFFC8FF00); // neon chartreuse
  static const Color accent2  = Color(0xFF00D4FF);
  static const Color bgDark   = Color(0xFF0A0A0A);
  static const Color surfDark = Color(0xFF111111);
  static const Color surf2Dark= Color(0xFF181818);
  static const Color borderDark= Color(0xFF222222);
  static const Color textDark = Color(0xFFE8E8E8);
  static const Color mutedDark= Color(0xFF555555);
  static const Color green    = Color(0xFF00E676);
  static const Color red      = Color(0xFFFF4444);

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
          return const TextStyle(color: Color(0xFF555555), fontSize: 10);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: accent);
          }
          return const IconThemeData(color: Color(0xFF555555));
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
      scaffoldBackgroundColor: const Color(0xFFF0F0F0),
      colorScheme: const ColorScheme.light(
        primary:   Color(0xFF5A8A00),
        secondary: accent2,
        surface:   Colors.white,
        error:     red,
      ),
      fontFamily: 'JetBrainsMono',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF0F0F0),
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 0,
      ),
    );
  }
}