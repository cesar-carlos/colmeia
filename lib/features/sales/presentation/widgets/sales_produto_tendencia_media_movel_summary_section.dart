import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_kpi_card.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_classificacao_labels.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_section_header.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_trend_comparison_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_card.dart';
import 'package:colmeia/shared/widgets/metrics/app_responsive_metric_stat_grid.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

SalesProdutoTendenciaMediaMovelSummary
buildSalesProdutoTendenciaMediaMovelSummary(
  List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow> summaryRows,
) {
  final counts = <String, int>{};
  final impacts = <String, double>{};
  var netImpact = 0.0;

  for (final row in summaryRows) {
    final classificacao = row.classificacao.trim().toUpperCase();
    counts[classificacao] =
        (counts[classificacao] ?? 0) + row.quantidadeProdutos;
    impacts[classificacao] = (impacts[classificacao] ?? 0) + row.impactoLiquido;
    netImpact += row.impactoLiquido;
  }

  final buckets =
      counts.entries
          .map(
            (entry) => SalesProdutoTendenciaMediaMovelClassBucket(
              classificacao: entry.key,
              count: entry.value,
              impacto: impacts[entry.key] ?? 0,
            ),
          )
          .toList(growable: false)
        ..sort((a, b) => b.count.compareTo(a.count));

  return SalesProdutoTendenciaMediaMovelSummary(
    countGrowing: counts['CRESCENDO'] ?? 0,
    countFalling: counts['CAINDO'] ?? 0,
    countNew: counts['NOVO'] ?? 0,
    countStopped: counts['PAROU'] ?? 0,
    netImpact: netImpact,
    buckets: buckets,
  );
}

class SalesProdutoTendenciaMediaMovelSummary {
  const SalesProdutoTendenciaMediaMovelSummary({
    required this.countGrowing,
    required this.countFalling,
    required this.countNew,
    required this.countStopped,
    required this.netImpact,
    required this.buckets,
  });

  final int countGrowing;
  final int countFalling;
  final int countNew;
  final int countStopped;
  final double netImpact;
  final List<SalesProdutoTendenciaMediaMovelClassBucket> buckets;
}

class SalesProdutoTendenciaMediaMovelClassBucket {
  const SalesProdutoTendenciaMediaMovelClassBucket({
    required this.classificacao,
    required this.count,
    required this.impacto,
  });

  final String classificacao;
  final int count;
  final double impacto;
}

class SalesProdutoTendenciaMediaMovelLoadingSection extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelLoadingSection({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SalesProdutoTendenciaMediaMovelSectionHeader(
          title: title,
          subtitle: subtitle,
        ),
        SizedBox(height: tokens.gapMd),
        const AppSkeleton(
          enabled: true,
          child: SizedBox(
            height: 120,
            width: double.infinity,
          ),
        ),
      ],
    );
  }
}

class SalesProdutoTendenciaMediaMovelSummarySection extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelSummarySection({
    required this.l10n,
    required this.summary,
    super.key,
  });

  final AppLocalizations l10n;
  final SalesProdutoTendenciaMediaMovelSummary summary;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final colors = context.appColors;
    final numberFormat = NumberFormat.decimalPattern(l10n.localeName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SalesProdutoTendenciaMediaMovelSectionHeader(
          title: l10n.salesProdutoTendenciaMediaMovelSummaryTitle,
          subtitle: l10n.salesProdutoTendenciaMediaMovelSummarySubtitle,
        ),
        SizedBox(height: tokens.gapMd),
        AppResponsiveMetricStatGrid(
          children: <Widget>[
            SalesProdutoTendenciaKpiCard(
              icon: Icons.trending_up_rounded,
              label: l10n.salesProdutoTendenciaMediaMovelKpiGrowing,
              value: numberFormat.format(summary.countGrowing),
              iconForeground: colors.tertiary,
              emphasis: AppMetricStatCardEmphasis.hero,
            ),
            SalesProdutoTendenciaKpiCard(
              icon: Icons.trending_down_rounded,
              label: l10n.salesProdutoTendenciaMediaMovelKpiFalling,
              value: numberFormat.format(summary.countFalling),
              iconForeground: colors.error,
            ),
            SalesProdutoTendenciaKpiCard(
              icon: Icons.new_releases_outlined,
              label: l10n.salesProdutoTendenciaMediaMovelKpiNewProducts,
              value: numberFormat.format(summary.countNew),
              iconForeground: colors.primary,
            ),
            SalesProdutoTendenciaKpiCard(
              icon: Icons.pause_circle_outline_rounded,
              label: l10n.salesProdutoTendenciaMediaMovelKpiStopped,
              value: numberFormat.format(summary.countStopped),
              iconForeground: colors.onSurfaceVariant,
            ),
            SalesProdutoTendenciaKpiCard(
              icon: Icons.balance_rounded,
              label: l10n.salesProdutoTendenciaMediaMovelKpiNetImpact,
              value: numberFormat.format(summary.netImpact),
              iconForeground:
                  summary.netImpact >= 0 ? colors.tertiary : colors.error,
            ),
          ],
        ),
      ],
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

    final chart = AppComparisonBarChart<SalesProdutoTendenciaMediaMovelClassBucket>(
      title: l10n.salesProdutoTendenciaMediaMovelSummaryByImpactTitle,
      subtitle: l10n.salesProdutoTendenciaMediaMovelSummaryByImpactSubtitle,
      items: buckets,
      labelBuilder: (bucket) => produtoTendenciaMediaMovelClassificacaoLabel(
        l10n,
        bucket.classificacao,
      ),
      valueBuilder: (bucket) => bucket.impacto,
      onShare: onShare,
      shareProgressKey: shareKey,
      dataLabelBuilder: (bucket, value) =>
          decimalFormat.format(bucket.impacto),
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
