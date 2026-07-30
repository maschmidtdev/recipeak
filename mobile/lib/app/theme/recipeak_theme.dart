import 'package:flutter/material.dart';

final class RecipeakTheme {
  RecipeakTheme._();

  static ThemeData light() {
    const background = Color(0xFFF6F1E8);
    const surface = Color(0xFFFFFCF6);
    const primary = Color(0xFF295F4E);
    const secondary = Color(0xFFC96A3D);
    const outline = Color(0xFFD7CCBE);
    const text = Color(0xFF1F2520);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      surface: surface,
      outline: outline,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: text,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: outline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE9E0D1),
        selectedColor: secondary,
        secondarySelectedColor: secondary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: const TextStyle(
          color: text,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
