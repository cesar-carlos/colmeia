import 'package:colmeia/features/overview/presentation/widgets/overview_agent_filter_summary.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_filter_period_chip.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';

ChartShareExportHeaderContext buildOverviewChartShareExportHeaderContext({
  required AppLocalizations l10n,
  required DashboardFilter filter,
  required List<DashboardAgentOption> availableAgents,
  required DateTime periodStart,
  required DateTime periodEnd,
  List<ChartShareExportHeaderParameter> extraParameters =
      const <ChartShareExportHeaderParameter>[],
}) {
  final singleAgentName = resolveChartShareSingleAgentName(
    availableAgents: [
      for (final agent in availableAgents)
        ChartShareAgentOption(agentId: agent.agentId, name: agent.name),
    ],
    selectedAgentIds: filter.selectedAgentIds,
  );
  final periodParameter = ChartShareExportHeaderParameter(
    label: filter.referenceRange != null
        ? l10n.dashboardHomeFiltersReferenceRangeLabel
        : l10n.dashboardHomeFiltersYearMonthLabel,
    value: OverviewFilterPeriodChipData(
      startYmd: OverviewFilterPeriodChipData.packYmd(periodStart),
      endYmd: OverviewFilterPeriodChipData.packYmd(periodEnd),
      hasCustomRange: filter.referenceRange != null,
    ).label(l10n),
  );
  final branchScopeParameter = singleAgentName == null
      ? ChartShareExportHeaderParameter(
          label: l10n.dashboardHomeFiltersBranchesLabel,
          value: overviewAgentFilterSummaryLabel(
            filter: filter,
            availableAgents: availableAgents,
            l10n: l10n,
          ),
        )
      : null;

  return ChartShareExportHeaderContext(
    singleAgentLabel: l10n.dashboardHomeFiltersBranchesLabel,
    singleAgentName: singleAgentName,
    parameters: <ChartShareExportHeaderParameter>[
      periodParameter,
      ?branchScopeParameter,
      ...extraParameters,
    ],
  );
}

ChartShareExportHeaderParameter overviewWeekdayMetricExportHeaderParameter({
  required AppLocalizations l10n,
  required bool isSalesCountMetric,
}) {
  return ChartShareExportHeaderParameter(
    label: l10n.brazilStoreSalesMapMetricGroupLabel,
    value: isSalesCountMetric
        ? l10n.overviewWeekdayMetricSalesCountLabel
        : l10n.overviewWeekdayMetricSalesAmountLabel,
  );
}

ChartShareExportHeaderContext? overviewWeekdayChartShareExportHeaderContext({
  required ChartShareExportHeaderContext? base,
  required AppLocalizations l10n,
  required bool isSalesCountMetric,
}) {
  final metricParameter = overviewWeekdayMetricExportHeaderParameter(
    l10n: l10n,
    isSalesCountMetric: isSalesCountMetric,
  );
  if (base == null) {
    return ChartShareExportHeaderContext(
      parameters: <ChartShareExportHeaderParameter>[metricParameter],
    );
  }
  return ChartShareExportHeaderContext(
    singleAgentLabel: base.singleAgentLabel,
    singleAgentName: base.singleAgentName,
    parameters: <ChartShareExportHeaderParameter>[
      ...base.parameters,
      metricParameter,
    ],
  );
}
