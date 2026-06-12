import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/chart_share_icon_button.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/dashboard_lucratividade_percent_metrics.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_bar_chart_preferences.dart';
import 'package:colmeia/features/sales/presentation/share/sales_monthly_pnl_share.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_monthly_pnl_bar_chart_body.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_monthly_pnl_bar_chart_controls.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';

Future<void> pushSalesMonthlyPnlBarChartFullscreen({
  required BuildContext context,
  required List<SalesMonthlyPnlPoint> points,
  required SalesMonthlyPnlBarChartPreferences initialSession,
  required bool isLoading,
  required bool loadFailed,
  String? loadFailureMessage,
  String? filterSummary,
  ChartShareExportHeaderContext? exportHeaderContext,
}) {
  final pageL10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  final tokens = theme.appTokens;
  final chartTheme = AppChartTheme.fromContext(
    context,
    preset: AppChartPreset.standard,
  );
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  final primaryMoney = NumberFormat.currency(
    locale: localeTag,
    symbol: r'R$',
    decimalDigits: 0,
  );
  final gridLineColor = theme.colorScheme.outlineVariant.withValues(
    alpha: 0.35,
  );
  final percentRatioFormat = NumberFormat.decimalPercentPattern(
    locale: localeTag,
    decimalDigits: 1,
  );
  final fullscreenShareKey = GlobalKey();
  final shareTitle = pageL10n.salesMonthlyPnlBarChartTitle;
  final shareMetadata = buildSalesMonthlyPnlBarChartShareMetadata(
    l10n: pageL10n,
    points: points,
    session: initialSession,
    tokens: tokens,
    chartTheme: chartTheme,
    localeTag: localeTag,
    primaryMoney: primaryMoney,
    gridLineColor: gridLineColor,
    percentRatioFormat: percentRatioFormat,
    exportHeaderContext: exportHeaderContext,
  );
  return context.pushChartFullscreen<void>(
    extra: AppChartFullscreenRouteExtra(
      title: shareTitle,
      subtitle: pageL10n.salesMonthlyPnlBarChartSubtitle,
      filterSummary: filterSummary,
      chartSemanticsLabel: pageL10n.salesMonthlyPnlBarChartSemantics,
      headerTrailing: buildChartFullscreenShareTrailing(
        context: context,
        shareKey: fullscreenShareKey,
        metadata: shareMetadata,
      ),
      chartBuilder: (fullscreenContext) {
        final l10nFs = AppLocalizations.of(fullscreenContext);
        final tokensFs = fullscreenContext.appTokens;
        final sessionHolder = <SalesMonthlyPnlBarChartPreferences>[
          initialSession,
        ];
        return RepaintBoundary(
          key: fullscreenShareKey,
          child: StatefulBuilder(
            builder: (context, setFs) {
              final fsSession = sessionHolder[0];
              final isPct =
                  fsSession.displayMode ==
                  SalesMonthlyPnlBarDisplayMode.percent;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  salesMonthlyPnlBarDisplayModeSegmented(
                    l10n: l10nFs,
                    value: fsSession.displayMode,
                    onChanged: (v) => setFs(() {
                      sessionHolder[0] = sessionHolder[0].copyWith(
                        displayMode: v,
                      );
                    }),
                  ),
                  if (isPct) ...<Widget>[
                    SizedBox(height: tokensFs.gapSm),
                    Semantics(
                      sortKey: const OrdinalSortKey(2),
                      child: LayoutBuilder(
                        builder: (context, c2) {
                          final narrow = c2.maxWidth < 380;
                          return DashboardLucratividadePercentMetricSection(
                            l10n: l10nFs,
                            tokens: tokensFs,
                            metric: fsSession.percentMetric,
                            useDropdownLayout: narrow,
                            hasChartData: points.isNotEmpty,
                            showChronologicalHint: true,
                            onMetricChanged: (v) => setFs(() {
                              sessionHolder[0] = sessionHolder[0].copyWith(
                                percentMetric: v,
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ],
                  SizedBox(height: tokensFs.contentSpacing),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, innerConstraints) {
                        final chartH = innerConstraints.maxHeight.isFinite
                            ? innerConstraints.maxHeight
                            : 220.0;
                        return SalesMonthlyPnlBarChartBody(
                          l10n: l10nFs,
                          points: points,
                          loadFailed: loadFailed,
                          loadFailureMessage: loadFailureMessage,
                          isLoading: isLoading,
                          session: sessionHolder[0],
                          chartHeightOverride: chartH,
                          useChartShell: false,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    ),
  );
}
