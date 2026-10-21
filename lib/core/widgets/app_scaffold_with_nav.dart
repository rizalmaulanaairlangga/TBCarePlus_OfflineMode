import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_bottom_nav.dart';
import 'responsive_center.dart';

/// Wraps page content with adaptive layout:
/// - In portrait or on tablets/desktops: standard bottom navigation bar (if [currentIndex] != null).
/// - In landscape phone mode: compact left navigation rail ([AppNavRail]), allowing full vertical
///   screen height for scrollable content, while avoiding the horizontal bottom bar intrusion.
class AppScaffoldWithNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavTap;
  final Widget child;
  final Widget? background;
  final Color? backgroundColor;

  const AppScaffoldWithNav({
    super.key,
    required this.currentIndex,
    required this.onNavTap,
    required this.child,
    this.background,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? AppColors.darkBackground : AppColors.background);
    final isLandscapePhone = context.isLandscapePhone;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          ?background,
          if (isLandscapePhone)
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppNavRail(
                  currentIndex: currentIndex,
                  onTap: onNavTap,
                ),
                Expanded(
                  child: child,
                ),
              ],
            )
          else
            child,
        ],
      ),
      bottomNavigationBar: isLandscapePhone
          ? null
          : AppBottomNav(
              currentIndex: currentIndex,
              onTap: onNavTap,
            ),
    );
  }
}
