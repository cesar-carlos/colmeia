import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_share.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_trend_comparison_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Minimum KPI card width in the trend summary strip.
const double kSalesProdutoTendenciaKpiMinCardWidth = 176;

class SalesProdutoTendenciaSummarySection extends StatelessWidget {
  const SalesProdutoTendenciaSummarySection({
    required this.l10n,
    required this.summaryRows,
    required this.loading,
    required this.periodoAtual,
    required this.periodoAnterior,
    required this.periodoAtualDescriptor,
    required this.periodoAnteriorDescriptor,
    required this.classLabelBuilder,
    required this.onOpenClassificacaoFullscreen,
    required this.classificacaoShareKey,
    required this.onShareClassificacao,
    super.key,
  });

  final AppLocalizations l10n;
  final List<ProdutoVendidoTendenciaDeVendaSummaryRow> summaryRows;
  final bool loading;
  final DateTimeRange periodoAtual;
  final DateTimeRange periodoAnterior;
  final String periodoAtualDescriptor;
  final String periodoAnteriorDescriptor;
  final String Function(String value) classLabelBuilder;
  final VoidCallback onOpenClassificacaoFullscreen;
  final GlobalKey classificacaoShareKey;
  final VoidCallback? onShareClassificacao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final colors = theme.appColors;
    final summary = buildSalesProdutoTendenciaSummary(summaryRows);
    final chartBlockHeight = AppComparisonBarChart.loadingBlockHeight(tokens);

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _TrendSummaryKpiStrip(
                    l10n: l10n,
                    summary: buildSalesProdutoTendenciaSummary(
                      const <ProdutoVendidoTendenciaDeVendaSummaryRow>[],
                    ),
                    tokens: tokens,
                    colors: colors,
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  SizedBox(
                    height: chartBlockHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.salesProdutoTendenciaSummaryByClassificacaoTitle,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (summaryRows.isEmpty)
            Text(
              l10n.salesProdutoTendenciaNoData,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else ...<Widget>[
            _TrendSummaryKpiStrip(
              l10n: l10n,
              summary: summary,
              tokens: tokens,
              colors: colors,
            ),
            SizedBox(height: tokens.contentSpacing),
            RepaintBoundary(
              key: classificacaoShareKey,
              child: AppComparisonBarChart<SalesProdutoTendenciaClassBucket>(
                title: l10n.salesProdutoTendenciaSummaryByClassificacaoTitle,
                subtitle:
                    l10n.salesProdutoTendenciaSummaryByClassificacaoSubtitle,
                items: summary.buckets,
                labelBuilder: (bucket) =>
                    classLabelBuilder(bucket.classificacao),
                valueBuilder: (bucket) => bucket.count,
                onShare: onShareClassificacao,
                onOpenFullscreen: onOpenClassificacaoFullscreen,
                openFullscreenTooltip: l10n.chartOpenFullscreenTooltip,
                openFullscreenSemanticLabel: l10n.chartOpenFullscreenTooltip,
                plotFloorAccessibilityNotice:
                    l10n.chartComparisonPlotFloorNotice,
                extremeSpreadAccessibilityNotice:
                    l10n.chartComparisonExtremeValueSpreadNotice,
                style: salesTrendHomeLikeComparisonBarChartStyle(
                  tokens: tokens,
                  l10n: l10n,
                  yAxisFormat: NumberFormat.decimalPattern(l10n.localeName),
                ),
                dataLabelBuilder: (bucket, value) =>
                    NumberFormat.decimalPattern(l10n.localeName).format(
                      bucket.count,
                    ),
                tooltipLabelBuilder: (bucket, value) =>
                    '${classLabelBuilder(bucket.classificacao)} • '
                    '${bucket.count} • '
                    '${NumberFormat.decimalPattern(l10n.localeName).format(bucket.impacto.round())}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendSummaryKpiStrip extends StatelessWidget {
  const _TrendSummaryKpiStrip({
    required this.l10n,
    required this.summary,
    required this.tokens,
    required this.colors,
  });

  final AppLocalizations l10n;
  final SalesProdutoTendenciaSummary summary;
  final AppThemeTokens tokens;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final locale = l10n.localeName;
    final nf = NumberFormat.decimalPattern(locale);
    final cards = <_TrendSummaryKpiCard>[
      _TrendSummaryKpiCard(
        icon: Icons.trending_up_rounded,
        label: l10n.salesProdutoTendenciaKpiGrowing,
        value: nf.format(summary.countGrowing),
        iconColor: colors.tertiary,
      ),
      _TrendSummaryKpiCard(
        icon: Icons.trending_down_rounded,
        label: l10n.salesProdutoTendenciaKpiFalling,
        value: nf.format(summary.countFalling),
        iconColor: colors.error,
      ),
      _TrendSummaryKpiCard(
        icon: Icons.new_releases_outlined,
        label: l10n.salesProdutoTendenciaKpiNewProducts,
        value: nf.format(summary.countNew),
        iconColor: colors.primary,
      ),
      _TrendSummaryKpiCard(
        icon: Icons.pause_circle_outline_rounded,
        label: l10n.salesProdutoTendenciaKpiStopped,
        value: nf.format(summary.countStopped),
        iconColor: colors.onSurfaceVariant,
      ),
      _TrendSummaryKpiCard(
        icon: Icons.horizontal_rule_rounded,
        label: l10n.salesProdutoTendenciaKpiStable,
        value: nf.format(summary.countStable),
        iconColor: colors.onSurfaceVariant,
      ),
      _TrendSummaryKpiCard(
        icon: Icons.balance_rounded,
        label: l10n.salesProdutoTendenciaKpiNetImpact,
        value: nf.format(summary.netImpact),
        iconColor: summary.netImpact >= 0 ? colors.tertiary : colors.error,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = tokens.gapMd;
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth.isFinite && maxWidth > 0
            ? ((maxWidth + spacing) /
                      (kSalesProdutoTendenciaKpiMinCardWidth + spacing))
                  .floor()
                  .clamp(1, cards.length)
            : cards.length;
        final cardWidth = maxWidth.isFinite && maxWidth > 0
            ? (maxWidth - (spacing * (columns - 1))) / columns
            : kSalesProdutoTendenciaKpiMinCardWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(width: cardWidth, child: card),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _TrendSummaryKpiCard extends StatelessWidget {
  const _TrendSummaryKpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return AppMetricStatCard(
      leading: Icon(icon, color: iconColor),
      label: label,
      value: value,
    );
  }
}
