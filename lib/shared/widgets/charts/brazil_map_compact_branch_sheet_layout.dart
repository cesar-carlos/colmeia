import 'package:colmeia/core/layout/app_breakpoints.dart';

/// Pure layout policy for the compact branch detail bottom sheet on narrow widths.
abstract final class BrazilMapCompactBranchSheetLayout {
  static bool shouldUse({
    required bool showStoreDetail,
    required double maxWidth,
  }) {
    return showStoreDetail && maxWidth < AppBreakpoints.mobile;
  }
}
