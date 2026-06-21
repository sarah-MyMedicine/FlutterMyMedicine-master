import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const warning = Color(0xFFFFB300);
}

class AppTheme {
  static TextTheme _buildTextTheme(Color textColor, Color secondaryTextColor) {
    return GoogleFonts.notoSansArabicTextTheme(
      TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textColor,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: secondaryTextColor),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        bodySmall: TextStyle(fontSize: 12, color: secondaryTextColor),
      ),
    );
  }

  static ThemeData lightTheme(Color primaryColor) {
    final secondary = Color.lerp(primaryColor, Colors.black, 0.1) ?? primaryColor;
    final onSurface = Color.lerp(primaryColor, Colors.black, 0.3) ?? Colors.black;
    final lightBg = Color.lerp(primaryColor, Colors.white, 0.9) ?? Colors.white;

    final base = ThemeData.from(
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondary,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: onSurface,
      ),
    );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primaryColor,
        secondary: secondary,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        toolbarHeight: 60,
        centerTitle: true,
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
      textTheme: _buildTextTheme(onSurface, Colors.black87),
    );
  }

  static ThemeData darkTheme(Color primaryColor) {
    final secondary = Color.lerp(primaryColor, Colors.white, 0.15) ?? primaryColor;
    final surface = const Color(0xFF121212);
    final inputFill = const Color(0xFF1E1E1E);
    final border = Color.lerp(primaryColor, Colors.white, 0.35) ?? primaryColor;

    final base = ThemeData.from(
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondary,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
    );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primaryColor,
        secondary: secondary,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F1115),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF181B22),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        centerTitle: true,
      ),
      cardColor: const Color(0xFF171A20),
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
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
      textTheme: _buildTextTheme(Colors.white, Colors.white70),
    );
  }

  static ThemeData theme(Color primaryColor) => lightTheme(primaryColor);
}
