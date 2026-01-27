import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF5FB8A8); // main teal
  static const primaryDark = Color(0xFF4A9184);
  static const primaryAlt = Color(0xFF52A396);
  static const bgLight = Color(0xFFF0F9F8);
  static const border = Color(0xFFC3E7E2);
  static const heading = Color(0xFF45887E);
  static const deep = Color(0xFF315C56);
  static const warning = Color(0xFFFFB300);
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData.from(
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryAlt,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.deep,
      ),
    );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.primaryAlt,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.deep,
        ), // text-3xl / 3xl
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.deep,
        ), // 2xl / bold
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.deep,
        ), // xl
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.deep),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        bodySmall: TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
