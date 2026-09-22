import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get heading1 => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.foreground,
    letterSpacing: -0.7,
    height: 1.05,
  );
  static TextStyle get heading2 => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.foreground,
    letterSpacing: -0.5,
    height: 1.1,
  );
  static TextStyle get bodyMedium => TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedForeground,
    height: 1.5,
  );
  static TextStyle get bodySmall => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedForeground,
    height: 1.4,
  );
  static TextStyle get buttonPrimary => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryForeground,
  );
  static TextStyle get buttonSecondary => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );
  static double scaleDown(BuildContext context, double base, {double smallFactor = 0.92}) {
    final w = MediaQuery.of(context).size.width;
    if (w < 360) return base * smallFactor;
    if (w < 380) return base * 0.96;
    return base;
  }
}
