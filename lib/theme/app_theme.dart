import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6A1B9A);
  static const Color backgroundColor = Colors.black;
  static const Color textColor = Colors.white;
  static const Color mutedTextColor = Colors.white70;

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: backgroundColor,
        onPrimary: textColor,
        onSecondary: textColor,
        onSurface: textColor,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor),
        titleLarge: TextStyle(color: textColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: textColor,
          backgroundColor: primaryColor,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: mutedTextColor,
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
} 