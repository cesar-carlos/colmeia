import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/sales/presentation/share/mappers/sales_produto_tendencia_media_movel_share_mapper.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_media_movel_share.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_filtered_empty_state.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_kpi_card.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_classificacao_chart_support.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_trend_comparison_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_card.dart';
import 'package:colmeia/shared/widgets/metrics/app_responsive_metric_stat_grid.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

export 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_media_movel_share.dart'
    show
        SalesProdutoTendenciaMediaMovelClassBucket,
        SalesProdutoTendenciaMediaMovelSummary,
        buildSalesProdutoTendenciaMediaMovelSummary;

class SalesProdutoTendenciaMediaMovelSummarySection extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelSummarySection({
    required this.l10n,
    required this.summary,
    required this.loading,
    required this.hasSummaryRows,
    required this.summaryRows,
    super.key,
    this.activeClassificacao,
    this.hasActiveDetailFilters = false,
    this.onClearFilters,
    this.onOpenFilters,
    this.onClearClassificacaoFilter,
    this.onClassificacaoSelected,
  });

  final AppLocalizations l10n;
  final SalesProdutoTendenciaMediaMovelSummary summary;
  final List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow> summaryRows;
  final bool loading;
  final bool hasSummaryRows;
  final String? activeClassificacao;
  final bool hasActiveDetailFilters;
  final VoidCallback? onClearFilters;
  final VoidCallback? onOpenFilters;
  final VoidCallback? onClearClassificacaoFilter;
  final ValueChanged<String>? onClassificacaoSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final colors = context.appColors;
    final numberFormat = NumberFormat.decimalPattern(l10n.localeName);
    final buckets = salesProdutoTendenciaMediaMovelOrderedClassBuckets(
      summaryRows,
      includeZeroCounts: true,
    );

    return AppSectionCardWithHeading(
      title: l10n.salesProdutoTendenciaMediaMovelSummaryTitle,
      subtitle: l10n.salesProdutoTendenciaMediaMovelSummarySubtitle,
      headingBottom:
          activeClassificacao != null && onClearClassificacaoFilter != null
          ? Wrap(
              spacing: tokens.gapSm,
              runSpacing: tokens.gapSm,
              children: <Widget>[
                AppTagChip(
                  icon: Icons.filter_alt_outlined,
                  label:
                      '${l10n.salesProdutoTendenciaFilterClassification}: '
                      '${produtoTendenciaMediaMovelClassificacaoLabel(l10n, activeClassificacao!)}',
                  onRemove: onClearClassificacaoFilter,
                  removeSemanticsLabel: l10n
                      .salesProdutoTendenciaMediaMovelRemoveClassificacaoFilterSemantics,
                ),
              ],
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (loading && !hasSummaryRows)
            AppSkeleton(
              enabled: true,
              loadingSemanticsLabel:
                  l10n.salesProdutoTendenciaMediaMovelChartNavLoadingSemantics,
              child: _MediaMovelSummaryKpiStrip(
                l10n: l10n,
                summary: buildSalesProdutoTendenciaMediaMovelSummary(
                  const <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[],
                ),
                colors: colors,
                numberFormat: numberFormat,
                onClassificacaoSelected: onClassificacaoSelected,
              ),
            )
          else if (!hasSummaryRows)
            SalesProdutoTendenciaFilteredEmptyState(
              l10n: l10n,
              message: l10n.salesProdutoTendenciaMediaMovelNoData,
              hasActiveDetailFilters: hasActiveDetailFilters,
              onClearFilters: onClearFilters,
              onOpenFilters: onOpenFilters,
            )
          else
            AppSkeleton(
              enabled: loading,
              loadingSemanticsLabel:
                  l10n.salesProdutoTendenciaMediaMovelChartNavLoadingSemantics,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _MediaMovelSummaryKpiStrip(
                    l10n: l10n,
                    summary: summary,
                    colors: colors,
                    numberFormat: numberFormat,
                    onClassificacaoSelected: onClassificacaoSelected,
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  Text(
                    salesProdutoTendenciaMediaMovelClassificacaoOneLineLegend(
                      l10n,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  buildSalesProdutoTendenciaMediaMovelClassificacaoBarChart(
                    context: context,
                    l10n: l10n,
                    buckets: buckets,
                    countFormat: numberFormat,
                    heightOverride: tokens.chartCompactHeight,
                    onBucketTap: onClassificacaoSelected == null
                        ? null
                        : (bucket) =>
                              onClassificacaoSelected!(bucket.classificacao),
                    belowSubtitle: Text(
                      l10n.salesProdutoTendenciaMediaMovelSummaryByClassificacaoDrillDownHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaMovelSummaryKpiStrip extends StatelessWidget {
  const _MediaMovelSummaryKpiStrip({
    required this.l10n,
    required this.summary,
    required this.colors,
    required this.numberFormat,
    this.onClassificacaoSelected,
  });

  final AppLocalizations l10n;
  final SalesProdutoTendenciaMediaMovelSummary summary;
  final AppColors colors;
  final NumberFormat numberFormat;
  final ValueChanged<String>? onClassificacaoSelected;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveMetricStatGrid(
      extraWideColumns: 5,
      children: <Widget>[
        _classificacaoKpi(
          icon: Icons.trending_up_rounded,
          label: l10n.salesProdutoTendenciaMediaMovelKpiGrowing,
          value: numberFormat.format(summary.countGrowing),
          iconForeground: colors.tertiary,
          classificacao: 'CRESCENDO',
          emphasis: AppMetricStatCardEmphasis.hero,
        ),
        _classificacaoKpi(
          icon: Icons.trending_down_rounded,
          label: l10n.salesProdutoTendenciaMediaMovelKpiFalling,
          value: numberFormat.format(summary.countFalling),
          iconForeground: colors.error,
          classificacao: 'CAINDO',
        ),
        _classificacaoKpi(
          icon: Icons.new_releases_outlined,
          label: l10n.salesProdutoTendenciaMediaMovelKpiNewProducts,
          value: numberFormat.format(summary.countNew),
          iconForeground: colors.primary,
          classificacao: 'NOVO',
        ),
        _classificacaoKpi(
          icon: Icons.pause_circle_outline_rounded,
          label: l10n.salesProdutoTendenciaMediaMovelKpiStopped,
          value: numberFormat.format(summary.countStopped),
          iconForeground: colors.onSurfaceVariant,
          classificacao: 'PAROU',
        ),
        SalesProdutoTendenciaKpiCard(
          icon: Icons.balance_rounded,
          label: l10n.salesProdutoTendenciaMediaMovelKpiNetImpact,
          value: numberFormat.format(summary.netImpact),
          iconForeground: summary.netImpact >= 0
              ? colors.tertiary
              : colors.error,
        ),
      ],
    );
  }

  Widget _classificacaoKpi({
    required IconData icon,
    required String label,
    required String value,
    required Color iconForeground,
    required String classificacao,
    AppMetricStatCardEmphasis emphasis = AppMetricStatCardEmphasis.standard,
  }) {
    final classLabel = produtoTendenciaMediaMovelClassificacaoLabel(
      l10n,
      classificacao,
    );
    return SalesProdutoTendenciaKpiCard(
      icon: icon,
      label: label,
      value: value,
      iconForeground: iconForeground,
      emphasis: emphasis,
      onTap: onClassificacaoSelected == null
          ? null
          : () => onClassificacaoSelected!(classificacao),
      semanticsLabel: onClassificacaoSelected == null
          ? null
          : l10n.salesProdutoTendenciaMediaMovelKpiFilterSemantics(classLabel),
    );
  }
}

class SalesProdutoTendenciaMediaMovelCountChartSection extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelCountChartSection({
    required this.l10n,
    required this.buckets,
    this.shareKey,
    this.onShare,
    super.key,
  });

  final AppLocalizations l10n;
  final List<SalesProdutoTendenciaMediaMovelClassBucket> buckets;
  final Key? shareKey;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final locale = Localizations.localeOf(context).toLanguageTag();

    final colors = Theme.of(context).appColors;
    final chart = AppComparisonBarChart<SalesProdutoTendenciaMediaMovelClassBucket>(
      title: l10n.salesProdutoTendenciaMediaMovelSummaryByClassificacaoTitle,
      subtitle:
          l10n.salesProdutoTendenciaMediaMovelSummaryByClassificacaoSubtitle,
      items: buckets,
      labelBuilder: (bucket) => produtoTendenciaMediaMovelClassificacaoLabel(
        l10n,
        bucket.classificacao,
      ),
      valueBuilder: (bucket) => bucket.count,
      colorBuilder: (bucket) =>
          salesProdutoTendenciaMediaMovelClassificacaoColor(
            colors,
            bucket.classificacao,
          ),
      onShare: onShare,
      shareProgressKey: shareKey,
      dataLabelBuilder: (bucket, value) => '${bucket.count}',
      tooltipLabelBuilder: (bucket, value) =>
          '${produtoTendenciaMediaMovelClassificacaoLabel(l10n, bucket.classificacao)}: '
          '${bucket.count}',
      style: salesTrendHomeLikeComparisonBarChartStyle(
        tokens: tokens,
        l10n: l10n,
        yAxisFormat: NumberFormat.compact(locale: locale),
      ),
      emptyPlaceholder: AppSectionCard(
        child: Text(l10n.salesProdutoTendenciaMediaMovelNoData),
      ),
    );
    if (shareKey == null) {
      return chart;
    }
    return RepaintBoundary(key: shareKey, child: chart);
  }
}

class SalesProdutoTendenciaMediaMovelImpactChartSection
    extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelImpactChartSection({
    required this.l10n,
    required this.buckets,
    this.shareKey,
    this.onShare,
    super.key,
  });

  final AppLocalizations l10n;
  final List<SalesProdutoTendenciaMediaMovelClassBucket> buckets;
  final Key? shareKey;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final decimalFormat = NumberFormat.decimalPattern(l10n.localeName);

    final colors = Theme.of(context).appColors;
    final chart = AppComparisonBarChart<SalesProdutoTendenciaMediaMovelClassBucket>(
      title: l10n.salesProdutoTendenciaMediaMovelSummaryByImpactTitle,
      subtitle: l10n.salesProdutoTendenciaMediaMovelSummaryByImpactSubtitle,
      items: buckets,
      labelBuilder: (bucket) => produtoTendenciaMediaMovelClassificacaoLabel(
        l10n,
        bucket.classificacao,
      ),
      valueBuilder: (bucket) => bucket.impacto,
      colorBuilder: (bucket) =>
          salesProdutoTendenciaMediaMovelClassificacaoColor(
            colors,
            bucket.classificacao,
          ),
      onShare: onShare,
      shareProgressKey: shareKey,
      dataLabelBuilder: (bucket, value) => decimalFormat.format(bucket.impacto),
      tooltipLabelBuilder: (bucket, value) =>
          '${produtoTendenciaMediaMovelClassificacaoLabel(l10n, bucket.classificacao)}: '
          '${decimalFormat.format(bucket.impacto)}',
      style: salesTrendHomeLikeComparisonBarChartStyle(
        tokens: tokens,
        l10n: l10n,
        yAxisFormat: NumberFormat.compact(locale: locale),
        minPlottedValueShareOfMax: 0,
      ),
      emptyPlaceholder: AppSectionCard(
        child: Text(l10n.salesProdutoTendenciaMediaMovelNoData),
      ),
    );
    if (shareKey == null) {
      return chart;
    }
    return RepaintBoundary(key: shareKey, child: chart);
  }
}
