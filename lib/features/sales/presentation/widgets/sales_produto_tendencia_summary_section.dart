import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_share.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_classificacao_chart_support.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_filtered_empty_state.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_kpi_card.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_card.dart';
import 'package:colmeia/shared/widgets/metrics/app_responsive_metric_stat_grid.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesProdutoTendenciaSummarySection extends StatelessWidget {
  const SalesProdutoTendenciaSummarySection({
    required this.l10n,
    required this.summaryRows,
    required this.loading,
    required this.periodoAtual,
    required this.periodoAnterior,
    required this.periodoAtualDescriptor,
    required this.periodoAnteriorDescriptor,
    super.key,
    this.activeClassificacao,
    this.hasActiveDetailFilters = false,
    this.onClearFilters,
    this.onOpenFilters,
    this.onClearClassificacaoFilter,
    this.onClassificacaoSelected,
    this.classificacaoShareKey,
    this.onShareClassificacao,
  });

  final AppLocalizations l10n;
  final List<ProdutoVendidoTendenciaDeVendaSummaryRow> summaryRows;
  final bool loading;
  final DateTimeRange periodoAtual;
  final DateTimeRange periodoAnterior;
  final String periodoAtualDescriptor;
  final String periodoAnteriorDescriptor;
  final String? activeClassificacao;
  final bool hasActiveDetailFilters;
  final VoidCallback? onClearFilters;
  final VoidCallback? onOpenFilters;
  final VoidCallback? onClearClassificacaoFilter;
  final ValueChanged<String>? onClassificacaoSelected;
  final Key? classificacaoShareKey;
  final VoidCallback? onShareClassificacao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final colors = theme.appColors;
    final summary = buildSalesProdutoTendenciaSummary(summaryRows);
    final buckets = salesProdutoTendenciaOrderedClassBuckets(
      summaryRows,
      includeZeroCounts: true,
    );
    final countFormat = NumberFormat.decimalPattern(l10n.localeName);

    return AppSectionCardWithHeading(
      title: l10n.salesProdutoTendenciaSummaryTitle,
      subtitle: l10n.salesProdutoTendenciaSummarySubtitle,
      headingBottom: Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: <Widget>[
          AppTagChip(
            icon: Icons.timeline_rounded,
            label:
                '${l10n.salesProdutoTendenciaComparisonCurrentChip}: '
                '${AppBrFormatters.shortDate(periodoAtual.start)} - '
                '${AppBrFormatters.shortDate(periodoAtual.end)} • '
                '$periodoAtualDescriptor',
          ),
          AppTagChip(
            icon: Icons.history_rounded,
            label:
                '${l10n.salesProdutoTendenciaComparisonPreviousChip}: '
                '${AppBrFormatters.shortDate(periodoAnterior.start)} - '
                '${AppBrFormatters.shortDate(periodoAnterior.end)} • '
                '$periodoAnteriorDescriptor',
          ),
          if (activeClassificacao != null && onClearClassificacaoFilter != null)
            AppTagChip(
              icon: Icons.filter_alt_outlined,
              label:
                  '${l10n.salesProdutoTendenciaFilterClassification}: '
                  '${salesProdutoTendenciaClassificacaoLabel(l10n, activeClassificacao)}',
              onRemove: onClearClassificacaoFilter,
              removeSemanticsLabel:
                  l10n.salesProdutoTendenciaRemoveClassificacaoFilterSemantics,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (loading && summaryRows.isEmpty)
            AppSkeleton(
              enabled: true,
              loadingSemanticsLabel:
                  l10n.salesProdutoTendenciaLoadingTrendSemantics,
              child: _TrendSummaryKpiStrip(
                l10n: l10n,
                summary: buildSalesProdutoTendenciaSummary(
                  const <ProdutoVendidoTendenciaDeVendaSummaryRow>[],
                ),
                colors: colors,
                onClassificacaoSelected: onClassificacaoSelected,
              ),
            )
          else if (summaryRows.isEmpty)
            SalesProdutoTendenciaFilteredEmptyState(
              l10n: l10n,
              message: l10n.salesProdutoTendenciaNoData,
              hasActiveDetailFilters: hasActiveDetailFilters,
              onClearFilters: onClearFilters,
              onOpenFilters: onOpenFilters,
            )
          else
            AppSkeleton(
              enabled: loading,
              loadingSemanticsLabel:
                  l10n.salesProdutoTendenciaLoadingTrendSemantics,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _TrendSummaryKpiStrip(
                    l10n: l10n,
                    summary: summary,
                    colors: colors,
                    onClassificacaoSelected: onClassificacaoSelected,
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  Text(
                    salesProdutoTendenciaClassificacaoOneLineLegend(l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  RepaintBoundary(
                    key: classificacaoShareKey,
                    child: buildSalesProdutoTendenciaClassificacaoBarChart(
                      context: context,
                      l10n: l10n,
                      buckets: buckets,
                      countFormat: countFormat,
                      heightOverride: tokens.chartCompactHeight,
                      onBucketTap: onClassificacaoSelected == null
                          ? null
                          : (bucket) =>
                                onClassificacaoSelected!(bucket.classificacao),
                      belowSubtitle: Text(
                        l10n.salesProdutoTendenciaSummaryByClassificacaoDrillDownHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onShare: loading || summaryRows.isEmpty
                          ? null
                          : onShareClassificacao,
                      shareProgressKey: classificacaoShareKey,
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

class _TrendSummaryKpiStrip extends StatelessWidget {
  const _TrendSummaryKpiStrip({
    required this.l10n,
    required this.summary,
    required this.colors,
    this.onClassificacaoSelected,
  });

  final AppLocalizations l10n;
  final SalesProdutoTendenciaSummary summary;
  final AppColors colors;
  final ValueChanged<String>? onClassificacaoSelected;

  @override
  Widget build(BuildContext context) {
    final locale = l10n.localeName;
    final nf = NumberFormat.decimalPattern(locale);
    return AppResponsiveMetricStatGrid(
      extraWideColumns: 6,
      children: <Widget>[
        _classificacaoKpi(
          icon: Icons.trending_up_rounded,
          label: l10n.salesProdutoTendenciaKpiGrowing,
          value: nf.format(summary.countGrowing),
          iconForeground: colors.tertiary,
          classificacao: 'CRESCENDO',
          emphasis: AppMetricStatCardEmphasis.hero,
        ),
        _classificacaoKpi(
          icon: Icons.trending_down_rounded,
          label: l10n.salesProdutoTendenciaKpiFalling,
          value: nf.format(summary.countFalling),
          iconForeground: colors.error,
          classificacao: 'CAINDO',
        ),
        _classificacaoKpi(
          icon: Icons.new_releases_outlined,
          label: l10n.salesProdutoTendenciaKpiNewProducts,
          value: nf.format(summary.countNew),
          iconForeground: colors.primary,
          classificacao: 'NOVO PRODUTO',
        ),
        _classificacaoKpi(
          icon: Icons.pause_circle_outline_rounded,
          label: l10n.salesProdutoTendenciaKpiStopped,
          value: nf.format(summary.countStopped),
          iconForeground: colors.onSurfaceVariant,
          classificacao: 'PAROU DE VENDER',
        ),
        _classificacaoKpi(
          icon: Icons.horizontal_rule_rounded,
          label: l10n.salesProdutoTendenciaKpiStable,
          value: nf.format(summary.countStable),
          iconForeground: colors.onSurfaceVariant,
          classificacao: 'ESTAVEL',
        ),
        SalesProdutoTendenciaKpiCard(
          icon: Icons.balance_rounded,
          label: l10n.salesProdutoTendenciaKpiNetImpact,
          value: nf.format(summary.netImpact),
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
    final classLabel = salesProdutoTendenciaClassificacaoLabel(
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
          : l10n.salesProdutoTendenciaKpiFilterSemantics(classLabel),
    );
  }
}
