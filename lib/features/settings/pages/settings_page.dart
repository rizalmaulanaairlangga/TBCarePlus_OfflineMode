import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/settings/app_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark ? AppColors.darkBorder : Colors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        final locale = AppSettings.instance.locale;
        return Scaffold(
          backgroundColor: bg,
          body: Stack(
            children: [
              _buildAuras(context, isDark),
              SafeArea(
                child: Column(
                  children: [
                    ResponsiveCenter(maxWidth: 720, child: _buildHeader(context, fg, card, isDark)),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: ResponsiveCenter(
                          maxWidth: 720,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSectionTitle(context, context.tr('settingsLanguage'), context.tr('settingsLanguageSubtitle'), Icons.language_rounded, isDark, fg, mutedFg),
                              const SizedBox(height: 12),
                              _buildLanguageSelector(context, card, border, fg, mutedFg, isDark, locale),
                              const SizedBox(height: 20),
                              _buildFontSizeSelector(context, card, border, fg, mutedFg, isDark, locale),
                              const SizedBox(height: 20),
                              _buildSectionTitle(context, context.tr('settingsTheme'), context.tr('settingsThemeSubtitle'), Icons.palette_outlined, isDark, fg, mutedFg),
                              const SizedBox(height: 12),
                              _buildThemeSelector(context, card, border, fg, mutedFg, isDark, locale),
                              const SizedBox(height: 20),
                              _buildSectionTitle(context, context.tr('settingsColorBlind'), context.tr('settingsColorBlindSubtitle'), Icons.visibility_rounded, isDark, fg, mutedFg),
                              const SizedBox(height: 12),
                              _buildColorBlindSelector(context, card, border, fg, mutedFg, isDark, locale),
                              const SizedBox(height: 18),
                              _buildPreviewCard(context, isDark, fg, mutedFg, card, border),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.15)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 18, color: isDark ? AppColors.darkPrimary : AppColors.primary),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        locale == AppLocale.id
                                            ? 'Perubahan akan langsung diterapkan.'
                                            : 'Changes are applied immediately.',
                                        style: TextStyle(fontSize: 12, color: mutedFg, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewCard(BuildContext context, bool isDark, Color fg, Color mutedFg, Color card, Color border) {
    final locale = AppSettings.instance.locale;
    final scale = AppSettings.instance.fontScaleOption;
    final cb = AppSettings.instance.colorBlindMode;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final warning = isDark ? AppColors.darkWarning : AppColors.warning;
    final destructive = isDark ? AppColors.darkDestructive : AppColors.destructive;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card.withValues(alpha: isDark ? 1.0 : 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.2), width: 1.2),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100)),
                child: Text(context.tr('settingsPreview'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: primary, letterSpacing: 0.6)),
              ),
              const Spacer(),
              Text('${(scale.scale * 100).round()}% • ${cb.displayName(locale)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: mutedFg)),
            ],
          ),
          const SizedBox(height: 12),
          Text(context.tr('settingsPreviewText'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg)),
          const SizedBox(height: 6),
          Text(
            locale == AppLocale.id
                ? 'Contoh teks ini akan membesar sesuai pilihan ukuran huruf. Warna menyesuaikan mode buta warna.'
                : 'This preview text scales with your font size. Colors adapt to the color-blind mode.',
            style: TextStyle(fontSize: 12, color: mutedFg, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _previewDot(primary, locale == AppLocale.id ? 'Primer' : 'Primary'),
              const SizedBox(width: 8),
              _previewDot(warning, locale == AppLocale.id ? 'Sedang' : 'Medium'),
              const SizedBox(width: 8),
              _previewDot(destructive, locale == AppLocale.id ? 'Tinggi' : 'High'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewDot(Color c, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withValues(alpha: 0.25))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color fg, Color card, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: card.withValues(alpha: isDark ? 0.9 : 0.75),
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? AppColors.darkBorder : Colors.white),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(Icons.arrow_back, color: fg, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              context.tr('settingsTitle'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg, letterSpacing: -0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, String subtitle, IconData icon, bool isDark, Color fg, Color mutedFg) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: isDark ? AppColors.darkPrimary : AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: mutedFg)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(BuildContext context, Color card, Color border, Color fg, Color mutedFg, bool isDark, AppLocale current) {
    return Container(
      decoration: BoxDecoration(
        color: card.withValues(alpha: isDark ? 1.0 : 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: (isDark ? Colors.black : AppColors.primary).withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: AppLocale.values.map((loc) {
          final selected = loc == current;
          return InkWell(
            onTap: () => AppSettings.instance.setLocale(loc),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: selected ? (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.15) : (isDark ? AppColors.darkMuted : AppColors.muted).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(loc == AppLocale.id ? 'ID' : 'EN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: selected ? (isDark ? AppColors.darkPrimary : AppColors.primary) : mutedFg)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.nativeName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: selected ? (isDark ? AppColors.darkPrimary : AppColors.primary) : fg)),
                        Text(loc == AppLocale.id ? 'Bahasa Indonesia' : 'English', style: TextStyle(fontSize: 11, color: mutedFg)),
                      ],
                    ),
                  ),
                  if (selected) Icon(Icons.check_circle_rounded, color: isDark ? AppColors.darkPrimary : AppColors.primary, size: 22) else Icon(Icons.circle_outlined, color: mutedFg.withValues(alpha: 0.3), size: 22),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFontSizeSelector(BuildContext context, Color card, Color border, Color fg, Color mutedFg, bool isDark, AppLocale locale) {
    final current = AppSettings.instance.fontScaleOption;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final idx = FontScaleOption.values.indexOf(current);
    String sliderLabel(FontScaleOption opt) {
      final isId = locale == AppLocale.id;
      switch (opt) {
        case FontScaleOption.small:
          return isId ? 'Kecil' : 'Small';
        case FontScaleOption.medium:
          return 'Default';
        case FontScaleOption.large:
          return isId ? 'Besar' : 'Large';
        case FontScaleOption.extraLarge:
          return isId ? 'Ekstra besar' : 'Extra large';
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: card.withValues(alpha: isDark ? 1.0 : 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: (isDark ? Colors.black : AppColors.primary).withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale == AppLocale.id ? 'Ukuran fon' : 'Font size',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg),
          ),
          const SizedBox(height: 2),
          Text(
            locale == AppLocale.id ? 'Perbesar atau perkecil teks' : 'Make text larger or smaller',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: mutedFg),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('A', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg)),
              const SizedBox(width: 12),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    activeTrackColor: primary,
                    inactiveTrackColor: (isDark ? AppColors.darkMuted : AppColors.muted).withValues(alpha: 0.9),
                    thumbColor: Colors.white,
                    overlayColor: primary.withValues(alpha: 0.15),
                    thumbShape: _RingThumbShape(ringColor: primary, thumbRadius: 10),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                    tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
                    activeTickMarkColor: primary.withValues(alpha: 0.0),
                    inactiveTickMarkColor: Colors.white.withValues(alpha: 0.55),
                    trackShape: const RoundedRectSliderTrackShape(),
                    showValueIndicator: ShowValueIndicator.never,
                  ),
                  child: Slider(
                    value: idx.toDouble(),
                    min: 0,
                    max: 3,
                    divisions: 3,
                    label: sliderLabel(current),
                    onChanged: (v) {
                      final newIdx = v.round().clamp(0, 3);
                      final opt = FontScaleOption.values[newIdx];
                      if (opt != current) AppSettings.instance.setFontScale(opt);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('A', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: fg)),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                sliderLabel(current),
                key: ValueKey(current),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: mutedFg),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, Color card, Color border, Color fg, Color mutedFg, bool isDark, AppLocale locale) {
    return Container(
      decoration: BoxDecoration(
        color: card.withValues(alpha: isDark ? 1.0 : 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: (isDark ? Colors.black : AppColors.primary).withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: ThemeModeOption.values.map((opt) {
          final selected = opt == AppSettings.instance.themeModeOption;
          IconData icon;
          switch (opt) {
            case ThemeModeOption.light:
              icon = Icons.wb_sunny_rounded;
              break;
            case ThemeModeOption.dark:
              icon = Icons.nights_stay_rounded;
              break;
            case ThemeModeOption.system:
              icon = Icons.phone_android_rounded;
              break;
          }
          return InkWell(
            onTap: () => AppSettings.instance.setThemeMode(opt),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: selected ? (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.15) : (isDark ? AppColors.darkMuted : AppColors.muted).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: selected ? (isDark ? AppColors.darkPrimary : AppColors.primary) : mutedFg),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opt.displayName(locale), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: selected ? (isDark ? AppColors.darkPrimary : AppColors.primary) : fg)),
                        Text(opt.description(locale), style: TextStyle(fontSize: 11, color: mutedFg)),
                      ],
                    ),
                  ),
                  if (selected) Icon(Icons.check_circle_rounded, color: isDark ? AppColors.darkPrimary : AppColors.primary, size: 22) else Icon(Icons.circle_outlined, color: mutedFg.withValues(alpha: 0.3), size: 22),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorBlindSelector(BuildContext context, Color card, Color border, Color fg, Color mutedFg, bool isDark, AppLocale locale) {
    final current = AppSettings.instance.colorBlindMode;
    return Container(
      decoration: BoxDecoration(
        color: card.withValues(alpha: isDark ? 1.0 : 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: (isDark ? Colors.black : AppColors.primary).withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: ColorBlindMode.values.map((mode) {
          final selected = mode == current;
          final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
          IconData icon;
          switch (mode) {
            case ColorBlindMode.normal:
              icon = Icons.visibility_rounded;
              break;
            case ColorBlindMode.deuteranopia:
              icon = Icons.filter_alt_rounded;
              break;
            case ColorBlindMode.protanopia:
              icon = Icons.invert_colors_rounded;
              break;
            case ColorBlindMode.tritanopia:
              icon = Icons.water_drop_rounded;
              break;
            case ColorBlindMode.highContrast:
              icon = Icons.contrast_rounded;
              break;
          }
          final dots = _dotsForMode(mode, isDark);
          return InkWell(
            onTap: () => AppSettings.instance.setColorBlindMode(mode),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: selected ? primary.withValues(alpha: 0.15) : (isDark ? AppColors.darkMuted : AppColors.muted).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: selected ? primary : mutedFg),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mode.displayName(locale), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: selected ? primary : fg)),
                        Text(mode.description(locale), style: TextStyle(fontSize: 11, color: mutedFg)),
                        const SizedBox(height: 6),
                        Row(
                          children: dots.map((c) => Container(width: 14, height: 14, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1), boxShadow: [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 4)]) )).toList(),
                        ),
                      ],
                    ),
                  ),
                  if (selected) Icon(Icons.check_circle_rounded, color: primary, size: 22) else Icon(Icons.circle_outlined, color: mutedFg.withValues(alpha: 0.3), size: 22),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Color> _dotsForMode(ColorBlindMode mode, bool isDark) {
    switch (mode) {
      case ColorBlindMode.deuteranopia:
      case ColorBlindMode.protanopia:
        return [const Color(0xFF0072B2), const Color(0xFFE69F00), const Color(0xFFD55E00)];
      case ColorBlindMode.tritanopia:
        return [const Color(0xFF009E73), const Color(0xFFCC79A7), const Color(0xFFD55E00)];
      case ColorBlindMode.highContrast:
        return isDark ? [const Color(0xFFFFFF00), const Color(0xFFFFD600), const Color(0xFFFF5252)] : [const Color(0xFF000000), const Color(0xFFB45309), const Color(0xFFB91C1C)];
      case ColorBlindMode.normal:
      default:
        return isDark ? [const Color(0xFF34D399), const Color(0xFFFBBF24), const Color(0xFFF87171)] : [const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFFEF4444)];
    }
  }

  Widget _buildAuras(BuildContext context, bool isDark) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final c1 = (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: isDark ? 0.06 : 0.08);
    final c2 = (isDark ? AppColors.darkSecondary : AppColors.secondary).withValues(alpha: 0.04);
    return Stack(
      children: [
        Positioned(top: -sw * 0.05, right: -sw * 0.1, child: _aura(175, c1)),
        Positioned(top: sh * 0.3, left: -sw * 0.2, child: _aura(150, c2)),
      ],
    );
  }

  Widget _aura(double size, Color color) => Container(
        width: size * 2,
        height: size * 2,
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: size, spreadRadius: size / 2)]),
      );
}

class _RingThumbShape extends SliderComponentShape {
  final Color ringColor;
  final double thumbRadius;
  const _RingThumbShape({required this.ringColor, this.thumbRadius = 10});
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.fromRadius(thumbRadius);
  @override
  void paint(PaintingContext context, Offset center, {required Animation<double> activationAnimation, required Animation<double> enableAnimation, required bool isDiscrete, required TextPainter labelPainter, required RenderBox parentBox, required SliderThemeData sliderTheme, required TextDirection textDirection, required double value, required double textScaleFactor, required Size sizeWithOverflow}) {
    final Canvas canvas = context.canvas;
    final fillPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = ringColor..style = PaintingStyle.stroke..strokeWidth = 3;
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, thumbRadius, shadowPaint);
    canvas.drawCircle(center, thumbRadius, fillPaint);
    canvas.drawCircle(center, thumbRadius, borderPaint);
    canvas.drawCircle(center, thumbRadius - 5, Paint()..color = ringColor.withValues(alpha: 0.15)..style = PaintingStyle.fill);
  }
}
