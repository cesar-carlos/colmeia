import 'package:checks/checks.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';
import 'package:colmeia/features/overview/presentation/widgets/weekday_user_grouped_chart_data.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'buildWeekdayUserGroupedChartModel uses Monday-first axis and sorts series by total',
    () async {
      final l10n = AppLocalizationsEn();
      final points = <OverviewWeekdayUserSalesTrendPoint>[
        const OverviewWeekdayUserSalesTrendPoint(
          weekdayNumber: 2,
          userName: 'Alice',
          salesCount: 3,
          salesAmount: 100,
        ),
        const OverviewWeekdayUserSalesTrendPoint(
          weekdayNumber: 2,
          userName: 'Bob',
          salesCount: 5,
          salesAmount: 200,
        ),
        const OverviewWeekdayUserSalesTrendPoint(
          weekdayNumber: 4,
          userName: 'Alice',
          salesCount: 2,
          salesAmount: 50,
        ),
      ];

      final model = buildWeekdayUserGroupedChartModel(
        points: points,
        l10n: l10n,
        useSalesCount: true,
      );

      check(model.weekdayCategoryLabels).deepEquals(<String>[
        l10n.overviewDailySalesAxisDowMon,
        l10n.overviewDailySalesAxisDowWed,
      ]);
      check(model.combinedRemainingUsers).isFalse();

      check(model.userNames).deepEquals(<String>['Alice', 'Bob']);
      check(model.seriesData).length.equals(2);
      const mondayIdx = 0;
      const wednesdayIdx = 1;
      final alice = model.seriesData[0];
      final bob = model.seriesData[1];
      check(alice[mondayIdx].salesCount).equals(3);
      check(bob[mondayIdx].salesCount).equals(5);
      check(alice[mondayIdx].value).equals(3);
      check(bob[mondayIdx].value).equals(5);
      check(alice[wednesdayIdx].salesCount).equals(2);
      check(bob[wednesdayIdx].salesCount).equals(0);
    },
  );

  test(
    'buildWeekdayUserGroupedChartModel merges overflow users into Others',
    () async {
      final l10n = AppLocalizationsEn();
      final points = <OverviewWeekdayUserSalesTrendPoint>[
        for (var i = 1; i <= 9; i++)
          OverviewWeekdayUserSalesTrendPoint(
            weekdayNumber: 2,
            userName: 'U$i',
            salesCount: i,
            salesAmount: (i * 10).toDouble(),
          ),
      ];

      final model = buildWeekdayUserGroupedChartModel(
        points: points,
        l10n: l10n,
        useSalesCount: true,
      );

      check(model.combinedRemainingUsers).isTrue();
      check(model.userNames.length).equals(kWeekdayUserGroupedMaxSeries);
      check(
        model.userNames.last,
      ).equals(l10n.overviewWeekdayUserGroupedOthersLabel);

      check(model.weekdayCategoryLabels).length.equals(1);
      check(
        model.weekdayCategoryLabels.single,
      ).equals(l10n.overviewDailySalesAxisDowMon);
      const mondayIdx = 0;
      final others = model.seriesData.last;
      check(others[mondayIdx].salesCount).equals(3);
      check(others[mondayIdx].value).equals(3);
    },
  );

  test('weekdayUserGroupedCategories maps model rows to category adapters', () {
    const model = WeekdayUserGroupedChartModel(
      userNames: <String>['Alice', 'Bob'],
      weekdayCategoryLabels: <String>['Mon', 'Wed'],
      seriesData: <List<WeekdayUserGroupedBarDatum>>[
        <WeekdayUserGroupedBarDatum>[
          WeekdayUserGroupedBarDatum(
            weekdayCategoryLabel: 'Mon',
            value: 3,
            plottedY: 3,
            salesCount: 3,
            salesAmount: 100,
          ),
          WeekdayUserGroupedBarDatum(
            weekdayCategoryLabel: 'Wed',
            value: 2,
            plottedY: 2,
            salesCount: 2,
            salesAmount: 50,
          ),
        ],
        <WeekdayUserGroupedBarDatum>[
          WeekdayUserGroupedBarDatum(
            weekdayCategoryLabel: 'Mon',
            value: 5,
            plottedY: 5,
            salesCount: 5,
            salesAmount: 200,
          ),
          WeekdayUserGroupedBarDatum(
            weekdayCategoryLabel: 'Wed',
            value: 0,
            plottedY: 0,
            salesCount: 0,
            salesAmount: 0,
          ),
        ],
      ],
    );

    final categories = weekdayUserGroupedCategories(model);

    check(categories).length.equals(2);
    check(categories[0].label).equals('Mon');
    check(categories[0].cells).length.equals(2);
    check(categories[0].cells[0].salesCount).equals(3);
    check(categories[1].cells[1].salesCount).equals(0);
  });
}
