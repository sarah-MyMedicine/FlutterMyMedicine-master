import 'package:flutter/material.dart';

class AppColors {
  static const warning = Color(0xFFFFB300);
}

class AppTheme {
  static ThemeData theme(Color primaryColor) {
    // Generate lighter shade for light backgrounds
    final lightBg = Color.lerp(primaryColor, Colors.white, 0.9) ?? Colors.white;
    
    final base = ThemeData.from(
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: Color.lerp(primaryColor, Colors.black, 0.1) ?? primaryColor,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color.lerp(primaryColor, Colors.black, 0.3) ?? Colors.black,
      ),
    );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primaryColor,
        secondary: Color.lerp(primaryColor, Colors.black, 0.1) ?? primaryColor,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color.lerp(primaryColor, Colors.black, 0.2) ?? primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color.lerp(primaryColor, Colors.black, 0.2) ?? primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color.lerp(primaryColor, Colors.black, 0.3) ?? Colors.black,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color.lerp(primaryColor, Colors.black, 0.3) ?? Colors.black,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.lerp(primaryColor, Colors.black, 0.3) ?? Colors.black,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color.lerp(primaryColor, Colors.black, 0.3) ?? Colors.black,
        ),
        bodyMedium: const TextStyle(fontSize: 14, color: Colors.black87),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        bodySmall: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
