import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'responsive_center.dart';
import '../l10n/l10n.dart';

/// Navigation item model used by both bottom navigation bar and navigation rail
class AppNavItem {
  final IconData icon;
  final String labelKey;

  const AppNavItem({required this.icon, required this.labelKey});
}

const List<AppNavItem> kAppNavItems = [
  AppNavItem(icon: Icons.home_rounded, labelKey: 'navHome'),
  AppNavItem(icon: Icons.history_rounded, labelKey: 'navHistory'),
  AppNavItem(icon: Icons.person_rounded, labelKey: 'navProfile'),
];

/// Side navigation rail for short landscape and wide layouts.
class AppNavRail extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final double width;
  final bool isExpanded;

  const AppNavRail({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.width = 112,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final mutedFg = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    final visualScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(0.85, 1.5);

    return Container(
      width: width * visualScale,
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : Colors.white).withValues(
          alpha: 0.96,
        ),
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : Colors.white,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        right: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : 0,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8 * visualScale),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: isExpanded
                        ? CrossAxisAlignment.stretch
                        : CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36 * visualScale,
                        height: 36 * visualScale,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceAlt
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                (isDark ? AppColors.darkBorder : Colors.white)
                                    .withValues(alpha: 0.8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/img_logo_app.png',
                            width: 22 * visualScale,
                            height: 22 * visualScale,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.shield_outlined,
                              color: primary,
                              size: 16 * visualScale,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8 * visualScale),
                      for (int i = 0; i < kAppNavItems.length; i++) ...[
                        _buildRailItem(
                          context,
                          item: kAppNavItems[i],
                          index: i,
                          isDark: isDark,
                          primary: primary,
                          mutedFg: mutedFg,
                          visualScale: visualScale,
                        ),
                        if (i < kAppNavItems.length - 1)
                          SizedBox(height: 8 * visualScale),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRailItem(
    BuildContext context, {
    required AppNavItem item,
    required int index,
    required bool isDark,
    required Color primary,
    required Color mutedFg,
    required double visualScale,
  }) {
    final bool isActive = currentIndex == index;
    final label = context.tr(item.labelKey);

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isActive) onTap(index);
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: (isExpanded ? 200 : 100) * visualScale,
            padding: EdgeInsets.symmetric(
              vertical: (isExpanded ? 8 : 6) * visualScale,
              horizontal: (isExpanded ? 12 : 4) * visualScale,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? primary.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: isExpanded
                ? Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 22 * visualScale,
                        color: isActive
                            ? primary
                            : mutedFg.withValues(alpha: 0.7),
                      ),
                      SizedBox(width: 12 * visualScale),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isActive
                                ? primary
                                : mutedFg.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 22 * visualScale,
                        color: isActive
                            ? primary
                            : mutedFg.withValues(alpha: 0.7),
                      ),
                      SizedBox(height: 3 * visualScale),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isActive
                              ? primary
                              : mutedFg.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Standard bottom navigation bar with adaptive landscape phone awareness
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // If in landscape rail mode, hide bottom navigation bar.
    final size = MediaQuery.sizeOf(context);
    final isRailMode =
        size.width >= Breakpoints.expanded ||
        (context.isLandscape && size.height < 500);
    if (isRailMode) {
      return const SizedBox.shrink();
    }

    return Hero(
      tag: 'bottom-nav-logged-in',
      flightShuttleBuilder:
          (flightContext, animation, direction, fromContext, toContext) =>
              toContext.widget,
      child: Material(
        type: MaterialType.transparency,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape = context.isLandscape;
    final bottomPad = isLandscape ? 8.0 : 20.0;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : Colors.white).withValues(
          alpha: 0.92,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : Colors.white,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: 520,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < kAppNavItems.length; i++)
                _buildNavItem(
                  context,
                  kAppNavItems[i].icon,
                  context.tr(kAppNavItems[i].labelKey),
                  i,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final bool isActive = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final mutedFg = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return GestureDetector(
      onTap: () {
        if (!isActive) onTap(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? primary : mutedFg.withValues(alpha: 0.6),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? primary : mutedFg.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
