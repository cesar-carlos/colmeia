import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

abstract final class AppPageSpacingPresets {
  const AppPageSpacingPresets._();

  /// Slightly widens the content rail to match dense dashboard pages.
  static const double dashboardHorizontalAdjustment = -6;
}

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
  ///
  /// [horizontalAdjustment] is added to the breakpoint-based horizontal inset
  /// (negative values widen content toward the screen edges). Clamped to a
  /// reasonable range so padding never inverts or becomes excessive.
  EdgeInsets pageScrollPadding(
    AppThemeTokens tokens, {
    double horizontalAdjustment = 0,
  }) {
    final h = (pageHorizontalPadding + horizontalAdjustment).clamp(8.0, 56.0);
    return EdgeInsets.fromLTRB(
      h,
      tokens.contentSpacing,
      h,
      tokens.contentSpacing,
    );
  }
}
