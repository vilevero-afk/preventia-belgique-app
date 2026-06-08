import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/adaptive_page.dart';

class PlatformCapabilities {
  const PlatformCapabilities._();

  static bool get isDesktopPlatform {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => true,
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => false,
    };
  }

  static bool get isMobilePlatform {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.fuchsia => false,
    };
  }

  static bool isMobileLayout(BuildContext context) {
    return LayoutBreakpoints.isMobile(context);
  }

  static bool isTabletLayout(BuildContext context) {
    return LayoutBreakpoints.isTablet(context);
  }

  static bool isDesktopLayout(BuildContext context) {
    return LayoutBreakpoints.isDesktop(context);
  }

  static String get pdfUnavailableMessage {
    if (isDesktopPlatform) {
      return 'Export PDF indisponible sur cet appareil. Exportez les documents séparément si le dialogue système ne s’ouvre pas.';
    }
    return 'Export PDF indisponible sur cet appareil.';
  }
}
