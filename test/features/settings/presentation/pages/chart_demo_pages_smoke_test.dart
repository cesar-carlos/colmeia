import 'package:colmeia/features/settings/presentation/pages/app_area_trend_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_brazil_store_sales_map_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_bullet_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_category_donut_card_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_combo_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_comparison_bar_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_distribution_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_funnel_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_gauge_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_heatmap_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_polar_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_pyramid_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_radar_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_radial_bar_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_range_area_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_scatter_bubble_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_sparkline_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_stacked_bar_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_step_line_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_sunburst_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_time_series_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_treemap_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_waterfall_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/horizontal_progress_chart_demo_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';

void main() {
  const pumpDuration = Duration(milliseconds: 300);

  final chartDemos = <({Widget page, Type pageType, String title})>[
    (
      page: const AppComparisonBarChartDemoPage(),
      pageType: AppComparisonBarChartDemoPage,
      title: 'AppComparisonBarChart',
    ),
    (
      page: const AppComboChartDemoPage(),
      pageType: AppComboChartDemoPage,
      title: 'AppComboChart',
    ),
    (
      page: const AppRadarChartDemoPage(),
      pageType: AppRadarChartDemoPage,
      title: 'AppRadarChart',
    ),
    (
      page: const AppFunnelChartDemoPage(),
      pageType: AppFunnelChartDemoPage,
      title: 'AppFunnelChart',
    ),
    (
      page: const AppGaugeChartDemoPage(),
      pageType: AppGaugeChartDemoPage,
      title: 'AppGaugeChart',
    ),
    (
      page: const AppAreaTrendChartDemoPage(),
      pageType: AppAreaTrendChartDemoPage,
      title: 'AppAreaTrendChart',
    ),
    (
      page: const AppStackedBarChartDemoPage(),
      pageType: AppStackedBarChartDemoPage,
      title: 'AppStackedBarChart',
    ),
    (
      page: const AppWaterfallChartDemoPage(),
      pageType: AppWaterfallChartDemoPage,
      title: 'AppWaterfallChart',
    ),
    (
      page: const AppBulletChartDemoPage(),
      pageType: AppBulletChartDemoPage,
      title: 'AppBulletChart',
    ),
    (
      page: const AppHeatmapChartDemoPage(),
      pageType: AppHeatmapChartDemoPage,
      title: 'AppHeatmapChart',
    ),
    (
      page: const AppScatterBubbleChartDemoPage(),
      pageType: AppScatterBubbleChartDemoPage,
      title: 'AppScatterBubbleChart',
    ),
    (
      page: const AppTimeSeriesChartDemoPage(),
      pageType: AppTimeSeriesChartDemoPage,
      title: 'AppTimeSeriesChart',
    ),
    (
      page: const AppTreemapChartDemoPage(),
      pageType: AppTreemapChartDemoPage,
      title: 'AppTreemapChart',
    ),
    (
      page: const AppPolarChartDemoPage(),
      pageType: AppPolarChartDemoPage,
      title: 'AppPolarChart',
    ),
    (
      page: const AppSunburstChartDemoPage(),
      pageType: AppSunburstChartDemoPage,
      title: 'AppSunburstChart',
    ),
    (
      page: const AppRadialBarChartDemoPage(),
      pageType: AppRadialBarChartDemoPage,
      title: 'AppRadialBarChart',
    ),
    (
      page: const AppPyramidChartDemoPage(),
      pageType: AppPyramidChartDemoPage,
      title: 'AppPyramidChart',
    ),
    (
      page: const AppSparklineChartDemoPage(),
      pageType: AppSparklineChartDemoPage,
      title: 'AppSparklineChart',
    ),
    (
      page: const AppDistributionChartDemoPage(),
      pageType: AppDistributionChartDemoPage,
      title: 'AppDistributionChart',
    ),
    (
      page: const AppStepLineChartDemoPage(),
      pageType: AppStepLineChartDemoPage,
      title: 'AppStepLineChart',
    ),
    (
      page: const AppRangeAreaChartDemoPage(),
      pageType: AppRangeAreaChartDemoPage,
      title: 'AppRangeAreaChart',
    ),
    (
      page: const HorizontalProgressChartDemoPage(),
      pageType: HorizontalProgressChartDemoPage,
      title: 'AppHorizontalProgressChart',
    ),
    (
      page: const AppCategoryDonutCardDemoPage(),
      pageType: AppCategoryDonutCardDemoPage,
      title: 'AppCategoryDonutCard',
    ),
  ];

  for (final demo in chartDemos) {
    testWidgets('${demo.title} demo mounts without throwing', (tester) async {
      await tester.pumpWidget(
        LocalizedTestApp(child: demo.page),
      );
      await tester.pump(pumpDuration);

      expect(find.byType(demo.pageType), findsOneWidget);
      expect(find.text(demo.title), findsOneWidget);
    });
  }

  testWidgets(
    'AppBrazilStoreSalesMapChart demo mounts without throwing',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      try {
        await tester.pumpWidget(
          const LocalizedTestApp(
            child: AppBrazilStoreSalesMapChartDemoPage(),
          ),
        );
        await tester.pump(pumpDuration);

        expect(find.byType(AppBrazilStoreSalesMapChartDemoPage), findsOneWidget);
        expect(find.text('AppBrazilStoreSalesMapChart'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
