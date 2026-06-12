import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_row_percent_metric_comparator.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row_percent_metric.dart';
import 'package:colmeia/features/overview/presentation/share/overview_lucratividade_chart_share.dart';
import 'package:colmeia/features/overview/presentation/widgets/lucratividade_combo_chart.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:flutter/material.dart';

/// Period product profitability chart: **one category per agent** (all
/// branches summed) for the active overview filter date range.
class OverviewLucratividadeChart extends StatelessWidget {
  const OverviewLucratividadeChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    required this.overviewApprovedAgentCount,
    this.loadFailure,
    this.loadFailureMessage,
    this.onViewAgentFailureDetails,
    this.onRequestFullscreen,
    this.onRequestShare,
    this.exportHeaderContext,
    super.key,
  });

  final AppLocalizations l10n;
  final ChartShareExportHeaderContext? exportHeaderContext;
  final List<ResumoProdutoVendaLucratividadeRow> points;
  final bool loadFailed;
  final AppFailure? loadFailure;
  final int overviewApprovedAgentCount;
  final String? loadFailureMessage;
  final VoidCallback? onViewAgentFailureDetails;
  final AppChartFullscreenRequestCallback? onRequestFullscreen;
  final AppChartShareRequestCallback? onRequestShare;

  static final LucratividadeComboRowAccessors<ResumoProdutoVendaLucratividadeRow>
  _rowAccessors = LucratividadeComboRowAccessors(
    lucro: (r) => r.lucro,
    valorTotalItem: (r) => r.valorTotalItem,
    custoReposicao: (r) => r.custoReposicao,
    metricBarValue: (r, m) => r.metricBarValue(m),
    sortPoints: (sorted, display, percentMetric) {
      if (display == LucratividadeComboDisplay.profitRevenue) {
        sorted.sort((a, b) => b.lucro.compareTo(a.lucro));
      } else if (display == LucratividadeComboDisplay.costRevenue) {
        sorted.sort((a, b) => b.custoReposicao.compareTo(a.custoReposicao));
      } else if (display == LucratividadeComboDisplay.percentMetrics) {
        sorted.sort(
          (a, b) => compareLucratividadeRowsByPercentMetric(a, b, percentMetric),
        );
      } else {
        sorted.sort((a, b) => b.valorTotalItem.compareTo(a.valorTotalItem));
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return LucratividadeComboChart<ResumoProdutoVendaLucratividadeRow>(
      l10n: l10n,
      copy: LucratividadeComboChartCopy(
        title: l10n.overviewLucratividadeTitle,
        subtitle: l10n.overviewLucratividadeSubtitle,
        switchProfit: l10n.overviewLucratividadeSwitchProfit,
        switchRevenue: l10n.overviewLucratividadeSwitchRevenue,
        switchCost: l10n.overviewLucratividadeSwitchCost,
        switchMargin: l10n.overviewLucratividadeSwitchMargin,
        profitSeriesLabel: l10n.overviewLucratividadeProfitSeriesLabel,
        revenueSeriesLabel: l10n.overviewLucratividadeRevenueSeriesLabel,
        costSeriesLabel: l10n.overviewLucratividadeCostSeriesLabel,
        emptyMessage: l10n.overviewLucratividadeEmpty,
        multiAgentHintMessage: l10n.overviewLucratividadeMultiAgentHint,
        loadFailedFallback: l10n.overviewMonthlyParcelsLoadFailed,
        showChronologicalPercentHint: false,
        useSmartCompactCurrencyLabels: true,
        chartPaddingBottom: tokens.gapSm,
      ),
      points: points,
      loadFailed: loadFailed,
      loadFailure: loadFailure,
      loadFailureMessage: loadFailureMessage,
      onViewAgentFailureDetails: onViewAgentFailureDetails,
      onRequestFullscreen: onRequestFullscreen,
      onRequestShare: onRequestShare,
      exportHeaderContext: exportHeaderContext,
      rowAccessors: _rowAccessors,
      xLabelBuilder: overviewLucratividadeAgentXLabel,
      hasMultiAgentEmptyHint: overviewApprovedAgentCount > 0,
      shareMetadataBuilder:
          ({
            required sortedPoints,
            required exportBaseStyle,
            required barFn,
            required lineFn,
            required labelFn,
            required barSeriesLabel,
            required lineSeriesLabel,
          }) => buildOverviewLucratividadeChartShareMetadata(
            l10n: l10n,
            sortedPoints: sortedPoints,
            exportBaseStyle: exportBaseStyle,
            series: OverviewLucratividadeComboShareSeries(
              barValueBuilder: barFn,
              lineValueBuilder: lineFn,
              barDataLabelBuilder: labelFn,
              barSeriesLabel: barSeriesLabel,
              lineSeriesLabel: lineSeriesLabel,
            ),
            exportHeaderContext: exportHeaderContext,
          ),
    );
  }
}
