import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card_density.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_grid.dart';
import 'package:flutter/material.dart';

enum SalesProdutoTendenciaChartId {
  classificacao,
  topGainers,
  topLosers,
}

const List<SalesProdutoTendenciaChartId> _allSalesProdutoTendenciaCharts =
    <SalesProdutoTendenciaChartId>[
  SalesProdutoTendenciaChartId.classificacao,
  SalesProdutoTendenciaChartId.topGainers,
  SalesProdutoTendenciaChartId.topLosers,
];

/// Compact navigation grid for sales trend chart fullscreen views.
class SalesProdutoTendenciaChartNavGrid extends StatelessWidget {
  const SalesProdutoTendenciaChartNavGrid({
    required this.l10n,
    required this.onChartSelected,
    super.key,
    this.loading = false,
    this.enabled = true,
  });

  final AppLocalizations l10n;
  final ValueChanged<SalesProdutoTendenciaChartId> onChartSelected;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final grid = AppHubNavigationGrid(
      density: AppHubNavigationCardDensity.chartNav,
      itemCount: _allSalesProdutoTendenciaCharts.length,
      itemBuilder: (context, index, layout) {
        final chartId = _allSalesProdutoTendenciaCharts[index];
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
      loadingSemanticsLabel: l10n.salesProdutoTendenciaLoadingTrendSemantics,
      child: grid,
    );
  }
}

String _chartTitle(AppLocalizations l10n, SalesProdutoTendenciaChartId chartId) {
  return switch (chartId) {
    SalesProdutoTendenciaChartId.classificacao =>
      l10n.salesProdutoTendenciaSummaryByClassificacaoTitle,
    SalesProdutoTendenciaChartId.topGainers =>
      l10n.salesProdutoTendenciaTopGainersTitle,
    SalesProdutoTendenciaChartId.topLosers =>
      l10n.salesProdutoTendenciaTopLosersTitle,
  };
}

IconData _chartIcon(SalesProdutoTendenciaChartId chartId) {
  return switch (chartId) {
    SalesProdutoTendenciaChartId.classificacao => Icons.stacked_bar_chart_rounded,
    SalesProdutoTendenciaChartId.topGainers => Icons.trending_up_rounded,
    SalesProdutoTendenciaChartId.topLosers => Icons.trending_down_rounded,
  };
}
