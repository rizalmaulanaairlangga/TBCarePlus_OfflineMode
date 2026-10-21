import 'package:flutter/material.dart';
import '../settings/app_settings.dart';

class AppColors {
  // ── Base light palette (normal) ──
  static const Color _lightBackground = Color(0xFFF0FDF4);
  static const Color _lightForeground = Color(0xFF064E3B);
  static const Color _lightBorder = Color(0xFFD1FAE5);
  static const Color _lightPrimary = Color(0xFF10B981);
  static const Color _lightPrimaryFg = Color(0xFFFFFFFF);
  static const Color _lightSecondary = Color(0xFF059669);
  static const Color _lightMuted = Color(0xFFA7F3D0);
  static const Color _lightMutedFg = Color(0xFF047857);
  static const Color _lightAccent = Color(0xFF0D9488);
  static const Color _lightWarning = Color(0xFFF59E0B);
  static const Color _lightDestructive = Color(0xFFEF4444);
  static const Color white = Color(0xFFFFFFFF);

  // Dark base
  static const Color _darkBackground = Color(0xFF0B1E16);
  static const Color _darkSurface = Color(0xFF132A1F);
  static const Color _darkSurfaceAlt = Color(0xFF1A3328);
  static const Color _darkForeground = Color(0xFFE6FFF3);
  static const Color _darkBorder = Color(0xFF1E3D2F);
  static const Color _darkMuted = Color(0xFF204536);
  static const Color _darkMutedFg = Color(0xFF8ED0B7);
  static const Color _darkPrimary = Color(0xFF34D399);
  static const Color _darkPrimaryFg = Color(0xFF022016);
  static const Color _darkSecondary = Color(0xFF10B981);
  static const Color _darkAccent = Color(0xFF2DD4BF);
  static const Color _darkWarning = Color(0xFFFBBF24);
  static const Color _darkDestructive = Color(0xFFF87171);

  // ── Light theme getters (color-blind aware) ──
  static Color get background => _resolveLight((c) => c._lightBackground, ColorBlindMode.normal);
  static Color get foreground => _resolveLight((c) => c._lightForeground, ColorBlindMode.normal);
  static Color get border => _resolveLight((c) => c._lightBorder, ColorBlindMode.normal);
  static Color get primary => _resolveLight((c) => c._lightPrimary, ColorBlindMode.normal);
  static Color get primaryForeground => _lightPrimaryFg;
  static Color get secondary => _resolveLight((c) => c._lightSecondary, ColorBlindMode.normal);
  static Color get muted => _resolveLight((c) => c._lightMuted, ColorBlindMode.normal);
  static Color get mutedForeground => _resolveLight((c) => c._lightMutedFg, ColorBlindMode.normal);
  static Color get accent => _resolveLight((c) => c._lightAccent, ColorBlindMode.normal);
  static Color get warning => _resolveLight((c) => c._lightWarning, ColorBlindMode.normal);
  static Color get destructive => _resolveLight((c) => c._lightDestructive, ColorBlindMode.normal);

  // Dark getters remain for backwards compat, but delegate
  static Color get darkBackground => _resolveDark((c) => c._darkBackground);
  static Color get darkSurface => _resolveDark((c) => c._darkSurface);
  static Color get darkSurfaceAlt => _resolveDark((c) => c._darkSurfaceAlt);
  static Color get darkForeground => _resolveDark((c) => c._darkForeground);
  static Color get darkBorder => _resolveDark((c) => c._darkBorder);
  static Color get darkMuted => _resolveDark((c) => c._darkMuted);
  static Color get darkMutedForeground => _resolveDark((c) => c._darkMutedFg);
  static Color get darkPrimary => _resolveDark((c) => c._darkPrimary);
  static Color get darkPrimaryForeground {
    final mode = AppSettings.instance.colorBlindMode;
    if (mode == ColorBlindMode.highContrast) return const Color(0xFF000000);
    return _darkPrimaryFg;
  }
  static Color get darkSecondary => _resolveDark((c) => c._darkSecondary);
  static Color get darkAccent => _resolveDark((c) => c._darkAccent);
  static Color get darkWarning => _resolveDark((c) => c._darkWarning);
  static Color get darkDestructive => _resolveDark((c) => c._darkDestructive);

