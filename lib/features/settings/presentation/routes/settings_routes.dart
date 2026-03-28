import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/settings/presentation/pages/app_buttons_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_compact_kpi_and_executive_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_comparison_bar_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_distribution_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_feedback_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_forms_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_inline_pagination_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_metric_stat_card_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_profile_widgets_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_section_card_heading_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_time_series_chart_demo_page.dart';
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
          ],
        ),
      ],
    ),
  ];
}
