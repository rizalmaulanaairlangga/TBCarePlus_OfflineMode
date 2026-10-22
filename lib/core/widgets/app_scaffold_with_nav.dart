import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_bottom_nav.dart';
import 'responsive_center.dart';

/// Wraps page content with adaptive layout:
/// - In portrait and tablet layouts: standard bottom navigation.
/// - In short landscape windows: a compact left rail.
/// - On wide windows: an expanded left rail beside the page content.
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
    final bg =
        backgroundColor ??
        (isDark ? AppColors.darkBackground : AppColors.background);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideWindow = constraints.maxWidth >= Breakpoints.expanded;
        final isShortLandscape =
            constraints.maxWidth > constraints.maxHeight &&
            constraints.maxHeight < 500;
        final useRail = isWideWindow || isShortLandscape;

        return Scaffold(
          backgroundColor: bg,
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (background != null) Positioned.fill(child: background!),
              if (useRail)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppNavRail(
                      currentIndex: currentIndex,
                      onTap: onNavTap,
                      width: isWideWindow ? 224 : 112,
                      isExpanded: isWideWindow,
                    ),
                    Expanded(child: child),
                  ],
                )
              else
                child,
            ],
          ),
          bottomNavigationBar: useRail
              ? null
              : AppBottomNav(currentIndex: currentIndex, onTap: onNavTap),
        );
      },
    );
  }
}