  // ── Palette overrides per color-blind mode ──
  static Color _resolveLight(Color Function(_Palette p) pick, ColorBlindMode fallback) {
    final mode = AppSettings.instance.colorBlindMode;
    // For light, use palette light colors
    switch (mode) {
      case ColorBlindMode.deuteranopia:
      case ColorBlindMode.protanopia:
        return _deuterLight(pick);
      case ColorBlindMode.tritanopia:
        return _tritanLight(pick);
      case ColorBlindMode.highContrast:
        return _highContrastLight(pick);
      case ColorBlindMode.normal:
        return pick(_Palette.normalLight);
    }
  }

  static Color _resolveDark(Color Function(_Palette p) pick) {
    final mode = AppSettings.instance.colorBlindMode;
    switch (mode) {
      case ColorBlindMode.deuteranopia:
      case ColorBlindMode.protanopia:
        return _deuterDark(pick);
      case ColorBlindMode.tritanopia:
        return _tritanDark(pick);
      case ColorBlindMode.highContrast:
        return _highContrastDark(pick);
      case ColorBlindMode.normal:
        return pick(_Palette.normalDark);
    }
  }

  static Color _deuterLight(Color Function(_Palette p) pick) {
    // Wong palette: blue primary, vermillion/orange for risk, blue backgrounds
    if (pick(_Palette.normalLight) == _lightPrimary) return const Color(0xFF0072B2);
    if (pick(_Palette.normalLight) == _lightSecondary) return const Color(0xFF005A9C);
    if (pick(_Palette.normalLight) == _lightAccent) return const Color(0xFF56B4E9);
    if (pick(_Palette.normalLight) == _lightWarning) return const Color(0xFFE69F00);
    if (pick(_Palette.normalLight) == _lightDestructive) return const Color(0xFFD55E00);
    if (pick(_Palette.normalLight) == _lightBackground) return const Color(0xFFF0F7FF);
    if (pick(_Palette.normalLight) == _lightForeground) return const Color(0xFF002A3A);
    if (pick(_Palette.normalLight) == _lightBorder) return const Color(0xFFBFD9EC);
    if (pick(_Palette.normalLight) == _lightMuted) return const Color(0xFFCCE6F2);
    if (pick(_Palette.normalLight) == _lightMutedFg) return const Color(0xFF004B6B);
    return pick(_Palette.normalLight);
  }

  static Color _deuterDark(Color Function(_Palette p) pick) {
    if (pick(_Palette.normalDark) == _darkPrimary) return const Color(0xFF56B4E9);
    if (pick(_Palette.normalDark) == _darkSecondary) return const Color(0xFF0072B2);
    if (pick(_Palette.normalDark) == _darkAccent) return const Color(0xFF56B4E9);
    if (pick(_Palette.normalDark) == _darkWarning) return const Color(0xFFF0C040);
    if (pick(_Palette.normalDark) == _darkDestructive) return const Color(0xFFFF8C42);
    if (pick(_Palette.normalDark) == _darkBackground) return const Color(0xFF0A1929);
    if (pick(_Palette.normalDark) == _darkSurface) return const Color(0xFF122840);
    if (pick(_Palette.normalDark) == _darkSurfaceAlt) return const Color(0xFF1A3652);
    if (pick(_Palette.normalDark) == _darkForeground) return const Color(0xFFE6F0FF);
    if (pick(_Palette.normalDark) == _darkBorder) return const Color(0xFF1E3A5A);
    if (pick(_Palette.normalDark) == _darkMuted) return const Color(0xFF1E3A5A);
    if (pick(_Palette.normalDark) == _darkMutedFg) return const Color(0xFF8EC8E6);
    return pick(_Palette.normalDark);
  }

  static Color _tritanLight(Color Function(_Palette p) pick) {
    if (pick(_Palette.normalLight) == _lightPrimary) return const Color(0xFF009E73);
    if (pick(_Palette.normalLight) == _lightSecondary) return const Color(0xFF007A5A);
    if (pick(_Palette.normalLight) == _lightAccent) return const Color(0xFF009E73);
    if (pick(_Palette.normalLight) == _lightWarning) return const Color(0xFFCC79A7);
    if (pick(_Palette.normalLight) == _lightDestructive) return const Color(0xFFD55E00);
    if (pick(_Palette.normalLight) == _lightBackground) return const Color(0xFFF0FAF6);
    if (pick(_Palette.normalLight) == _lightForeground) return const Color(0xFF00332A);
    if (pick(_Palette.normalLight) == _lightBorder) return const Color(0xFFBFE8D9);
    if (pick(_Palette.normalLight) == _lightMuted) return const Color(0xFFC8EDE0);
    if (pick(_Palette.normalLight) == _lightMutedFg) return const Color(0xFF005A45);
    return pick(_Palette.normalLight);
  }

