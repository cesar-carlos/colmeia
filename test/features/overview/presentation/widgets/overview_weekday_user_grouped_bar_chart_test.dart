import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_user_grouped_bar_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/weekday_user_grouped_chart_data.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'renders external legend chips outside any horizontal scroll view',
    (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final points = <OverviewWeekdayUserSalesTrendPoint>[
        for (var u = 1; u <= 6; u++)
          for (final weekday in const <int>[2, 3, 4, 5, 6, 7, 1])
            OverviewWeekdayUserSalesTrendPoint(
              weekdayNumber: weekday,
              userName: 'User $u',
              salesCount: u * weekday,
              salesAmount: (u * weekday * 25).toDouble(),
            ),
      ];

      await tester.pumpWidget(
        _TestApp(
          child: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              final tokens = Theme.of(context).extension<AppThemeTokens>()!;
              return OverviewWeekdayUserGroupedBarChart(
                l10n: l10n,
                model: buildWeekdayUserGroupedChartModel(
                  points: points,
                  l10n: l10n,
                  useSalesCount: true,
                ),
                isSalesCount: true,
                title: 'Sales by weekday and user',
                subtitle: 'Weekdays on the horizontal axis.',
                belowSubtitle: const SizedBox.shrink(),
                plotFloorAccessibilityNotice: '',
                extremeSpreadAccessibilityNotice: '',
                tokens: tokens,
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      for (var u = 1; u <= 6; u++) {
        expect(find.text('User $u'), findsOneWidget);
      }

      for (var u = 1; u <= 6; u++) {
        final legendTextFinder = find.text('User $u');
        final ancestors = find.ancestor(
          of: legendTextFinder,
          matching: find.byType(ChartHorizontalScrollShell),
        );
        expect(
          ancestors,
          findsNothing,
          reason: 'Legend chip "User $u" must not live inside the scroll shell',
        );
      }

      expect(find.byType(ChartHorizontalScrollShell), findsOneWidget);
    },
  );

  testWidgets(
    'omits horizontal scroll wrapper when chart fits the available width',
    (tester) async {
      tester.view.physicalSize = const Size(1200 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final points = <OverviewWeekdayUserSalesTrendPoint>[
        const OverviewWeekdayUserSalesTrendPoint(
          weekdayNumber: 2,
          userName: 'Alice',
          salesCount: 4,
          salesAmount: 100,
        ),
        const OverviewWeekdayUserSalesTrendPoint(
          weekdayNumber: 3,
          userName: 'Alice',
          salesCount: 5,
          salesAmount: 150,
        ),
      ];

      await tester.pumpWidget(
        _TestApp(
          child: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              final tokens = Theme.of(context).extension<AppThemeTokens>()!;
              return OverviewWeekdayUserGroupedBarChart(
                l10n: l10n,
                model: buildWeekdayUserGroupedChartModel(
                  points: points,
                  l10n: l10n,
                  useSalesCount: true,
                ),
                isSalesCount: true,
                title: 'Sales by weekday and user',
                subtitle: 'Weekdays on the horizontal axis.',
                belowSubtitle: const SizedBox.shrink(),
                plotFloorAccessibilityNotice: '',
                extremeSpreadAccessibilityNotice: '',
                tokens: tokens,
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ChartHorizontalScrollShell), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
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
