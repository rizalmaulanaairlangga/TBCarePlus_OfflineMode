import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../l10n/app_strings.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._internal();
  AppSettings._internal();

  static const String _boxName = 'meta';
  static const String _kLocale = 'app_locale';
  static const String _kThemeMode = 'app_theme_mode';
  static const String _kFontScale = 'app_font_scale';
  static const String _kColorBlind = 'app_color_blind';

  AppLocale _locale = AppLocale.id;
  ThemeModeOption _themeMode = ThemeModeOption.system;
  FontScaleOption _fontScale = FontScaleOption.medium;
  ColorBlindMode _colorBlindMode = ColorBlindMode.normal;

  AppLocale get locale => _locale;
  ThemeModeOption get themeModeOption => _themeMode;
  FontScaleOption get fontScaleOption => _fontScale;
  ColorBlindMode get colorBlindMode => _colorBlindMode;
  double get fontScale => _fontScale.scale;

  ThemeMode get themeMode {
    switch (_themeMode) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }

  Future<void> init() async {
    final box = Hive.box(_boxName);
    final locCode = box.get(_kLocale) as String?;
    if (locCode != null) {
      _locale = AppLocaleExt.fromCode(locCode);
    }
    final themeCode = box.get(_kThemeMode) as String?;
    if (themeCode != null) {
      _themeMode = ThemeModeOptionExt.fromCode(themeCode);
    }
    final fontCode = box.get(_kFontScale) as String?;
    if (fontCode != null) {
      _fontScale = FontScaleOptionExt.fromCode(fontCode);
    }
    final cbCode = box.get(_kColorBlind) as String?;
    if (cbCode != null) {
      _colorBlindMode = ColorBlindModeExt.fromCode(cbCode);
    }
    // Listen to box changes for external updates
    box.watch().listen((event) {
      bool changed = false;
      if (event.key == _kLocale) {
        final newLoc = AppLocaleExt.fromCode(event.value as String?);
        if (newLoc != _locale) {
          _locale = newLoc;
          changed = true;
        }
      } else if (event.key == _kThemeMode) {
        final newTheme = ThemeModeOptionExt.fromCode(event.value as String?);
        if (newTheme != _themeMode) {
          _themeMode = newTheme;
          changed = true;
        }
      } else if (event.key == _kFontScale) {
        final newFont = FontScaleOptionExt.fromCode(event.value as String?);
        if (newFont != _fontScale) {
          _fontScale = newFont;
          changed = true;
        }
      } else if (event.key == _kColorBlind) {
        final newCb = ColorBlindModeExt.fromCode(event.value as String?);
        if (newCb != _colorBlindMode) {
          _colorBlindMode = newCb;
          changed = true;
        }
      }
      if (changed) notifyListeners();
    });
  }

  Future<void> setLocale(AppLocale locale) async {
    _locale = locale;
    notifyListeners();
    final box = Hive.box(_boxName);
    await box.put(_kLocale, locale.code);
  }

  Future<void> setThemeMode(ThemeModeOption mode) async {
    _themeMode = mode;
    notifyListeners();
    final box = Hive.box(_boxName);
    await box.put(_kThemeMode, mode.code);
  }

  Future<void> setFontScale(FontScaleOption scale) async {
    _fontScale = scale;
    notifyListeners();
    final box = Hive.box(_boxName);
    await box.put(_kFontScale, scale.code);
  }

  Future<void> setColorBlindMode(ColorBlindMode mode) async {
    _colorBlindMode = mode;
    notifyListeners();
    final box = Hive.box(_boxName);
    await box.put(_kColorBlind, mode.code);
  }
}

enum ThemeModeOption { light, dark, system }

extension ThemeModeOptionExt on ThemeModeOption {
  String get code {
    switch (this) {
      case ThemeModeOption.light:
        return 'light';
      case ThemeModeOption.dark:
        return 'dark';
      case ThemeModeOption.system:
        return 'system';
    }
  }

  String displayName(AppLocale locale) {
    final isId = locale == AppLocale.id;
    switch (this) {
      case ThemeModeOption.light:
        return isId ? 'Terang' : 'Light';
      case ThemeModeOption.dark:
        return isId ? 'Gelap' : 'Dark';
      case ThemeModeOption.system:
        return isId ? 'Mengikuti Sistem' : 'System';
    }
  }

  String description(AppLocale locale) {
    final isId = locale == AppLocale.id;
    switch (this) {
      case ThemeModeOption.light:
        return isId ? 'Tampilan terang dengan nuansa hijau' : 'Bright appearance with green tones';
      case ThemeModeOption.dark:
        return isId ? 'Tampilan gelap hemat mata' : 'Dark appearance, easy on eyes';
      case ThemeModeOption.system:
        return isId ? 'Mengikuti pengaturan HP' : 'Follow system setting';
    }
  }

