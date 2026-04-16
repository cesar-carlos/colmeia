import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_sales_trend_chart.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders weekday comparison chart with localized labels', (
    tester,
  ) async {
    final points = List<OverviewWeekdaySalesTrendPoint>.generate(
      7,
      (index) => OverviewWeekdaySalesTrendPoint(
        weekdayNumber: index + 1,
        salesCount: index + 1,
        salesAmount: (index + 1) * 10,
      ),
      growable: false,
    );

    await tester.pumpWidget(
      _TestApp(
        child: Builder(
          builder: (context) {
            return OverviewWeekdaySalesTrendChart(
              l10n: AppLocalizations.of(context),
              points: points,
              loadFailed: false,
            );
          },
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    final chartFinder = find.byWidgetPredicate(
      (widget) =>
          widget is AppComparisonBarChart<OverviewWeekdaySalesTrendPoint>,
    );
    expect(chartFinder, findsOneWidget);
    final chart = tester
        .widget<AppComparisonBarChart<OverviewWeekdaySalesTrendPoint>>(
          chartFinder,
        );

    expect(chart.title, 'Sales by weekday');
    expect(
      chart.subtitle,
      'Weekday distribution in the selected period (all branches in scope).',
    );
    expect(chart.items, hasLength(7));
    expect(chart.labelBuilder(points.first), 'Sunday');
    expect(
      find.byWidgetPredicate((widget) => widget is AppSegmentedControl),
      findsOneWidget,
    );
    expect(
      chart.tooltipLabelBuilder!(points[1], points[1].salesCount),
      contains(r'R$'),
    );
    expect(chart.style.minBarWidth, 72);
    expect(chart.style.yAxisFormat!.format(1500), isNot(contains(r'R$')));

    await tester.tap(find.text('Revenue'));
    await tester.pumpAndSettle();

    final revenueChart = tester
        .widget<AppComparisonBarChart<OverviewWeekdaySalesTrendPoint>>(
          chartFinder,
        );
    expect(revenueChart.title, 'Revenue by weekday');
    expect(revenueChart.style.yAxisFormat!.format(1500), contains(r'R$'));
  });

  testWidgets('renders empty placeholder', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: Builder(
          builder: (context) {
            return OverviewWeekdaySalesTrendChart(
              l10n: AppLocalizations.of(context),
              points: const <OverviewWeekdaySalesTrendPoint>[],
              loadFailed: false,
            );
          },
        ),
      ),
    );

    expect(find.text('No weekday data for this period.'), findsOneWidget);
  });

  testWidgets('renders load failed placeholder', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: Builder(
          builder: (context) {
            return OverviewWeekdaySalesTrendChart(
              l10n: AppLocalizations.of(context),
              points: const <OverviewWeekdaySalesTrendPoint>[],
              loadFailed: true,
            );
          },
        ),
      ),
    );

    expect(
      find.text('Could not load the weekday chart. Try again later.'),
      findsOneWidget,
    );
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}
