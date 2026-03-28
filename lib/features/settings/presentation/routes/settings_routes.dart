import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/settings/presentation/pages/app_area_trend_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_bullet_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_buttons_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_combo_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_compact_kpi_and_executive_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_comparison_bar_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_distribution_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_feedback_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_forms_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_funnel_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_gauge_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_heatmap_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_inline_pagination_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_metric_stat_card_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_polar_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_profile_widgets_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_pyramid_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_radar_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_radial_bar_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_range_area_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_scatter_bubble_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_section_card_heading_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_sparkline_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_stacked_bar_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_step_line_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_sunburst_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_time_series_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_treemap_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_waterfall_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/horizontal_progress_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/settings_page.dart';
import 'package:colmeia/features/settings/presentation/pages/shared_components_demo_index_page.dart';
import 'package:go_router/go_router.dart';

const String sharedComponentsDemoIndexPath = 'component-demos';
const String horizontalProgressChartDemoPath = 'horizontal-progress-chart-demo';
const String appComparisonBarChartDemoPath = 'app-comparison-bar-chart-demo';
const String appTimeSeriesChartDemoPath = 'app-time-series-chart-demo';
const String appDistributionChartDemoPath = 'app-distribution-chart-demo';
const String appMetricStatCardDemoPath = 'app-metric-stat-card-demo';
const String appSectionCardHeadingDemoPath = 'app-section-card-heading-demo';
const String appInlinePaginationDemoPath = 'app-inline-pagination-demo';
const String appCompactKpiExecutiveDemoPath = 'app-compact-kpi-executive-demo';
const String appButtonsDemoPath = 'app-buttons-demo';
const String appFeedbackDemoPath = 'app-feedback-demo';
const String appFormsDemoPath = 'app-forms-demo';
const String appProfileWidgetsDemoPath = 'app-profile-widgets-demo';
const String appStackedBarChartDemoPath = 'app-stacked-bar-chart-demo';
const String appAreaTrendChartDemoPath = 'app-area-trend-chart-demo';
const String appComboChartDemoPath = 'app-combo-chart-demo';
const String appSparklineChartDemoPath = 'app-sparkline-chart-demo';
const String appBulletChartDemoPath = 'app-bullet-chart-demo';
const String appWaterfallChartDemoPath = 'app-waterfall-chart-demo';
const String appHeatmapChartDemoPath = 'app-heatmap-chart-demo';
const String appScatterBubbleChartDemoPath = 'app-scatter-bubble-chart-demo';
const String appRangeAreaChartDemoPath = 'app-range-area-chart-demo';
const String appFunnelChartDemoPath = 'app-funnel-chart-demo';
const String appGaugeChartDemoPath = 'app-gauge-chart-demo';
const String appStepLineChartDemoPath = 'app-step-line-chart-demo';
const String appRadarChartDemoPath = 'app-radar-chart-demo';
const String appPyramidChartDemoPath = 'app-pyramid-chart-demo';
const String appPolarChartDemoPath = 'app-polar-chart-demo';
const String appRadialBarChartDemoPath = 'app-radial-bar-chart-demo';
const String appSunburstChartDemoPath = 'app-sunburst-chart-demo';
const String appTreemapChartDemoPath = 'app-treemap-chart-demo';

final String sharedComponentsDemoIndexLocation =
    '${AppRoute.settings.path}/$sharedComponentsDemoIndexPath';

final String horizontalProgressChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$horizontalProgressChartDemoPath';

final String appComparisonBarChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appComparisonBarChartDemoPath';

final String appTimeSeriesChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appTimeSeriesChartDemoPath';

final String appDistributionChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appDistributionChartDemoPath';

final String appMetricStatCardDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appMetricStatCardDemoPath';

final String appSectionCardHeadingDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appSectionCardHeadingDemoPath';

final String appInlinePaginationDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appInlinePaginationDemoPath';

final String appCompactKpiExecutiveDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appCompactKpiExecutiveDemoPath';

final String appButtonsDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appButtonsDemoPath';

final String appFeedbackDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appFeedbackDemoPath';

final String appFormsDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appFormsDemoPath';

final String appProfileWidgetsDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appProfileWidgetsDemoPath';

final String appStackedBarChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appStackedBarChartDemoPath';

final String appAreaTrendChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appAreaTrendChartDemoPath';

final String appComboChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appComboChartDemoPath';

final String appSparklineChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appSparklineChartDemoPath';

final String appBulletChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appBulletChartDemoPath';

final String appWaterfallChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appWaterfallChartDemoPath';

final String appHeatmapChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appHeatmapChartDemoPath';

final String appScatterBubbleChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appScatterBubbleChartDemoPath';

final String appRangeAreaChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appRangeAreaChartDemoPath';

final String appFunnelChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appFunnelChartDemoPath';

final String appGaugeChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appGaugeChartDemoPath';

final String appStepLineChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appStepLineChartDemoPath';

final String appRadarChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appRadarChartDemoPath';

final String appPyramidChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appPyramidChartDemoPath';

final String appPolarChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appPolarChartDemoPath';

final String appRadialBarChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appRadialBarChartDemoPath';

final String appSunburstChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appSunburstChartDemoPath';

