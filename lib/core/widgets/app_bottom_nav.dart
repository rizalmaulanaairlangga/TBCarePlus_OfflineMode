import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'responsive_center.dart';
import '../l10n/l10n.dart';

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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : Colors.white, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: ResponsiveCenter(
        maxWidth: 480,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.home_rounded, context.tr('navHome'), 0),
            _buildNavItem(context, Icons.history_rounded, context.tr('navHistory'), 1),
            _buildNavItem(context, Icons.person_rounded, context.tr('navProfile'), 2),
          ],
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
    bool isActive = currentIndex == index;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    return GestureDetector(
      onTap: () { if (!isActive) onTap(index); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isActive ? primary.withValues(alpha: 0.12) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: isActive ? primary : mutedFg.withValues(alpha: 0.6), size: 22),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? primary : mutedFg.withValues(alpha: 0.6))),
        ]),
      ),
    );
  }
}
