import 'package:flutter/material.dart';

/// Wraps content in a centered ConstrainedBox so it stays tidy on tablet/desktop.
/// - Phone (<600dp): content expands full width with given horizontal padding.
/// - Tablet (>=600dp): content maxWidth 680dp (or 720 for large tablet) centered.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 600;
    // Use Align topCenter instead of Center to avoid infinite-height issues
    // inside SingleChildScrollView (Center tries to expand vertically).
    if (!isTablet) {
      // Phone: no maxWidth constraint, just apply padding
      if (padding == null) return child;
      return Padding(padding: padding!, child: child);
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

/// Helper for scrollable content: returns SingleChildScrollView centered.
Widget responsiveScroll(BuildContext context, Widget child, {double maxWidth = 720, EdgeInsetsGeometry? outerPadding}) {
  return ResponsiveCenter(
    maxWidth: maxWidth,
    padding: outerPadding,
    child: child,
  );
}

bool isTabletSize(BuildContext context) => MediaQuery.of(context).size.width >= 600;
bool isLargeTablet(BuildContext context) => MediaQuery.of(context).size.width >= 900;
