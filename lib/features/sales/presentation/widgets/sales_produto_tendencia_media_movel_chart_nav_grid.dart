import 'package:colmeia/features/sales/presentation/widgets/sales_trend_chart_nav_grid.dart';
import 'package:colmeia/l10n/app_localizations.dart';
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
    required this.isChartReady,
    super.key,
    this.loading = false,
    this.sectionTitle,
  });

  final AppLocalizations l10n;
  final ValueChanged<SalesProdutoTendenciaMediaMovelChartId> onChartSelected;
  final bool Function(SalesProdutoTendenciaMediaMovelChartId chartId)
  isChartReady;
  final bool loading;
  final String? sectionTitle;

  @override
  Widget build(BuildContext context) {
    return SalesTrendChartNavGrid<SalesProdutoTendenciaMediaMovelChartId>(
      items: _allSalesProdutoTendenciaMediaMovelCharts
          .map((chartId) => _toItem(l10n, chartId))
          .toList(growable: false),
      l10n: l10n,
      onChartSelected: onChartSelected,
      isChartReady: isChartReady,
      loading: loading,
      sectionTitle: sectionTitle,
      loadingSemanticsLabel:
          l10n.salesProdutoTendenciaMediaMovelChartNavLoadingSemantics,
    );
  }
}

SalesTrendChartNavItem<SalesProdutoTendenciaMediaMovelChartId> _toItem(
  AppLocalizations l10n,
  SalesProdutoTendenciaMediaMovelChartId chartId,
) {
  return SalesTrendChartNavItem<SalesProdutoTendenciaMediaMovelChartId>(
    id: chartId,
    icon: _chartIcon(chartId),
    navLabel: _chartNavLabel(l10n, chartId),
    title: _chartTitle(l10n, chartId),
    subtitle: _chartSubtitle(l10n, chartId),
  );
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

String _chartNavLabel(
  AppLocalizations l10n,
  SalesProdutoTendenciaMediaMovelChartId chartId,
) {
  return switch (chartId) {
    SalesProdutoTendenciaMediaMovelChartId.countByClassificacao =>
      l10n.salesProdutoTendenciaMediaMovelChartNavClassificacaoLabel,
    SalesProdutoTendenciaMediaMovelChartId.impactByClassificacao =>
      l10n.salesProdutoTendenciaMediaMovelChartNavImpactLabel,
  };
}

String? _chartSubtitle(
  AppLocalizations l10n,
  SalesProdutoTendenciaMediaMovelChartId chartId,
) {
  return switch (chartId) {
    SalesProdutoTendenciaMediaMovelChartId.countByClassificacao =>
      l10n.salesProdutoTendenciaMediaMovelSummaryByClassificacaoSubtitle,
    SalesProdutoTendenciaMediaMovelChartId.impactByClassificacao =>
      l10n.salesProdutoTendenciaMediaMovelSummaryByImpactSubtitle,
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
