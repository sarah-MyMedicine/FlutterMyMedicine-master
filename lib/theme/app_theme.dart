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
    final secondaryText = Color.lerp(onSurface, Colors.white, 0.35) ?? Colors.black87;
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
        surface: Colors.white,
        onSurface: onSurface,
      ),
      canvasColor: Colors.white,
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      iconTheme: IconThemeData(color: onSurface),
      listTileTheme: ListTileThemeData(
        textColor: onSurface,
        iconColor: onSurface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: secondaryText,
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: onSurface),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: lightBg,
          labelStyle: TextStyle(color: secondaryText),
          hintStyle: TextStyle(color: secondaryText),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        ),
      ),
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
        labelStyle: TextStyle(color: secondaryText),
        hintStyle: TextStyle(color: secondaryText),
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
      textTheme: _buildTextTheme(onSurface, secondaryText),
    );
  }

  static ThemeData darkTheme(Color primaryColor) {
    final secondary = Color.lerp(primaryColor, Colors.white, 0.15) ?? primaryColor;
    final surface = const Color(0xFF121212);
    final inputFill = const Color(0xFF1E1E1E);
    final border = Color.lerp(primaryColor, Colors.white, 0.35) ?? primaryColor;
    const onSurface = Colors.white;
    const secondaryText = Colors.white70;

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
        surface: surface,
        onSurface: onSurface,
      ),
      canvasColor: const Color(0xFF171A20),
      scaffoldBackgroundColor: const Color(0xFF0F1115),
      cardColor: const Color(0xFF171A20),
      iconTheme: const IconThemeData(color: onSurface),
      listTileTheme: const ListTileThemeData(
        textColor: onSurface,
        iconColor: onSurface,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF171A20),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: secondaryText,
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF171A20),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(color: onSurface),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1E1E1E),
          labelStyle: TextStyle(color: secondaryText),
          hintStyle: TextStyle(color: secondaryText),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(Color(0xFF171A20)),
          surfaceTintColor: WidgetStatePropertyAll<Color>(Colors.transparent),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF181B22),
        foregroundColor: Colors.white,
        elevation: 0,
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
        fillColor: inputFill,
        labelStyle: const TextStyle(color: secondaryText),
        hintStyle: const TextStyle(color: secondaryText),
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
      textTheme: _buildTextTheme(onSurface, secondaryText),
    );
  }

  static ThemeData theme(Color primaryColor) => lightTheme(primaryColor);
}
