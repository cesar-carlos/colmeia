import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_classificacao.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_filter_limits.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_metric_mode.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/forms/app_choice_chip.dart';
import 'package:flutter/material.dart';

/// Shared metric / volume / threshold controls for both trend filter sheets.
class SalesTrendSharedFilterControls extends StatelessWidget {
  const SalesTrendSharedFilterControls({
    required this.l10n,
    required this.metricMode,
    required this.minVolumeUnits,
    required this.trendThresholdPercent,
    required this.onMetricModeChanged,
    required this.onMinVolumeChanged,
    required this.onThresholdChanged,
    super.key,
    this.topMoversSortBy,
    this.onTopMoversSortChanged,
  });

  final AppLocalizations l10n;
  final SalesTrendMetricMode metricMode;
  final int minVolumeUnits;
  final double trendThresholdPercent;
  final ValueChanged<SalesTrendMetricMode> onMetricModeChanged;
  final ValueChanged<int> onMinVolumeChanged;
  final ValueChanged<double> onThresholdChanged;
  final SalesTrendTopMoversSortBy? topMoversSortBy;
  final ValueChanged<SalesTrendTopMoversSortBy>? onTopMoversSortChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.salesTrendFilterMetricTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.gapSm),
        Wrap(
          spacing: tokens.gapSm,
          runSpacing: tokens.gapSm,
          children: <Widget>[
            AppChoiceChip(
              label: l10n.salesTrendFilterMetricQuantity,
              selected: metricMode == SalesTrendMetricMode.quantity,
              icon: Icons.inventory_2_outlined,
              onSelected: () =>
                  onMetricModeChanged(SalesTrendMetricMode.quantity),
            ),
            AppChoiceChip(
              label: l10n.salesTrendFilterMetricRevenue,
              selected: metricMode == SalesTrendMetricMode.revenue,
              icon: Icons.payments_outlined,
              onSelected: () =>
                  onMetricModeChanged(SalesTrendMetricMode.revenue),
            ),
          ],
        ),
        SizedBox(height: tokens.contentSpacing),
        Text(
          l10n.salesTrendFilterMinVolumeTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.gapSm),
        Wrap(
          spacing: tokens.gapSm,
          runSpacing: tokens.gapSm,
          children: <Widget>[
            for (final preset in SalesTrendFilterLimits.minVolumePresets)
              AppChoiceChip(
                label: '$preset',
                selected: minVolumeUnits == preset,
                onSelected: () => onMinVolumeChanged(preset),
              ),
          ],
        ),
        SizedBox(height: tokens.contentSpacing),
        Text(
          l10n.salesTrendFilterThresholdTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.gapSm),
        Wrap(
          spacing: tokens.gapSm,
          runSpacing: tokens.gapSm,
          children: <Widget>[
            for (final preset in SalesTrendFilterLimits.trendThresholdPresets)
              AppChoiceChip(
                label: l10n.salesTrendFilterThresholdPercentLabel(
                  (preset * 100).round(),
                ),
                selected: trendThresholdPercent == preset,
                onSelected: () => onThresholdChanged(preset),
              ),
          ],
        ),
        if (topMoversSortBy != null &&
            onTopMoversSortChanged != null) ...<Widget>[
          SizedBox(height: tokens.contentSpacing),
          Text(
            l10n.salesTrendFilterTopMoversSortTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.gapSm),
          Wrap(
            spacing: tokens.gapSm,
            runSpacing: tokens.gapSm,
            children: <Widget>[
              AppChoiceChip(
                label: l10n.salesTrendFilterTopMoversSortDifference,
                selected:
                    topMoversSortBy == SalesTrendTopMoversSortBy.diferenca,
                onSelected: () => onTopMoversSortChanged!(
                  SalesTrendTopMoversSortBy.diferenca,
                ),
              ),
              AppChoiceChip(
                label: l10n.salesTrendFilterTopMoversSortPercent,
                selected:
                    topMoversSortBy == SalesTrendTopMoversSortBy.percentual,
                onSelected: () => onTopMoversSortChanged!(
                  SalesTrendTopMoversSortBy.percentual,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

List<ChartShareExportHeaderParameter> salesTrendShareExtraParameters({
  required AppLocalizations l10n,
  required SalesTrendMetricMode metricMode,
  required int minVolumeUnits,
  required double trendThresholdPercent,
  String? filialLabel,
  int? codFilial,
}) {
  final params = <ChartShareExportHeaderParameter>[
    ChartShareExportHeaderParameter(
      label: l10n.salesTrendFilterMetricTitle,
      value: metricMode == SalesTrendMetricMode.revenue
          ? l10n.salesTrendFilterMetricRevenue
          : l10n.salesTrendFilterMetricQuantity,
    ),
    ChartShareExportHeaderParameter(
      label: l10n.salesTrendFilterMinVolumeTitle,
      value: '$minVolumeUnits',
    ),
    ChartShareExportHeaderParameter(
      label: l10n.salesTrendFilterThresholdTitle,
      value: l10n.salesTrendFilterThresholdPercentLabel(
        (trendThresholdPercent * 100).round(),
      ),
    ),
    ChartShareExportHeaderParameter(
      label: l10n.salesProdutoTendenciaFilterClassification,
      value: l10n.salesProdutoTendenciaSummaryClassificacaoLegend,
    ),
  ];
  if (codFilial != null) {
    params.insert(
      0,
      ChartShareExportHeaderParameter(
        label: l10n.salesTrendFilterFilialLabel,
        value: filialLabel ?? '#$codFilial',
      ),
    );
  }
  return params;
}
