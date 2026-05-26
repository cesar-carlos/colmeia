import 'package:colmeia/features/sales/domain/sales_daily_totals_range_policy.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesDailyTotalsRangePolicy', () {
    test(
      'sales daily totals max span stays aligned with overview dashboard cap',
      () {
        expect(
          kSalesDailyTotalsMaxInclusiveDays,
          kDashboardCustomReferenceRangeMaxInclusiveDays,
        );
      },
    );
  });
}
