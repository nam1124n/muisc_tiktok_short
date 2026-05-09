import 'package:flutter/material.dart';

class AppTheme {
  static const _brandColor = Color(0xFF9038FF);
  static const _scaffoldBackgroundColor = Color(0xFFF8F9FA);
  static const _cardBackgroundColor = Colors.white;
  static const _inputBorderColor = Color(0xFFE5E7EB);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _brandColor),
    );
    final textTheme = base.textTheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _inputBorderColor),
    );

    return base.copyWith(
      scaffoldBackgroundColor: _scaffoldBackgroundColor,
      colorScheme: base.colorScheme.copyWith(
        primary: _brandColor,
        surface: _cardBackgroundColor,
      ),
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF111827),
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF111827),
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1F2937),
        ),
        labelMedium: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: const Color(0xFF6B7280),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: _brandColor, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _brandColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _brandColor),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        color: _cardBackgroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
    );
  }
}
