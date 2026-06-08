import 'package:flutter/material.dart';

class LayoutBreakpoints {
  const LayoutBreakpoints._();

  static const double mobile = 700;
  static const double desktop = 1100;

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobile && width <= desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width > desktop;
  }

  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > desktop) {
      return 1100;
    }
    if (width >= mobile) {
      return 900;
    }
    return double.infinity;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > desktop) {
      return const EdgeInsets.all(24);
    }
    if (width >= mobile) {
      return const EdgeInsets.all(20);
    }
    return const EdgeInsets.all(16);
  }
}

class AdaptivePage extends StatelessWidget {
  const AdaptivePage({
    required this.child,
    this.mobilePadding = const EdgeInsets.all(16),
    this.maxTabletWidth = 900,
    this.maxDesktopWidth = 1100,
    this.centerVertically = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry mobilePadding;
  final double maxTabletWidth;
  final double maxDesktopWidth;
  final bool centerVertically;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final adaptiveMaxWidth = width > LayoutBreakpoints.desktop
        ? maxDesktopWidth
        : width >= LayoutBreakpoints.mobile
        ? maxTabletWidth
        : double.infinity;
    final maxWidth = adaptiveMaxWidth == double.infinity
        ? double.infinity
        : adaptiveMaxWidth;
    final padding = mobilePadding == const EdgeInsets.all(16)
        ? LayoutBreakpoints.pagePadding(context)
        : mobilePadding;

    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );

    if (!centerVertically) {
      return content;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: Center(child: content)),
          ),
        );
      },
    );
  }
}
