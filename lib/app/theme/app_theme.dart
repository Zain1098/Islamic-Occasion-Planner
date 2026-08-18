import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _green = Color(0xFF285745);
  static const _gold = Color(0xFFB68A3A);
  static const _ivory = Color(0xFFFFF9F0);
  static const _ink = Color(0xFF29251F);

  static ThemeData get light => _buildTheme(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _green,
      primary: _green,
      secondary: _gold,
      surface: _ivory,
      brightness: Brightness.light,
    ),
  );

  static ThemeData get dark => _buildTheme(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF91C3A6),
      primary: const Color(0xFF91C3A6),
      secondary: const Color(0xFFE7C878),
      surface: const Color(0xFF171A17),
      brightness: Brightness.dark,
    ),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
  }) {
    final isLight = brightness == Brightness.light;
    final textTheme = ThemeData(brightness: brightness).textTheme.apply(
      bodyColor: isLight ? _ink : colorScheme.onSurface,
      displayColor: isLight ? _ink : colorScheme.onSurface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isLight ? _ivory : const Color(0xFF111411),
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        indicatorColor: colorScheme.primaryContainer,
        backgroundColor: isLight
            ? const Color(0xFFFFFDF8)
            : const Color(0xFF1A1E1A),
      ),
    );
  }
}