  static Color _tritanDark(Color Function(_Palette p) pick) {
    if (pick(_Palette.normalDark) == _darkPrimary) return const Color(0xFF00D09E);
    if (pick(_Palette.normalDark) == _darkSecondary) return const Color(0xFF009E73);
    if (pick(_Palette.normalDark) == _darkAccent) return const Color(0xFF00D09E);
    if (pick(_Palette.normalDark) == _darkWarning) return const Color(0xFFE8A0BF);
    if (pick(_Palette.normalDark) == _darkDestructive) return const Color(0xFFFF8C42);
    if (pick(_Palette.normalDark) == _darkBackground) return const Color(0xFF0B1E1A);
    if (pick(_Palette.normalDark) == _darkSurface) return const Color(0xFF14302A);
    if (pick(_Palette.normalDark) == _darkSurfaceAlt) return const Color(0xFF1E453A);
    if (pick(_Palette.normalDark) == _darkForeground) return const Color(0xFFE6FFF3);
    if (pick(_Palette.normalDark) == _darkBorder) return const Color(0xFF1E3D32);
    if (pick(_Palette.normalDark) == _darkMuted) return const Color(0xFF1E453A);
    if (pick(_Palette.normalDark) == _darkMutedFg) return const Color(0xFF8EDCC8);
    return pick(_Palette.normalDark);
  }

  static Color _highContrastLight(Color Function(_Palette p) pick) {
    // Black-yellow high contrast, WCAG AAA
    if (pick(_Palette.normalLight) == _lightPrimary) return const Color(0xFF000000);
    if (pick(_Palette.normalLight) == _lightSecondary) return const Color(0xFF222222);
    if (pick(_Palette.normalLight) == _lightAccent) return const Color(0xFF000000);
    if (pick(_Palette.normalLight) == _lightWarning) return const Color(0xFFB45309);
    if (pick(_Palette.normalLight) == _lightDestructive) return const Color(0xFFB91C1C);
    if (pick(_Palette.normalLight) == _lightBackground) return const Color(0xFFFFFFFF);
    if (pick(_Palette.normalLight) == _lightForeground) return const Color(0xFF000000);
    if (pick(_Palette.normalLight) == _lightBorder) return const Color(0xFF000000);
    if (pick(_Palette.normalLight) == _lightMuted) return const Color(0xFFE5E5E5);
    if (pick(_Palette.normalLight) == _lightMutedFg) return const Color(0xFF000000);
    return pick(_Palette.normalLight);
  }

  static Color _highContrastDark(Color Function(_Palette p) pick) {
    if (pick(_Palette.normalDark) == _darkPrimary) return const Color(0xFFFFFF00); // yellow on black
    if (pick(_Palette.normalDark) == _darkSecondary) return const Color(0xFFFFEB3B);
    if (pick(_Palette.normalDark) == _darkAccent) return const Color(0xFFFFFF00);
    if (pick(_Palette.normalDark) == _darkWarning) return const Color(0xFFFFD600);
    if (pick(_Palette.normalDark) == _darkDestructive) return const Color(0xFFFF5252);
    if (pick(_Palette.normalDark) == _darkBackground) return const Color(0xFF000000);
    if (pick(_Palette.normalDark) == _darkSurface) return const Color(0xFF111111);
    if (pick(_Palette.normalDark) == _darkSurfaceAlt) return const Color(0xFF222222);
    if (pick(_Palette.normalDark) == _darkForeground) return const Color(0xFFFFFFFF);
    if (pick(_Palette.normalDark) == _darkBorder) return const Color(0xFFFFFFFF);
    if (pick(_Palette.normalDark) == _darkMuted) return const Color(0xFF333333);
    if (pick(_Palette.normalDark) == _darkMutedFg) return const Color(0xFFFFFFFF);
    return pick(_Palette.normalDark);
  }

