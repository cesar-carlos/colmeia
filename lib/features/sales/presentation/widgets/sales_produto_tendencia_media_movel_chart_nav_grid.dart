import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card_density.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_grid.dart';
import 'package:flutter/material.dart';

enum SalesProdutoTendenciaMediaMovelChartId {
  countByClassificacao,
  impactByClassificacao,
}

const List<SalesProdutoTendenciaMediaMovelChartId>
    _allSalesProdutoTendenciaMediaMovelCharts =
    <SalesProdutoTendenciaMediaMovelChartId>[
  SalesProdutoTendenciaMediaMovelChartId.countByClassificacao,
  SalesProdutoTendenciaMediaMovelChartId.impactByClassificacao,
];

/// Compact navigation grid for moving-average trend chart fullscreen views.
class SalesProdutoTendenciaMediaMovelChartNavGrid extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelChartNavGrid({
    required this.l10n,
    required this.onChartSelected,
    super.key,
    this.loading = false,
    this.enabled = true,
  });

  final AppLocalizations l10n;
  final ValueChanged<SalesProdutoTendenciaMediaMovelChartId> onChartSelected;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final grid = AppHubNavigationGrid(
      density: AppHubNavigationCardDensity.chartNav,
      itemCount: _allSalesProdutoTendenciaMediaMovelCharts.length,
      itemBuilder: (context, index, layout) {
        final chartId = _allSalesProdutoTendenciaMediaMovelCharts[index];
        final title = _chartTitle(l10n, chartId);
        final icon = _chartIcon(chartId);
        final canTap = enabled && !loading;

        return AppHubNavigationCard(
          density: AppHubNavigationCardDensity.chartNav,
          icon: icon,
          label: title,
          labelStyle: layout.narrowLabelStyle,
          semanticsLabel: title,
          aspectRatio: layout.aspectRatio,
          onTap: canTap ? () => onChartSelected(chartId) : null,
        );
      },
    );

    if (!loading) {
      return grid;
    }

    return AppSkeleton(
      enabled: true,
      loadingSemanticsLabel: l10n.chartLoadingGeneric,
      child: grid,
    );
  }
}

String _chartTitle(
  AppLocalizations l10n,
  SalesProdutoTendenciaMediaMovelChartId chartId,
) {
  return switch (chartId) {
    SalesProdutoTendenciaMediaMovelChartId.countByClassificacao =>
      l10n.salesProdutoTendenciaMediaMovelSummaryByClassificacaoTitle,
    SalesProdutoTendenciaMediaMovelChartId.impactByClassificacao =>
      l10n.salesProdutoTendenciaMediaMovelSummaryByImpactTitle,
  };
}

IconData _chartIcon(SalesProdutoTendenciaMediaMovelChartId chartId) {
  return switch (chartId) {
    SalesProdutoTendenciaMediaMovelChartId.countByClassificacao =>
      Icons.stacked_bar_chart_rounded,
    SalesProdutoTendenciaMediaMovelChartId.impactByClassificacao =>
      Icons.balance_rounded,
  };
}
