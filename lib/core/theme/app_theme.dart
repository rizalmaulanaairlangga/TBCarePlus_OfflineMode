import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        elevation: 0,
      ),
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.white,
        error: AppColors.destructive,
        onPrimary: AppColors.primaryForeground,
        onSurface: AppColors.foreground,
        outline: AppColors.border,
      ),
      cardColor: AppColors.white,
      dividerColor: AppColors.border,
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkForeground,
        elevation: 0,
      ),
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        surface: AppColors.darkSurface,
        error: AppColors.darkDestructive,
        onPrimary: AppColors.darkPrimaryForeground,
        onSurface: AppColors.darkForeground,
        outline: AppColors.darkBorder,
        onError: Colors.white,
      ),
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkBorder,
      useMaterial3: true,
    );
  }
}
