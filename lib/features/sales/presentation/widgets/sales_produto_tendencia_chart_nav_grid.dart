import 'package:colmeia/features/sales/presentation/widgets/sales_trend_chart_nav_grid.dart';
import 'package:colmeia/l10n/app_localizations.dart';
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
    required this.isChartReady,
    super.key,
    this.loading = false,
    this.sectionTitle,
  });

  final AppLocalizations l10n;
  final ValueChanged<SalesProdutoTendenciaChartId> onChartSelected;
  final bool Function(SalesProdutoTendenciaChartId chartId) isChartReady;
  final bool loading;
  final String? sectionTitle;

  @override
  Widget build(BuildContext context) {
    return SalesTrendChartNavGrid<SalesProdutoTendenciaChartId>(
      items: _allSalesProdutoTendenciaCharts
          .map((chartId) => _toItem(l10n, chartId))
          .toList(growable: false),
      l10n: l10n,
      onChartSelected: onChartSelected,
      isChartReady: isChartReady,
      loading: loading,
      sectionTitle: sectionTitle,
      loadingSemanticsLabel: l10n.salesProdutoTendenciaLoadingTrendSemantics,
    );
  }
}

SalesTrendChartNavItem<SalesProdutoTendenciaChartId> _toItem(
  AppLocalizations l10n,
  SalesProdutoTendenciaChartId chartId,
) {
  return SalesTrendChartNavItem<SalesProdutoTendenciaChartId>(
    id: chartId,
    icon: _chartIcon(chartId),
    navLabel: _chartNavLabel(l10n, chartId),
    title: _chartTitle(l10n, chartId),
    subtitle: _chartSubtitle(l10n, chartId),
  );
}

String _chartTitle(
  AppLocalizations l10n,
  SalesProdutoTendenciaChartId chartId,
) {
  return switch (chartId) {
    SalesProdutoTendenciaChartId.classificacao =>
      l10n.salesProdutoTendenciaSummaryByClassificacaoTitle,
    SalesProdutoTendenciaChartId.topGainers =>
      l10n.salesProdutoTendenciaTopGainersTitle,
    SalesProdutoTendenciaChartId.topLosers =>
      l10n.salesProdutoTendenciaTopLosersTitle,
  };
}

String _chartNavLabel(
  AppLocalizations l10n,
  SalesProdutoTendenciaChartId chartId,
) {
  return switch (chartId) {
    SalesProdutoTendenciaChartId.classificacao =>
      l10n.salesProdutoTendenciaChartNavClassificacaoLabel,
    SalesProdutoTendenciaChartId.topGainers =>
      l10n.salesProdutoTendenciaTopGainersTitle,
    SalesProdutoTendenciaChartId.topLosers =>
      l10n.salesProdutoTendenciaTopLosersTitle,
  };
}

String? _chartSubtitle(
  AppLocalizations l10n,
  SalesProdutoTendenciaChartId chartId,
) {
  return switch (chartId) {
    SalesProdutoTendenciaChartId.classificacao =>
      l10n.salesProdutoTendenciaSummaryByClassificacaoSubtitle,
    SalesProdutoTendenciaChartId.topGainers =>
      l10n.salesProdutoTendenciaTopGainersSubtitle,
    SalesProdutoTendenciaChartId.topLosers =>
      l10n.salesProdutoTendenciaTopLosersSubtitle,
  };
}

IconData _chartIcon(SalesProdutoTendenciaChartId chartId) {
  return switch (chartId) {
    SalesProdutoTendenciaChartId.classificacao =>
      Icons.stacked_bar_chart_rounded,
    SalesProdutoTendenciaChartId.topGainers => Icons.trending_up_rounded,
    SalesProdutoTendenciaChartId.topLosers => Icons.trending_down_rounded,
  };
}
