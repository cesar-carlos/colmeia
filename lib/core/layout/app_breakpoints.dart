import 'package:flutter/material.dart';

abstract final class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = mobile;
  static const double desktop = 1200;

  static const double pageContentMaxWidth = 960;

  /// Hides a report column when grid width is below this (very narrow layouts).
  static const double reportColumnHideExtraNarrow = 360;

  /// Hides a report column when grid width is below this (typical phone).
  static const double reportColumnHideNarrow = 480;

  /// Hides a report column when grid width is below this (large phones / small tablets).
  static const double reportColumnHideMedium = 540;

  /// Hides a column when grid width is below [mobile] (rail threshold).
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

  /// True on tablet or desktop (where the navigation rail is shown).
  static bool useRail(BuildContext context) =>
      isTablet(context) || isDesktop(context);

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;
}
