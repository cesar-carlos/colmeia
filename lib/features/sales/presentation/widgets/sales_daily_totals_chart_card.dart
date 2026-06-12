import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_chart_failure_placeholder_content.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_daily_totals_chart_copy.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_chart_labels.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/daily_sales_trend_chart.dart';
import 'package:flutter/material.dart';

class SalesDailyTotalsChartCard extends StatelessWidget {
  const SalesDailyTotalsChartCard({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    required this.isLoading,
    this.loadFailure,
    this.loadFailureMessage,
    this.dailySaleDateRange,
    this.exportHeaderContext,
    this.onRequestFullscreen,
    this.onRequestShare,
    super.key,
  });

  final AppLocalizations l10n;
  final List<DailySalesTrendPoint> points;
  final bool loadFailed;
  final bool isLoading;
  final AppFailure? loadFailure;
  final String? loadFailureMessage;
  final DashboardDateRange? dailySaleDateRange;
  final ChartShareExportHeaderContext? exportHeaderContext;
  final AppChartFullscreenRequestCallback? onRequestFullscreen;
  final AppChartShareRequestCallback? onRequestShare;

  @override
  Widget build(BuildContext context) {
    final range = dailySaleDateRange;
    final labels = DailySalesTrendChartLabels.resolve(
      l10n,
      salesBranchMonth: true,
    );
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final emptyMessage = loadFailed
        ? chartAgentQueryLoadFailureMessage(
            l10n: l10n,
            loadFailure: loadFailure,
            legacyMessage: loadFailureMessage,
            genericFallback: labels.resolveEmptyMessage(loadFailed: true),
          )
        : labels.resolveEmptyMessage(loadFailed: false);

    return DailySalesTrendChart(
      l10n: l10n,
      points: points,
      emptyMessage: emptyMessage,
      emptyPlaceholder: AgentQueryChartFailurePlaceholderContent(
        emptyMessage: emptyMessage,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        verticalPadding: tokens.contentSpacing,
        loadFailure: loadFailed ? loadFailure : null,
      ),
      isLoading: isLoading,
      useSalesDailyTotalsLabels: true,
      onRequestFullscreen: onRequestFullscreen,
      onRequestShare: onRequestShare,
      salesSubtitleOverride: range != null
          ? salesDailyTotalsEffectiveSubtitle(
              l10n,
              dailySaleDateRange: range,
            )
          : null,
      salesScopeHintOverride: range != null
          ? salesDailyTotalsEffectiveScopeHint(
              l10n,
              dailySaleDateRange: range,
            )
          : null,
      exportHeaderContext: exportHeaderContext,
    );
  }
}