  // Helpers to resolve based on brightness
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext c) => isDark(c) ? darkBackground : background;
  static Color fg(BuildContext c) => isDark(c) ? darkForeground : foreground;
  static Color bd(BuildContext c) => isDark(c) ? darkBorder : border;
  static Color pri(BuildContext c) => isDark(c) ? darkPrimary : primary;
  static Color priFg(BuildContext c) => isDark(c) ? darkPrimaryForeground : primaryForeground;
  static Color sec(BuildContext c) => isDark(c) ? darkSecondary : secondary;
  static Color mut(BuildContext c) => isDark(c) ? darkMuted : muted;
  static Color mutFg(BuildContext c) => isDark(c) ? darkMutedForeground : mutedForeground;
  static Color acc(BuildContext c) => isDark(c) ? darkAccent : accent;
  static Color card(BuildContext c) => isDark(c) ? darkSurface : white;
  static Color cardAlt(BuildContext c) => isDark(c) ? darkSurfaceAlt : white;
}

class _Palette {
  final Color _lightBackground;
  final Color _lightForeground;
  final Color _lightBorder;
  final Color _lightPrimary;
  final Color _lightSecondary;
  final Color _lightMuted;
  final Color _lightMutedFg;
  final Color _lightAccent;
  final Color _lightWarning;
  final Color _lightDestructive;
  final Color _darkBackground;
  final Color _darkSurface;
  final Color _darkSurfaceAlt;
  final Color _darkForeground;
  final Color _darkBorder;
  final Color _darkMuted;
  final Color _darkMutedFg;
  final Color _darkPrimary;
  final Color _darkSecondary;
  final Color _darkAccent;
  final Color _darkWarning;
  final Color _darkDestructive;
  const _Palette({
    required Color lightBackground,
    required Color lightForeground,
    required Color lightBorder,
    required Color lightPrimary,
    required Color lightSecondary,
    required Color lightMuted,
    required Color lightMutedFg,
    required Color lightAccent,
    required Color lightWarning,
    required Color lightDestructive,
    required Color darkBackground,
    required Color darkSurface,
    required Color darkSurfaceAlt,
    required Color darkForeground,
    required Color darkBorder,
    required Color darkMuted,
    required Color darkMutedFg,
    required Color darkPrimary,
    required Color darkSecondary,
    required Color darkAccent,
    required Color darkWarning,
    required Color darkDestructive,
  })  : _lightBackground = lightBackground,
        _lightForeground = lightForeground,
        _lightBorder = lightBorder,
        _lightPrimary = lightPrimary,
        _lightSecondary = lightSecondary,
        _lightMuted = lightMuted,
        _lightMutedFg = lightMutedFg,
        _lightAccent = lightAccent,
        _lightWarning = lightWarning,
        _lightDestructive = lightDestructive,
        _darkBackground = darkBackground,
        _darkSurface = darkSurface,
        _darkSurfaceAlt = darkSurfaceAlt,
        _darkForeground = darkForeground,
        _darkBorder = darkBorder,
        _darkMuted = darkMuted,
        _darkMutedFg = darkMutedFg,
        _darkPrimary = darkPrimary,
        _darkSecondary = darkSecondary,
        _darkAccent = darkAccent,
        _darkWarning = darkWarning,
        _darkDestructive = darkDestructive;

  static const normalLight = _Palette(
    lightBackground: Color(0xFFF0FDF4),
    lightForeground: Color(0xFF064E3B),
    lightBorder: Color(0xFFD1FAE5),
    lightPrimary: Color(0xFF10B981),
    lightSecondary: Color(0xFF059669),
    lightMuted: Color(0xFFA7F3D0),
    lightMutedFg: Color(0xFF047857),
    lightAccent: Color(0xFF0D9488),
    lightWarning: Color(0xFFF59E0B),
    lightDestructive: Color(0xFFEF4444),
    darkBackground: Color(0xFF0B1E16),
    darkSurface: Color(0xFF132A1F),
    darkSurfaceAlt: Color(0xFF1A3328),
    darkForeground: Color(0xFFE6FFF3),
    darkBorder: Color(0xFF1E3D2F),
    darkMuted: Color(0xFF204536),
    darkMutedFg: Color(0xFF8ED0B7),
    darkPrimary: Color(0xFF34D399),
    darkSecondary: Color(0xFF10B981),
    darkAccent: Color(0xFF2DD4BF),
    darkWarning: Color(0xFFFBBF24),
    darkDestructive: Color(0xFFF87171),
  );

  static const normalDark = normalLight;
}
