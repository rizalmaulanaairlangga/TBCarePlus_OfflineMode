import 'package:flutter/material.dart';

/// Screen size breakpoints following Material 3 guidelines.
class Breakpoints {
  static const double compact = 600; // Handset portrait (<600)
  static const double medium =
      840; // Small tablet, handset landscape (600..839)
  static const double expanded = 1200; // Large tablet, desktop (>=840)
}

/// Helper context extensions for responsive queries
extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  Orientation get orientation => MediaQuery.orientationOf(this);
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;

  /// True if device is a phone in landscape orientation (short vertical viewport: height < 500dp)
  bool get isLandscapePhone => isLandscape && screenHeight < 500;

  /// True if device is a tablet in landscape orientation (large viewport: height >= 500dp and width >= 600dp)
  bool get isLandscapeTablet =>
      isLandscape && screenHeight >= 500 && screenWidth >= Breakpoints.compact;

  /// True if width >= 600dp (tablet portrait/landscape or phone landscape)
  bool get isTabletOrWide => screenWidth >= Breakpoints.compact;

  /// True if width >= 840dp (large tablet or desktop)
  bool get isLargeScreen => screenWidth >= Breakpoints.medium;

  /// Optimal horizontal content padding depending on width
  EdgeInsets get responsiveHorizontalPadding {
    if (screenWidth >= Breakpoints.medium) {
      return const EdgeInsets.symmetric(horizontal: 24);
    }
    if (screenWidth >= Breakpoints.compact) {
      return const EdgeInsets.symmetric(horizontal: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 16);
  }
}

/// Wraps content in a centered ConstrainedBox so it stays neat on tablet/landscape/desktop.
/// - In landscape/tablet, content is centered with appropriate maxWidth.
/// - In phone portrait, content expands naturally with given padding.
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
    final w = MediaQuery.sizeOf(context).width;
    final isWide = w >= Breakpoints.compact;

    if (!isWide) {
      if (padding == null) return child;
      return Padding(padding: padding!, child: child);
    }

    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1.0,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}

/// Helper responsive grid that adapts column count automatically:
/// 1 column on phone portrait (<600dp)
/// 2 columns on tablet/landscape (>=600dp)
/// 3 columns on large desktop/screens (>=1000dp, optional)
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int minColumns;
  final int maxColumns;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 10,
    this.runSpacing = 10,
    this.minColumns = 1,
    this.maxColumns = 2,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    int cols = minColumns;
    if (width >= Breakpoints.medium) {
      cols = maxColumns;
    } else if (width >= Breakpoints.compact || isLandscape) {
      cols = 2.clamp(minColumns, maxColumns);
    }

    if (cols <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: runSpacing),
          ],
        ],
      );
    }

    // Multi-column row chunks
    final List<Widget> rows = [];
    for (int i = 0; i < children.length; i += cols) {
      final chunk = children.sublist(
        i,
        (i + cols > children.length) ? children.length : i + cols,
      );
      final row = Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          for (int j = 0; j < chunk.length; j++) ...[
            Expanded(child: chunk[j]),
            if (j < chunk.length - 1) SizedBox(width: spacing),
          ],
          if (chunk.length < cols)
            for (int k = 0; k < (cols - chunk.length); k++) ...[
              SizedBox(width: spacing),
              const Expanded(child: SizedBox.shrink()),
            ],
        ],
      );
      rows.add(
        crossAxisAlignment == CrossAxisAlignment.stretch
            ? IntrinsicHeight(child: row)
            : row,
      );
      if (i + cols < children.length) {
        rows.add(SizedBox(height: runSpacing));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}

/// Helper for scrollable content: returns SingleChildScrollView centered.
Widget responsiveScroll(
  BuildContext context,
  Widget child, {
  double maxWidth = 720,
  EdgeInsetsGeometry? outerPadding,
}) {
  return ResponsiveCenter(
    maxWidth: maxWidth,
    padding: outerPadding,
    child: child,
  );
}

bool isTabletSize(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= Breakpoints.compact;

bool isLargeTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= Breakpoints.medium;
