import 'package:colmeia/features/overview/presentation/localization/daily_sales_trend_chart_labels.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DailySalesTrendChartLabels overview vs sales copy', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final overview = DailySalesTrendChartLabels.resolve(
      l10n,
      salesBranchMonth: false,
    );
    final sales = DailySalesTrendChartLabels.resolve(
      l10n,
      salesBranchMonth: true,
    );

    expect(overview.subtitle, contains('aggregated across branches'));
    expect(sales.subtitle, contains('selected branch'));
    expect(sales.metricCountLabel, 'Sales');
    expect(sales.metricAmountLabel, 'Revenue');
    expect(sales.titleForMetric(isSalesCount: true), 'Daily sales');
    expect(sales.titleForMetric(isSalesCount: false), 'Daily revenue');
  });

  testWidgets('DailySalesTrendChartLabels resolveEmptyMessage uses overrides', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final sales = DailySalesTrendChartLabels.resolve(
      l10n,
      salesBranchMonth: true,
    );
    expect(
      sales.resolveEmptyMessage(loadFailed: false),
      isNotEmpty,
    );
    expect(
      sales.resolveEmptyMessage(
        loadFailed: true,
        loadFailureMessage: 'custom',
      ),
      'custom',
    );
  });
}
