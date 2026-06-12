import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row_percent_metric.dart';
import 'package:colmeia/features/overview/presentation/share/overview_lucratividade_mensal_chart_share.dart';
import 'package:colmeia/features/overview/presentation/widgets/lucratividade_combo_chart.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:flutter/material.dart';

/// Monthly product profitability chart using the shared [LucratividadeComboChart].
class OverviewLucratividadeMensalChart extends StatelessWidget {
  const OverviewLucratividadeMensalChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    required this.isSingleAgentSelected,
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
  final List<ResumoProdutoVendaLucratividadeMensalRow> points;
  final bool loadFailed;
  final AppFailure? loadFailure;
  final bool isSingleAgentSelected;
  final String? loadFailureMessage;
  final VoidCallback? onViewAgentFailureDetails;
  final AppChartFullscreenRequestCallback? onRequestFullscreen;
  final AppChartShareRequestCallback? onRequestShare;

  static final LucratividadeComboRowAccessors<
    ResumoProdutoVendaLucratividadeMensalRow
  >
  _rowAccessors = LucratividadeComboRowAccessors(
    lucro: (r) => r.lucro,
    valorTotalItem: (r) => r.valorTotalItem,
    custoReposicao: (r) => r.custoReposicao,
    metricBarValue: (r, m) => r.metricBarValue(m),
  );

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return LucratividadeComboChart<ResumoProdutoVendaLucratividadeMensalRow>(
      l10n: l10n,
      copy: LucratividadeComboChartCopy(
        title: l10n.overviewLucratividadeMensalTitle,
        subtitle: l10n.overviewLucratividadeMensalSubtitle,
        switchProfit: l10n.overviewLucratividadeMensalSwitchProfit,
        switchRevenue: l10n.overviewLucratividadeMensalSwitchRevenue,
        switchCost: l10n.overviewLucratividadeMensalSwitchCost,
        switchMargin: l10n.overviewLucratividadeMensalSwitchMargin,
        profitSeriesLabel: l10n.overviewLucratividadeMensalProfitSeriesLabel,
        revenueSeriesLabel: l10n.overviewLucratividadeMensalRevenueSeriesLabel,
        costSeriesLabel: l10n.overviewLucratividadeMensalCostSeriesLabel,
        emptyMessage: l10n.overviewLucratividadeMensalEmpty,
        multiAgentHintMessage: l10n.overviewLucratividadeMensalMultiAgentHint,
        loadFailedFallback: l10n.overviewMonthlyParcelsLoadFailed,
        showChronologicalPercentHint: true,
        useSmartCompactCurrencyLabels: false,
        minCategorySlotWidth: tokens.chartOverviewMonthlyCategoryMinSlotWidth,
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
      xLabelBuilder: overviewLucratividadeMensalXLabel,
      hasMultiAgentEmptyHint: isSingleAgentSelected,
      landscapeStyleOverride: (base, height) => base.forLandscapeFullscreen(
        height: height,
      ),
      shareMetadataBuilder:
          ({
            required sortedPoints,
            required exportBaseStyle,
            required barFn,
            required lineFn,
            required labelFn,
            required barSeriesLabel,
            required lineSeriesLabel,
          }) => buildOverviewLucratividadeMensalChartShareMetadata(
            l10n: l10n,
            sortedPoints: sortedPoints,
            exportBaseStyle: exportBaseStyle,
            series: OverviewLucratividadeMensalComboShareSeries(
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
