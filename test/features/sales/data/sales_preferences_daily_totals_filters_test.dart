import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SalesPreferences daily totals date range', () {
    late SharedPreferences prefs;
    late SalesPreferences salesPrefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      salesPrefs = SalesPreferences(prefs);
    });

    test(
      'persistMonthlyPnlAnchor preserves persisted custom daily totals range',
      () async {
        final range = OverviewDateRange.fromOrderedEndpoints(
          DateTime(2026, 3, 2),
          DateTime(2026, 3, 18),
        );
        await salesPrefs.persistSalesDailyTotalsDateRange(
          useCustomRange: true,
          range: range,
        );
        await salesPrefs.persistMonthlyPnlAnchor(
          const OverviewYearMonth(year: 2026, month: 7),
        );

        expect(salesPrefs.restoreSalesDailyTotalsUseCustomRange(), isTrue);
        final restored = salesPrefs.restoreSalesDailyTotalsDateRange();
        expect(restored, isNotNull);
        expect(restored!.startInclusive, DateTime(2026, 3, 2));
        expect(restored.endInclusive, DateTime(2026, 3, 18));

        final anchor = salesPrefs.restoreMonthlyPnlAnchor();
        expect(anchor, const OverviewYearMonth(year: 2026, month: 7));
      },
    );

    test(
      'persistSalesDailyTotalsDateRange clear removes custom range keys',
      () async {
        await salesPrefs.persistSalesDailyTotalsDateRange(
          useCustomRange: true,
          range: OverviewDateRange.fromOrderedEndpoints(
            DateTime(2026, 1, 5),
            DateTime(2026, 1, 20),
          ),
        );
        await salesPrefs.persistSalesDailyTotalsDateRange(
          useCustomRange: false,
        );

        expect(salesPrefs.restoreSalesDailyTotalsUseCustomRange(), isFalse);
        expect(salesPrefs.restoreSalesDailyTotalsDateRange(), isNull);
      },
    );
  });
}
