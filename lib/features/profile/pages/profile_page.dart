import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_scaffold_with_nav.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../routes/app_routes.dart';
import '../../../core/widgets/home_header.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/settings/app_settings.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        final sw = MediaQuery.of(context).size.width;
        final sh = MediaQuery.of(context).size.height;
        return AppScaffoldWithNav(
          currentIndex: 2,
          backgroundColor: bg,
          onNavTap: (i) {
            final routes = [AppRoutes.home, AppRoutes.history, AppRoutes.profile];
            if (i < routes.length) {
              Navigator.pushNamedAndRemoveUntil(context, routes[i], (route) => false);
            }
          },
          background: _buildScatteredAuras(sw, sh, isDark),
          child: SafeArea(
            child: Column(
              children: [
                const ResponsiveCenter(maxWidth: 720, child: HomeHeader(isGuest: false, showProfile: false)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: ResponsiveCenter(
                      maxWidth: 720,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAppInfoCard(isDark),
                          const SizedBox(height: 16),
                          ResponsiveGrid(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildMenuItem(
                                context,
                                icon: Icons.settings_outlined,
                                label: context.tr('profileSettings'),
                                subtitle: '${context.tr('settingsLanguage')} • ${context.tr('settingsFontSize')} • ${context.tr('settingsTheme')} • ${context.tr('settingsColorBlind')}',
                                onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                                isDark: isDark,
                              ),
                              _buildMenuItem(
                                context,
                                icon: Icons.info_outline_rounded,
                                label: context.tr('profileAbout'),
                                subtitle: context.tr('aboutSubtitle'),
                                onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppInfoCard(bool isDark) {
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card.withValues(alpha: isDark ? 1.0 : 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceAlt : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Center(
              child: Image.asset('assets/images/img_logo_app.png', width: 36, height: 36, fit: BoxFit.contain, errorBuilder: (_, _, _) => Icon(Icons.shield_outlined, color: primary, size: 26)),
            ),
          ),
          const SizedBox(height: 12),
          Text('TBCare+', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: fg)),
          const SizedBox(height: 4),
          Text(context.tr('profileAppDesc'), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: mutedFg, height: 1.4)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(100)),
            child: Text('${context.tr('profileOfflineMode')} • v1.3.2', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String label, String? subtitle, bool destructive = false, required VoidCallback onTap, required bool isDark}) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final color = destructive ? (isDark ? AppColors.darkDestructive : AppColors.destructive) : primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card.withValues(alpha: isDark ? 1.0 : 0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? AppColors.darkBorder : Colors.white),
          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1)), child: Icon(icon, size: 20, color: color)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: destructive ? color : fg, letterSpacing: -0.2)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: mutedFg.withValues(alpha: 0.8)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 20, color: mutedFg.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildScatteredAuras(double sw, double sh, bool isDark) => Stack(
        children: [
          Positioned(top: -sw * 0.05, right: -sw * 0.1, child: _buildAura(175, (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.1))),
          Positioned(top: sh * 0.3, left: -sw * 0.2, child: _buildAura(150, (isDark ? AppColors.darkSecondary : AppColors.secondary).withValues(alpha: 0.05))),
        ],
      );

  Widget _buildAura(double size, Color color) => Container(width: size * 2, height: size * 2, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: size, spreadRadius: size / 2)]));
}
