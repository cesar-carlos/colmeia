import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_metric.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:flutter/material.dart';

ChartShareExportHeaderContext buildSalesSingleAgentChartShareExportHeaderContext({
  required AppLocalizations l10n,
  required String agentName,
  List<ChartShareExportHeaderParameter> parameters =
      const <ChartShareExportHeaderParameter>[],
}) {
  return ChartShareExportHeaderContext(
    singleAgentLabel: l10n.salesBranchFilterLabel,
    singleAgentName: agentName,
    parameters: parameters,
  );
}

ChartShareExportHeaderParameter salesAnchorMonthExportHeaderParameter({
  required AppLocalizations l10n,
  required String anchorMonthLabel,
}) {
  return ChartShareExportHeaderParameter(
    label: l10n.salesMonthlyPnlFilterAnchorMonth,
    value: anchorMonthLabel,
  );
}

ChartShareExportHeaderParameter? salesDailyTotalsRangeExportHeaderParameter({
  required AppLocalizations l10n,
  required DashboardDateRange? dailyTotalsDateRange,
}) {
  final range = dailyTotalsDateRange;
  if (range == null) {
    return null;
  }
  return ChartShareExportHeaderParameter(
    label: l10n.salesDailyTotalsFilterSummaryLabel,
    value: l10n.salesDailyTotalsFilterSummaryCustomRangeValue(
      AppBrFormatters.shortDate(range.startInclusive),
      AppBrFormatters.shortDate(range.endInclusive),
    ),
  );
}

String salesChartShareDateTimeRangeValue(DateTimeRange range) {
  return '${AppBrFormatters.shortDate(range.start)} · '
      '${AppBrFormatters.shortDate(range.end)}';
}

ChartShareExportHeaderContext buildSalesProdutoTendenciaChartShareExportHeaderContext({
  required AppLocalizations l10n,
  required String agentName,
  required DateTimeRange periodoAtual,
  required DateTimeRange periodoAnterior,
  List<ChartShareExportHeaderParameter> extraParameters =
      const <ChartShareExportHeaderParameter>[],
}) {
  return buildSalesSingleAgentChartShareExportHeaderContext(
    l10n: l10n,
    agentName: agentName,
    parameters: <ChartShareExportHeaderParameter>[
      ChartShareExportHeaderParameter(
        label: l10n.salesProdutoTendenciaFilterCurrentPeriod,
        value: salesChartShareDateTimeRangeValue(periodoAtual),
      ),
      ChartShareExportHeaderParameter(
        label: l10n.salesProdutoTendenciaFilterPreviousPeriod,
        value: salesChartShareDateTimeRangeValue(periodoAnterior),
      ),
      ...extraParameters,
    ],
  );
}

ChartShareExportHeaderContext
buildSalesProdutoTendenciaMediaMovelChartShareExportHeaderContext({
  required AppLocalizations l10n,
  required String agentName,
  required int quantidadeDias,
  List<ChartShareExportHeaderParameter> extraParameters =
      const <ChartShareExportHeaderParameter>[],
}) {
  return buildSalesSingleAgentChartShareExportHeaderContext(
    l10n: l10n,
    agentName: agentName,
    parameters: <ChartShareExportHeaderParameter>[
      ChartShareExportHeaderParameter(
        label: l10n.salesProdutoTendenciaMediaMovelFilterQuantidadeDias,
        value: l10n.salesProdutoTendenciaMediaMovelFilterQuantidadeDiasValue(
          quantidadeDias,
        ),
      ),
      ...extraParameters,
    ],
  );
}

ChartShareExportHeaderContext
buildSalesRankingProdutosFaturamentoChartShareExportHeaderContext({
  required AppLocalizations l10n,
  required String branchName,
  required String periodLabel,
  required int quantidadeProdutos,
}) {
  return buildSalesSingleAgentChartShareExportHeaderContext(
    l10n: l10n,
    agentName: branchName,
    parameters: <ChartShareExportHeaderParameter>[
      ChartShareExportHeaderParameter(
        label: l10n.salesRankingProdutosFaturamentoFilterPeriod,
        value: periodLabel,
      ),
      ChartShareExportHeaderParameter(
        label: l10n.salesRankingProdutosFaturamentoFilterQuantidade,
        value: quantidadeProdutos.toString(),
      ),
      ChartShareExportHeaderParameter(
        label: l10n.brazilStoreSalesMapMetricGroupLabel,
        value: l10n.salesRankingProdutosFaturamentoMetricFaturamento,
      ),
    ],
  );
}

String? resolveSalesLiveMapSingleBranchName({
  required Set<SalesLiveMapBranchRef>? selectedBranchIds,
  required List<SalesLiveMapBranchOption> branchOptions,
}) {
  final selected = selectedBranchIds;
  if (selected == null || selected.length != 1) {
    return null;
  }
  final selectedRef = selected.first;
  for (final option in branchOptions) {
    if (option.branchRef == selectedRef) {
      return option.name;
    }
  }
  return null;
}

String salesLiveMapMetricExportLabel(
  AppLocalizations l10n,
  SalesLiveMapMetric metric,
) {
  return switch (metric) {
    SalesLiveMapMetric.revenue => l10n.brazilStoreSalesMapMetricRevenueShort,
    SalesLiveMapMetric.salesCount => l10n.brazilStoreSalesMapMetricSalesShort,
  };
}

ChartShareExportHeaderContext buildSalesLiveMapChartShareExportHeaderContext({
  required AppLocalizations l10n,
  required String agentsSummary,
  required String? singleBranchName,
  required String periodSummary,
  required String detailSummary,
  required String visualSummary,
  required bool usesMapLabel,
  required String mapMetricLabel,
}) {
  final branchScopeParameter = singleBranchName == null
      ? ChartShareExportHeaderParameter(
          label: l10n.salesLiveMapAgentsLabel,
          value: agentsSummary,
        )
      : null;

  return ChartShareExportHeaderContext(
    singleAgentLabel: l10n.salesLiveMapAgentsLabel,
    singleAgentName: singleBranchName,
    parameters: <ChartShareExportHeaderParameter>[
      ?branchScopeParameter,
      ChartShareExportHeaderParameter(
        label: l10n.salesLiveMapPeriodLabel,
        value: periodSummary,
      ),
      ChartShareExportHeaderParameter(
        label: l10n.salesLiveMapDetailLabel,
        value: detailSummary,
      ),
      ChartShareExportHeaderParameter(
        label: usesMapLabel
            ? l10n.salesLiveMapMapLabel
            : l10n.salesLiveMapVisualLabel,
        value: visualSummary,
      ),
      ChartShareExportHeaderParameter(
        label: l10n.brazilStoreSalesMapMetricGroupLabel,
        value: mapMetricLabel,
      ),
    ],
  );
}
