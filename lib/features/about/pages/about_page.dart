import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/url_utils.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          _buildScatteredAuras(screenWidth, screenHeight, isDark),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ResponsiveCenter(
                  maxWidth: 720,
                  child: _buildHeaderContent(context, isDark),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: ResponsiveCenter(
                      maxWidth: 720,
                      child: Column(
                        children: [
                          _buildInfoCard(
                            icon: Icons.info_outline_rounded,
                            title: context.tr('aboutWhatIsTitle'),
                            isDark: isDark,
                            child: Text(
                              context.tr('aboutWhatIsDesc'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkForeground
                                    : AppColors.foreground,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildInfoCard(
                            icon: Icons.gps_fixed_rounded,
                            title: context.tr('aboutPurposeTitle'),
                            isDark: isDark,
                            child: Column(
                              children: [
                                _buildCheckItem(
                                  context.tr('aboutPurpose1'),
                                  isDark,
                                ),
                                const SizedBox(height: 10),
                                _buildCheckItem(
                                  context.tr('aboutPurpose2'),
                                  isDark,
                                ),
                                const SizedBox(height: 10),
                                _buildCheckItem(
                                  context.tr('aboutPurpose3'),
                                  isDark,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildInfoCard(
                            icon: Icons.list_alt_rounded,
                            title: context.tr('aboutHowTitle'),
                            isDark: isDark,
                            child: _buildTimeline(context, isDark),
                          ),
                          const SizedBox(height: 14),
                          _buildDisclaimerCard(isDark, context),
                          const SizedBox(height: 14),
                          _buildInfoCard(
                            icon: Icons.monitor_heart_outlined,
                            title: context.tr('aboutTbTitle'),
                            isDark: isDark,
                            child: Text(
                              context.tr('aboutTbDesc'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkForeground
                                    : AppColors.foreground,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildReferenceCard(isDark, context),
                          const SizedBox(height: 14),
                          _buildDeveloperSection(isDark, context),
                          const SizedBox(height: 20),
                          _buildFooter(isDark, context),
                          const SizedBox(height: 24),
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
  }

  Widget _buildHeaderContent(BuildContext context, bool isDark) {
    return AboutPageHeader(isDark: isDark);
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget child,
    required bool isDark,
  }) {
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card.withValues(alpha: isDark ? 1.0 : 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.white),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.1),
                ),
                child: Icon(icon, size: 18, color: primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text, bool isDark) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.1),
          ),
          child: Icon(Icons.check, size: 10, color: primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: fg,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(BuildContext context, bool isDark) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final steps = [
      context.tr('aboutHow1'),
      context.tr('aboutHow2'),
      context.tr('aboutHow3'),
    ];
    return Column(
      children: List.generate(
        steps.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index < steps.length - 1 ? 12 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      border: Border.all(color: primary, width: 1.6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Container(
                      width: 1,
                      height: 16,
                      color: primary.withValues(alpha: 0.2),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: fg,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimerCard(bool isDark, BuildContext context) {
    final warning = isDark ? AppColors.darkWarning : AppColors.warning;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: warning.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: warning.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: warning.withValues(alpha: 0.2),
                ),
                child: Icon(Icons.shield_outlined, size: 18, color: warning),
              ),
              const SizedBox(width: 10),
              Text(
                context.tr('aboutDisclaimerTitle'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('aboutDisclaimerDesc'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: fg,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard(bool isDark, BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedFg = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.menu_book_rounded, size: 18, color: primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('aboutReferenceTitle'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkSurface : Colors.white).withValues(
                alpha: 0.9,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('aboutReferenceName'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: fg,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('aboutReferenceAuthors'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: mutedFg,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('aboutReferenceSource'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: mutedFg),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.tr('aboutReferenceDesc'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: mutedFg,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperSection(bool isDark, BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedFg = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    const devs = [
      (
        'aboutDev1Name',
        'https://www.linkedin.com/in/rizal-maulana-airlangga-072b21346/',
      ),
      (
        'aboutDev2Name',
        'https://www.linkedin.com/in/irwin-wiryawan-2214a6436/',
      ),
      (
        'aboutDev3Name',
        'https://www.linkedin.com/in/nabeel-prakasa-979456304/',
      ),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : Colors.white).withValues(
          alpha: isDark ? 1.0 : 0.88,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.white),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.1),
                ),
                child: Icon(Icons.code_rounded, size: 18, color: primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('aboutDeveloperTitle'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    Text(
                      context.tr('aboutDeveloperSubtitle'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: mutedFg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                Icon(Icons.ads_click_rounded, size: 14, color: primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.tr('aboutDeveloperHint'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ResponsiveGrid(
            spacing: 10,
            runSpacing: 10,
            children: devs
                .map(
                  (e) => _buildDeveloperNameCard(
                    name: context.tr(e.$1),
                    url: e.$2,
                    isDark: isDark,
                    context: context,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperNameCard({
    required String name,
    required String url,
    required bool isDark,
    required BuildContext context,
  }) {
    final card = isDark ? AppColors.darkSurfaceAlt : Colors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedFg = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => UrlUtils.launchLinkedIn(context, url),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: card.withValues(alpha: isDark ? 1.0 : 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primary.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person_rounded, size: 18, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, size: 14, color: mutedFg),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: fg,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.open_in_new_rounded,
                  size: 14,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark, BuildContext context) {
    final mutedFg = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : Colors.white,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/images/img_logo_app.png',
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) =>
                  Icon(Icons.shield_outlined, color: primary, size: 36),
            ),
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.data?.version ?? '';
            final versionLabel = version.isEmpty
                ? context.tr('version')
                : '${context.tr('version')} $version';
            return Text(
              '$versionLabel • ${context.tr('aboutFooter')}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: mutedFg,
                height: 1.5,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildScatteredAuras(double sw, double sh, bool isDark) => Stack(
    children: [
      Positioned(
        top: -sh * 0.05,
        right: -sw * 0.1,
        child: _buildAura(
          140,
          (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(
            alpha: 0.1,
          ),
        ),
      ),
      Positioned(
        top: sh * 0.4,
        left: -sw * 0.2,
        child: _buildAura(
          120,
          (isDark ? AppColors.darkSecondary : AppColors.secondary).withValues(
            alpha: 0.05,
          ),
        ),
      ),
      Positioned(
        bottom: sh * 0.1,
        right: -sw * 0.1,
        child: _buildAura(
          100,
          (isDark ? AppColors.darkAccent : AppColors.accent).withValues(
            alpha: 0.05,
          ),
        ),
      ),
    ],
  );
  Widget _buildAura(double size, Color color) => Container(
    width: size * 2,
    height: size * 2,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: color, blurRadius: size, spreadRadius: size / 2),
      ],
    ),
  );
}

class AboutPageHeader extends StatelessWidget {
  final bool isDark;

  const AboutPageHeader({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedFg = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final isCompact =
        MediaQuery.orientationOf(context) == Orientation.landscape &&
        MediaQuery.sizeOf(context).height < 500;
    final buttonSize = isCompact ? 34.0 : 40.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 20,
        vertical: isCompact ? 8 : 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: card.withValues(alpha: isDark ? 0.9 : 0.75),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : Colors.white,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back,
                color: fg,
                size: isCompact ? 18 : 20,
              ),
            ),
          ),
          SizedBox(width: isCompact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('aboutTitle'),
                  style: TextStyle(
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.w800,
                    color: fg,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('aboutSubtitle'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: mutedFg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
