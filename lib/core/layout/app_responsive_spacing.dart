import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Horizontal padding for scrollable shell pages, scaled by breakpoint.
extension AppResponsivePagePadding on BuildContext {
  double get pageHorizontalPadding {
    final tokens = Theme.of(this).extension<AppThemeTokens>()!;
    if (AppBreakpoints.isDesktop(this)) {
      return tokens.pagePaddingHorizontalSpacious;
    }
    if (AppBreakpoints.isTablet(this)) {
      return tokens.pagePaddingHorizontalComfortable;
    }
    return tokens.pagePaddingHorizontalCompact;
  }

  /// Vertical padding for primary page scroll bodies (uses contentSpacing).
  EdgeInsets pageScrollPadding(AppThemeTokens tokens) {
    return EdgeInsets.fromLTRB(
      pageHorizontalPadding,
      tokens.contentSpacing,
      pageHorizontalPadding,
      tokens.contentSpacing,
    );
  }
}
