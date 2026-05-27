import 'package:flutter/material.dart';

abstract final class AppBreakpoints {
  /// Upper bound (exclusive) for compact / single-column layouts.
  static const double mobile = 600;

  /// Lower bound for layouts below [desktop] (non-rail shell). Currently
  /// identical to [mobile] because the app does not use a distinct tablet tier.
  static const double tablet = mobile;

  /// Minimum width for persistent sidebar rail (shell + content constraint).
  static const double desktop = 1200;

  static const double pageContentMaxWidth = 960;

  /// KPI grid switches from 2 to 3 columns at or above this width.
  static const double kpiGridWide = 720;

  /// KPI grid switches from 3 to 5 columns at or above this width.
  static const double kpiGridExtraWide = 960;

  /// Hides a report column when grid width is below this (very narrow layouts).
  static const double reportColumnHideExtraNarrow = 360;

  /// Hides a report column when grid width is below this (typical phone).
  static const double reportColumnHideNarrow = 480;

  /// Hides a report column when grid width is below this (large phones / small tablets).
  static const double reportColumnHideMedium = 540;

  /// Hides a column when grid width is below [mobile] (compact layouts).
  static const double reportColumnHideWide = mobile;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  /// Tablet tier: width from [tablet] up to (but not including) [desktop].
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= tablet && w < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  /// Fixed shell navigation (sidebar rail): **only desktop** — hidden on phone
  /// and tablet. Non-desktop uses [Scaffold.drawer] (menu behind hamburger).
  ///
  /// Threshold: [desktop] (>= 1200 logical px). See [isDesktop].
  static bool useRail(BuildContext context) => isDesktop(context);

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;
}
