import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_compact_branch_sheet_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrazilMapCompactBranchSheetLayout', () {
    test('returns false when store detail is hidden', () {
      expect(
        BrazilMapCompactBranchSheetLayout.shouldUse(
          showStoreDetail: false,
          maxWidth: AppBreakpoints.mobile - 1,
        ),
        isFalse,
      );
    });

    test('returns false on desktop-width layouts', () {
      expect(
        BrazilMapCompactBranchSheetLayout.shouldUse(
          showStoreDetail: true,
          maxWidth: AppBreakpoints.mobile,
        ),
        isFalse,
      );
    });

    test('returns true on narrow widths when store detail is enabled', () {
      expect(
        BrazilMapCompactBranchSheetLayout.shouldUse(
          showStoreDetail: true,
          maxWidth: AppBreakpoints.mobile - 1,
        ),
        isTrue,
      );
    });
  });
}
