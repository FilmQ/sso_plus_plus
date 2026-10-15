import 'package:flutter/material.dart';

import 'status_colors.dart';

/// The Material 3 theme of the user app and the console.
///
/// The Figma frames use the Material 3 baseline palette, so the seed is the
/// baseline primary colour #6750A4.
abstract final class AppTheme {
  static const Color seed = Color(0xFF6750A4);

  /// The bundled Thai font (pubspec.yaml). Latin text keeps the default font;
  /// Thai characters use this one, as in the Figma frames.
  static const String thaiFont = 'NotoSansThai';

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme colors = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: colors,
      fontFamilyFallback: const <String>[thaiFont],
      extensions: <ThemeExtension<dynamic>>[
        brightness == Brightness.light ? StatusColors.light : StatusColors.dark,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
      ),
    );
  }
}
