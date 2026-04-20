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

    final sundayZero = <OverviewWeekdaySalesTrendPoint>[
      const OverviewWeekdaySalesTrendPoint(
        weekdayNumber: 1,
        salesCount: 0,
        salesAmount: 0,
      ),
      ...points.skip(1),
    ];
    await tester.pumpWidget(
      _TestApp(
        child: Builder(
          builder: (context) {
            return OverviewWeekdaySalesTrendChart(
              l10n: AppLocalizations.of(context),
              points: sundayZero,
              loadFailed: false,
            );
          },
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    final chartNoSunday = tester
        .widget<AppComparisonBarChart<OverviewWeekdaySalesTrendPoint>>(
          chartFinder,
        );
    expect(chartNoSunday.items, hasLength(6));
    expect(
      chartNoSunday.items.any((p) => p.weekdayNumber == 1),
      isFalse,
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

    final chartRestored = tester
        .widget<AppComparisonBarChart<OverviewWeekdaySalesTrendPoint>>(
          chartFinder,
        );
    expect(
      find.byWidgetPredicate((widget) => widget is AppSegmentedControl),
      findsOneWidget,
    );
    expect(
      chartRestored.tooltipLabelBuilder!(points[1], points[1].salesCount),
      contains(r'R$'),
    );
    expect(chartRestored.style.minBarWidth, 92);
    expect(
      chartRestored.style.animationDuration,
      const Duration(milliseconds: 350),
    );
    expect(chartRestored.style.yAxisFormat!.format(1500), isNot(contains(r'R$')));

    await tester.tap(find.text('Revenue'));
    await tester.pumpAndSettle();

    final revenueChart = tester
        .widget<AppComparisonBarChart<OverviewWeekdaySalesTrendPoint>>(
          chartFinder,
        );
    expect(revenueChart.title, 'Revenue by weekday');
    expect(revenueChart.style.yAxisFormat!.format(1500), contains(r'R$'));
  });

  testWidgets('revenue mode omits weekday when amount is zero', (tester) async {
    final points = <OverviewWeekdaySalesTrendPoint>[
      const OverviewWeekdaySalesTrendPoint(
        weekdayNumber: 1,
        salesCount: 10,
        salesAmount: 0,
      ),
      for (var i = 2; i <= 7; i++)
        OverviewWeekdaySalesTrendPoint(
          weekdayNumber: i,
          salesCount: i,
          salesAmount: i * 100.0,
        ),
    ];

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

    await tester.tap(find.text('Revenue'));
    await tester.pumpAndSettle();

    final chartFinder = find.byWidgetPredicate(
      (widget) =>
          widget is AppComparisonBarChart<OverviewWeekdaySalesTrendPoint>,
    );
    final revenueChart = tester
        .widget<AppComparisonBarChart<OverviewWeekdaySalesTrendPoint>>(
          chartFinder,
        );
    expect(revenueChart.items, hasLength(6));
    expect(
      revenueChart.items.any((p) => p.weekdayNumber == 1),
      isFalse,
    );
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

  testWidgets(
    'renders specific loadFailureMessage when set '
    '(BUG #4: chart shows actionable AppFailure.userMessage)',
    (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: Builder(
            builder: (context) {
              return OverviewWeekdaySalesTrendChart(
                l10n: AppLocalizations.of(context),
                points: const <OverviewWeekdaySalesTrendPoint>[],
                loadFailed: true,
                loadFailureMessage: 'Voce nao tem acesso a este agente.',
              );
            },
          ),
        ),
      );

      expect(
        find.text('Voce nao tem acesso a este agente.'),
        findsOneWidget,
      );
      // Generic l10n fallback must NOT be on screen when the specific
      // message is provided.
      expect(
        find.text('Could not load the weekday chart. Try again later.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'falls back to generic l10n message when loadFailureMessage is null',
    (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: Builder(
            builder: (context) {
              // Default loadFailureMessage is null — that case must fall
              // back to the generic l10n label so the chart never shows a
              // blank placeholder when loadFailed is true.
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
    },
  );
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
