import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
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

  bool get _anyChartReady =>
      _allSalesProdutoTendenciaMediaMovelCharts.any(isChartReady);

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final showInitialSkeleton = loading && !_anyChartReady;

    final grid = AppHubNavigationGrid(
      density: AppHubNavigationCardDensity.chartNav,
      itemCount: _allSalesProdutoTendenciaMediaMovelCharts.length,
      itemBuilder: (context, index, layout) {
        final chartId = _allSalesProdutoTendenciaMediaMovelCharts[index];
        final title = _chartTitle(l10n, chartId);
        final icon = _chartIcon(chartId);
        final ready = isChartReady(chartId);
        final canTap = ready;
        final semanticsLabel = _semanticsLabel(
          l10n: l10n,
          title: title,
          ready: ready,
          loading: loading,
        );

        return AppHubNavigationCard(
          density: AppHubNavigationCardDensity.chartNav,
          icon: icon,
          label: _chartNavLabel(l10n, chartId),
          tooltipMessage: title,
          labelStyle: layout.narrowLabelStyle,
          showReadyBadge: ready,
          semanticsLabel: semanticsLabel,
          aspectRatio: layout.aspectRatio,
          onTap: canTap ? () => onChartSelected(chartId) : null,
        );
      },
    );

    final resolvedGrid = showInitialSkeleton
        ? AppSkeleton(
            enabled: true,
            loadingSemanticsLabel:
                l10n.salesProdutoTendenciaMediaMovelChartNavLoadingSemantics,
            child: grid,
          )
        : grid;

    final title = sectionTitle;
    if (title == null || title.trim().isEmpty) {
      return resolvedGrid;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.gapSm),
        resolvedGrid,
      ],
    );
  }
}

String _semanticsLabel({
  required AppLocalizations l10n,
  required String title,
  required bool ready,
  required bool loading,
}) {
  if (ready) {
    return title;
  }
  if (loading) {
    return '$title, ${l10n.overviewChartNavLoadingSemanticsSuffix}';
  }
  return '$title, ${l10n.salesProdutoTendenciaChartNavUnavailableSemanticsSuffix}';
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

IconData _chartIcon(SalesProdutoTendenciaMediaMovelChartId chartId) {
  return switch (chartId) {
    SalesProdutoTendenciaMediaMovelChartId.countByClassificacao =>
      Icons.stacked_bar_chart_rounded,
    SalesProdutoTendenciaMediaMovelChartId.impactByClassificacao =>
      Icons.balance_rounded,
  };
}
