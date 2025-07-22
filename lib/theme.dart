import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF15202B);
  static const Color background = Color(0xFF0F1419);

  // Secondary color - used for buttons, links and highlights
  static const Color secondary = Color(0xFF1D9BF0);

  // Accent color - used for critical alerts
  static const Color accent = Color(0xFFE0245E);

  // Success color - used for normal status
  static const Color success = Color(0xFF17BF63);

  // Card background color
  static const Color cardBg = Color(0xFF192734);

  // Text colors
  static const Color textPrimary = Color(0xFFE1E8ED);
  static const Color textSecondary = Color(0xFF8899A6);
}

ThemeData darkTheme() {
  return ThemeData(
    // Base colors
    scaffoldBackgroundColor: AppColors.primary,
    primaryColor: AppColors.secondary,

    // AppBar theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.secondary),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        shape: StadiumBorder(),
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: AppColors.textSecondary),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.cardBg),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.cardBg),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.secondary),
      ),
    ),

    // Text theme
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
    ),

    // Card and Dialog theme
    cardColor: AppColors.cardBg,
    dialogBackgroundColor: AppColors.cardBg,

    // Icon theme
    iconTheme: IconThemeData(
      color: AppColors.secondary,
    ),
  );
}
