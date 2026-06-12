import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/daily_sales_trend_chart.dart';
import 'package:colmeia/shared/widgets/charts/daily_sales_trend_point.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  testWidgets('MetricToggleComparisonBarCard mounts via DailySalesTrendChart', (
    tester,
  ) async {
    await tester.pumpWidget(
      LocalizedTestApp(
        child: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return DailySalesTrendChart(
              l10n: l10n,
              points: <DailySalesTrendPoint>[
                DailySalesTrendPoint(
                  saleDate: DateTime(2025, 6),
                  salesCount: 12,
                  salesAmount: 1500,
                ),
                DailySalesTrendPoint(
                  saleDate: DateTime(2025, 6, 2),
                  salesCount: 8,
                  salesAmount: 980,
                ),
              ],
              emptyMessage: 'Sem vendas no período.',
            );
          },
        ),
      ),
    );

    expect(find.byType(DailySalesTrendChart), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });
}
