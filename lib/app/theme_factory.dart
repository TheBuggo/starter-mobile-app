import 'package:flutter/material.dart';

import '../models/theme_settings.dart';

class ThemeFactory {
  static ThemeData fromSettings(ThemeSettings settings) {
    final colorScheme = ColorScheme.fromSeed(
      brightness: settings.darkMode ? Brightness.dark : Brightness.light,
      seedColor: Color(settings.seedColor),
    );

    return ThemeData(
      brightness: colorScheme.brightness,
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      colorScheme: colorScheme,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      scaffoldBackgroundColor: colorScheme.surface,
      useMaterial3: true,
    );
  }
}