final String appTreemapChartDemoLocation =
    '$sharedComponentsDemoIndexLocation/$appTreemapChartDemoPath';

List<RouteBase> buildSettingsRoutes() {
  return <RouteBase>[
    GoRoute(
      name: AppRoute.settings.name,
      path: AppRoute.settings.path,
      builder: (context, state) {
        return const SettingsPage();
      },
      routes: <RouteBase>[
        GoRoute(
          path: sharedComponentsDemoIndexPath,
          builder: (context, state) {
            return const SharedComponentsDemoIndexPage();
          },
          routes: <RouteBase>[
            GoRoute(
              path: horizontalProgressChartDemoPath,
              builder: (context, state) {
                return const HorizontalProgressChartDemoPage();
              },
            ),
            GoRoute(
              path: appComparisonBarChartDemoPath,
              builder: (context, state) {
                return const AppComparisonBarChartDemoPage();
              },
            ),
            GoRoute(
              path: appTimeSeriesChartDemoPath,
              builder: (context, state) {
                return const AppTimeSeriesChartDemoPage();
              },
            ),
            GoRoute(
              path: appDistributionChartDemoPath,
              builder: (context, state) {
                return const AppDistributionChartDemoPage();
              },
            ),
            GoRoute(
              path: appMetricStatCardDemoPath,
              builder: (context, state) {
                return const AppMetricStatCardDemoPage();
              },
            ),
            GoRoute(
              path: appSectionCardHeadingDemoPath,
              builder: (context, state) {
                return const AppSectionCardHeadingDemoPage();
              },
            ),
            GoRoute(
              path: appInlinePaginationDemoPath,
              builder: (context, state) {
                return const AppInlinePaginationDemoPage();
              },
            ),
            GoRoute(
              path: appCompactKpiExecutiveDemoPath,
              builder: (context, state) {
                return const AppCompactKpiAndExecutiveDemoPage();
              },
            ),
            GoRoute(
              path: appButtonsDemoPath,
              builder: (context, state) {
                return const AppButtonsDemoPage();
              },
            ),
            GoRoute(
              path: appFeedbackDemoPath,
              builder: (context, state) {
                return const AppFeedbackDemoPage();
              },
            ),
            GoRoute(
              path: appFormsDemoPath,
              builder: (context, state) {
                return const AppFormsDemoPage();
              },
            ),
            GoRoute(
              path: appProfileWidgetsDemoPath,
              builder: (context, state) {
                return const AppProfileWidgetsDemoPage();
              },
            ),
            GoRoute(
              path: appStackedBarChartDemoPath,
              builder: (context, state) {
                return const AppStackedBarChartDemoPage();
              },
            ),
            GoRoute(
              path: appAreaTrendChartDemoPath,
              builder: (context, state) {
                return const AppAreaTrendChartDemoPage();
              },
            ),
            GoRoute(
              path: appComboChartDemoPath,
              builder: (context, state) {
                return const AppComboChartDemoPage();
              },
            ),
            GoRoute(
              path: appSparklineChartDemoPath,
              builder: (context, state) {
                return const AppSparklineChartDemoPage();
              },
            ),
            GoRoute(
              path: appBulletChartDemoPath,
              builder: (context, state) {
                return const AppBulletChartDemoPage();
              },
            ),
            GoRoute(
              path: appWaterfallChartDemoPath,
              builder: (context, state) {
                return const AppWaterfallChartDemoPage();
              },
            ),
            GoRoute(
              path: appHeatmapChartDemoPath,
              builder: (context, state) {
                return const AppHeatmapChartDemoPage();
              },
            ),
            GoRoute(
              path: appScatterBubbleChartDemoPath,
              builder: (context, state) {
                return const AppScatterBubbleChartDemoPage();
              },
            ),
            GoRoute(
              path: appRangeAreaChartDemoPath,
              builder: (context, state) {
                return const AppRangeAreaChartDemoPage();
              },
            ),
            GoRoute(
              path: appFunnelChartDemoPath,
              builder: (context, state) {
                return const AppFunnelChartDemoPage();
              },
            ),
            GoRoute(
              path: appGaugeChartDemoPath,
              builder: (context, state) {
                return const AppGaugeChartDemoPage();
              },
            ),
            GoRoute(
              path: appStepLineChartDemoPath,
              builder: (context, state) {
                return const AppStepLineChartDemoPage();
              },
            ),
            GoRoute(
              path: appRadarChartDemoPath,
              builder: (context, state) {
                return const AppRadarChartDemoPage();
              },
            ),
            GoRoute(
              path: appPyramidChartDemoPath,
              builder: (context, state) {
                return const AppPyramidChartDemoPage();
              },
            ),
            GoRoute(
              path: appPolarChartDemoPath,
              builder: (context, state) {
                return const AppPolarChartDemoPage();
              },
            ),
            GoRoute(
              path: appRadialBarChartDemoPath,
              builder: (context, state) {
                return const AppRadialBarChartDemoPage();
              },
            ),
            GoRoute(
              path: appSunburstChartDemoPath,
              builder: (context, state) {
                return const AppSunburstChartDemoPage();
              },
            ),
            GoRoute(
              path: appTreemapChartDemoPath,
              builder: (context, state) {
                return const AppTreemapChartDemoPage();
              },
            ),
          ],
        ),
      ],
    ),
  ];
}
