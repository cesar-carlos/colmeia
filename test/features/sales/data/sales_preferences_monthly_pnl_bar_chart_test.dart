import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_percent_metric.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_bar_chart_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SalesPreferences monthly P&L bar chart', () {
    late SharedPreferences prefs;
    late SalesPreferences salesPrefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      salesPrefs = SalesPreferences(prefs);
    });

    test(
      'restoreMonthlyPnlBarChartPreferences returns defaults when empty',
      () {
        expect(
          salesPrefs.restoreMonthlyPnlBarChartPreferences(),
          SalesMonthlyPnlBarChartPreferences.defaults,
        );
      },
    );

    test('persistMonthlyPnlBarChartPreferences round-trips', () async {
      const saved = SalesMonthlyPnlBarChartPreferences(
        displayMode: SalesMonthlyPnlBarDisplayMode.percent,
        percentMetric: LucratividadePercentMetric.markupOverCost,
      );
      await salesPrefs.persistMonthlyPnlBarChartPreferences(saved);
      expect(salesPrefs.restoreMonthlyPnlBarChartPreferences(), saved);
    });

    test('fromRaw maps legacy display values to amounts', () {
      final restored = SalesMonthlyPnlBarChartPreferences.fromRaw(
        const <String, Object?>{
          'display': 'values',
          'percent_metric': 'costOverRevenue',
        },
      );
      expect(restored.displayMode, SalesMonthlyPnlBarDisplayMode.amounts);
      expect(
        restored.percentMetric,
        LucratividadePercentMetric.costOverRevenue,
      );
    });
  });
}