  static ThemeModeOption fromCode(String? code) {
    switch (code) {
      case 'light':
        return ThemeModeOption.light;
      case 'dark':
        return ThemeModeOption.dark;
      default:
        return ThemeModeOption.system;
    }
  }
}

enum FontScaleOption { small, medium, large, extraLarge }

extension FontScaleOptionExt on FontScaleOption {
  String get code {
    switch (this) {
      case FontScaleOption.small:
        return 'small';
      case FontScaleOption.medium:
        return 'medium';
      case FontScaleOption.large:
        return 'large';
      case FontScaleOption.extraLarge:
        return 'extraLarge';
    }
  }

  double get scale {
    switch (this) {
      case FontScaleOption.small:
        return 0.85;
      case FontScaleOption.medium:
        return 1.0;
      case FontScaleOption.large:
        return 1.15;
      case FontScaleOption.extraLarge:
        return 1.30;
    }
  }

  String displayName(AppLocale locale) {
    final isId = locale == AppLocale.id;
    switch (this) {
      case FontScaleOption.small:
        return isId ? 'Kecil' : 'Small';
      case FontScaleOption.medium:
        return isId ? 'Sedang (Default)' : 'Medium (Default)';
      case FontScaleOption.large:
        return isId ? 'Besar' : 'Large';
      case FontScaleOption.extraLarge:
        return isId ? 'Sangat Besar' : 'Extra Large';
    }
  }

  String description(AppLocale locale) {
    final isId = locale == AppLocale.id;
    switch (this) {
      case FontScaleOption.small:
        return isId ? '85% — kompak' : '85% — compact';
      case FontScaleOption.medium:
        return isId ? '100% — standar' : '100% — standard';
      case FontScaleOption.large:
        return isId ? '115% — mudah dibaca' : '115% — easy to read';
      case FontScaleOption.extraLarge:
        return isId ? '130% — untuk lansia' : '130% — for seniors';
    }
  }

  static FontScaleOption fromCode(String? code) {
    switch (code) {
      case 'small':
        return FontScaleOption.small;
      case 'large':
        return FontScaleOption.large;
      case 'extraLarge':
        return FontScaleOption.extraLarge;
      default:
        return FontScaleOption.medium;
    }
  }
}

enum ColorBlindMode { normal, deuteranopia, protanopia, tritanopia, highContrast }

extension ColorBlindModeExt on ColorBlindMode {
  String get code {
    switch (this) {
      case ColorBlindMode.normal:
        return 'normal';
      case ColorBlindMode.deuteranopia:
        return 'deuteranopia';
      case ColorBlindMode.protanopia:
        return 'protanopia';
      case ColorBlindMode.tritanopia:
        return 'tritanopia';
      case ColorBlindMode.highContrast:
        return 'highContrast';
    }
  }

  String displayName(AppLocale locale) {
    final isId = locale == AppLocale.id;
    switch (this) {
      case ColorBlindMode.normal:
        return isId ? 'Normal' : 'Normal';
      case ColorBlindMode.deuteranopia:
        return isId ? 'Deuteranopia (Hijau)' : 'Deuteranopia';
      case ColorBlindMode.protanopia:
        return isId ? 'Protanopia (Merah)' : 'Protanopia';
      case ColorBlindMode.tritanopia:
        return isId ? 'Tritanopia (Biru-Kuning)' : 'Tritanopia';
      case ColorBlindMode.highContrast:
        return isId ? 'Kontras Tinggi' : 'High Contrast';
    }
  }

  String description(AppLocale locale) {
    final isId = locale == AppLocale.id;
    switch (this) {
      case ColorBlindMode.normal:
        return isId ? 'Warna standar hijau' : 'Standard green palette';
      case ColorBlindMode.deuteranopia:
        return isId ? 'Ramah buta hijau — biru & vermillion' : 'Green-blind friendly — blue & vermillion';
      case ColorBlindMode.protanopia:
        return isId ? 'Ramah buta merah — biru & oranye' : 'Red-blind friendly — blue & orange';
      case ColorBlindMode.tritanopia:
        return isId ? 'Ramah buta biru-kuning' : 'Blue-yellow blind friendly';
      case ColorBlindMode.highContrast:
        return isId ? 'Hitam-putih kontras maksimal' : 'Max contrast black & white';
    }
  }

  static ColorBlindMode fromCode(String? code) {
    switch (code) {
      case 'deuteranopia':
        return ColorBlindMode.deuteranopia;
      case 'protanopia':
        return ColorBlindMode.protanopia;
      case 'tritanopia':
        return ColorBlindMode.tritanopia;
      case 'highContrast':
        return ColorBlindMode.highContrast;
      default:
        return ColorBlindMode.normal;
    }
  }
}
