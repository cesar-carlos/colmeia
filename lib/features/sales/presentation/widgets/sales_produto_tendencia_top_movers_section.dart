import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_trend_comparison_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Viewport width at or above which top-gainer and top-loser charts sit side by side.
const double kSalesProdutoTendenciaTopMoversWideBreakpoint =
    AppBreakpoints.pageContentMaxWidth;

class SalesProdutoTendenciaTopMoversSection extends StatelessWidget {
  const SalesProdutoTendenciaTopMoversSection({
    required this.l10n,
    required this.topGainers,
    required this.topLosers,
    required this.loading,
    required this.onOpenGainersFullscreen,
    required this.onOpenLosersFullscreen,
    required this.gainersShareKey,
    required this.losersShareKey,
    required this.onShareGainers,
    required this.onShareLosers,
    super.key,
  });

  final AppLocalizations l10n;
  final List<ProdutoVendidoTendenciaDeVendaRow> topGainers;
  final List<ProdutoVendidoTendenciaDeVendaRow> topLosers;
  final bool loading;
  final VoidCallback onOpenGainersFullscreen;
  final VoidCallback onOpenLosersFullscreen;
  final GlobalKey gainersShareKey;
  final GlobalKey losersShareKey;
  final VoidCallback? onShareGainers;
  final VoidCallback? onShareLosers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final hasTopMovers = topGainers.isNotEmpty || topLosers.isNotEmpty;
    final chartBlockHeight = AppComparisonBarChart.loadingBlockHeight(tokens);

    return AppSectionCardWithHeading(
      title: l10n.salesProdutoTendenciaTopMoversTitle,
      subtitle: l10n.salesProdutoTendenciaTopMoversSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (loading && !hasTopMovers)
            AppSkeleton(
              enabled: true,
              loadingSemanticsLabel:
                  l10n.salesProdutoTendenciaLoadingTrendSemantics,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final titleStyle = theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  );
                  final wideSkeleton = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              l10n.salesProdutoTendenciaTopGainersTitle,
                              style: titleStyle,
                            ),
                            SizedBox(height: tokens.gapSm),
                            SizedBox(
                              height: chartBlockHeight,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  l10n.salesProdutoTendenciaTopGainersTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: tokens.gapMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              l10n.salesProdutoTendenciaTopLosersTitle,
                              style: titleStyle,
                            ),
                            SizedBox(height: tokens.gapSm),
                            SizedBox(
                              height: chartBlockHeight,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  l10n.salesProdutoTendenciaTopLosersTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                  final narrowSkeleton = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        l10n.salesProdutoTendenciaTopGainersTitle,
                        style: titleStyle,
                      ),
                      SizedBox(height: tokens.gapSm),
                      SizedBox(
                        height: chartBlockHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.salesProdutoTendenciaTopGainersTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(height: tokens.gapMd),
                      Text(
                        l10n.salesProdutoTendenciaTopLosersTitle,
                        style: titleStyle,
                      ),
                      SizedBox(height: tokens.gapSm),
                      SizedBox(
                        height: chartBlockHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.salesProdutoTendenciaTopLosersTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  );
                  return constraints.maxWidth >=
                          kSalesProdutoTendenciaTopMoversWideBreakpoint
                      ? wideSkeleton
                      : narrowSkeleton;
                },
              ),
            )
          else if (!hasTopMovers)
            Text(
              l10n.salesProdutoTendenciaNoData,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >=
                    kSalesProdutoTendenciaTopMoversWideBreakpoint;
                final chartAxisFormat = NumberFormat.decimalPattern(
                  l10n.localeName,
                );
                final gainersChart = RepaintBoundary(
                  key: gainersShareKey,
                  child: AppComparisonBarChart<ProdutoVendidoTendenciaDeVendaRow>(
                    title: l10n.salesProdutoTendenciaTopGainersTitle,
                    items: topGainers,
                    labelBuilder: (row) => row.nomeProduto,
                    valueBuilder: (row) => row.percentualTendencia,
                    onShare: onShareGainers,
                    onOpenFullscreen: onOpenGainersFullscreen,
                    openFullscreenTooltip: l10n.chartOpenFullscreenTooltip,
                    openFullscreenSemanticLabel:
                        l10n.chartOpenFullscreenTooltip,
                    plotFloorAccessibilityNotice:
                        l10n.chartComparisonPlotFloorNotice,
                    extremeSpreadAccessibilityNotice:
                        l10n.chartComparisonExtremeValueSpreadNotice,
                    style: salesTrendHomeLikeComparisonBarChartStyle(
                      tokens: tokens,
                      l10n: l10n,
                      yAxisFormat: chartAxisFormat,
                      minPlottedValueShareOfMax: 0.03,
                    ),
                    dataLabelBuilder: (row, _) =>
                        '${row.percentualTendencia.toStringAsFixed(1)}%',
                    tooltipLabelBuilder: (row, value) =>
                        '${row.nomeProduto} • '
                        '${row.percentualTendencia.toStringAsFixed(2)}% • '
                        '${NumberFormat.decimalPattern(l10n.localeName).format(row.diferenca.round())}',
                  ),
                );
                final losersChart = RepaintBoundary(
                  key: losersShareKey,
                  child: AppComparisonBarChart<ProdutoVendidoTendenciaDeVendaRow>(
                    title: l10n.salesProdutoTendenciaTopLosersTitle,
                    items: topLosers,
                    labelBuilder: (row) => row.nomeProduto,
                    valueBuilder: (row) => row.percentualTendencia.abs(),
                    onShare: onShareLosers,
                    onOpenFullscreen: onOpenLosersFullscreen,
                    openFullscreenTooltip: l10n.chartOpenFullscreenTooltip,
                    openFullscreenSemanticLabel:
                        l10n.chartOpenFullscreenTooltip,
                    plotFloorAccessibilityNotice:
                        l10n.chartComparisonPlotFloorNotice,
                    extremeSpreadAccessibilityNotice:
                        l10n.chartComparisonExtremeValueSpreadNotice,
                    style: salesTrendHomeLikeComparisonBarChartStyle(
                      tokens: tokens,
                      l10n: l10n,
                      yAxisFormat: chartAxisFormat,
                      minPlottedValueShareOfMax: 0.03,
                    ),
                    dataLabelBuilder: (row, _) =>
                        '${row.percentualTendencia.toStringAsFixed(1)}%',
                    tooltipLabelBuilder: (row, value) =>
                        '${row.nomeProduto} • '
                        '${row.percentualTendencia.toStringAsFixed(2)}% • '
                        '${NumberFormat.decimalPattern(l10n.localeName).format(row.diferenca.round())}',
                  ),
                );
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: gainersChart),
                      SizedBox(width: tokens.gapMd),
                      Expanded(child: losersChart),
                    ],
                  );
                }
                return Column(
                  children: <Widget>[
                    gainersChart,
                    SizedBox(height: tokens.gapMd),
                    losersChart,
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
