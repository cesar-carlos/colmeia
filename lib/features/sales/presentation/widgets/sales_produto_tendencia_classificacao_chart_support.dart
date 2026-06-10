import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_share.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_trend_comparison_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Display order aligned with the executive summary KPI strip.
const List<String> kSalesProdutoTendenciaClassificacaoDisplayOrder = <String>[
  'CRESCENDO',
  'CAINDO',
  'NOVO PRODUTO',
  'PAROU DE VENDER',
  'ESTAVEL',
];

List<SalesProdutoTendenciaClassBucket> salesProdutoTendenciaOrderedClassBuckets(
  List<ProdutoVendidoTendenciaDeVendaSummaryRow> summaryRows, {
  bool includeZeroCounts = false,
}) {
  final summary = buildSalesProdutoTendenciaSummary(summaryRows);
  final byClassificacao = <String, SalesProdutoTendenciaClassBucket>{
    for (final bucket in summary.buckets) bucket.classificacao: bucket,
  };

  final ordered = <SalesProdutoTendenciaClassBucket>[];
  for (final classificacao in kSalesProdutoTendenciaClassificacaoDisplayOrder) {
    final bucket = byClassificacao[classificacao];
    if (bucket != null) {
      ordered.add(bucket);
      continue;
    }
    if (includeZeroCounts) {
      ordered.add(
        SalesProdutoTendenciaClassBucket(
          classificacao: classificacao,
          count: 0,
          impacto: 0,
        ),
      );
    }
  }
  return ordered;
}

Color salesProdutoTendenciaClassificacaoColor(
  AppColors colors,
  String classificacao,
) {
  return switch (classificacao.trim().toUpperCase()) {
    'CRESCENDO' => colors.tertiary,
    'CAINDO' => colors.error,
    'NOVO PRODUTO' => colors.primary,
    'PAROU DE VENDER' => colors.onSurfaceVariant,
    'ESTAVEL' => colors.outline,
    _ => colors.primary,
  };
}

String salesProdutoTendenciaClassificacaoOneLineLegend(AppLocalizations l10n) {
  return l10n.salesProdutoTendenciaSummaryClassificacaoLegend;
}

String salesProdutoTendenciaClassificacaoPdfLegend(
  AppLocalizations l10n,
  List<SalesProdutoTendenciaClassBucket> buckets,
) {
  if (buckets.isEmpty) {
    return salesProdutoTendenciaClassificacaoOneLineLegend(l10n);
  }
  return buckets
      .map(
        (bucket) =>
            '${salesProdutoTendenciaClassificacaoLabel(l10n, bucket.classificacao)}: '
            '${salesProdutoTendenciaClassificacaoDescription(l10n, bucket.classificacao)}',
      )
      .join(' · ');
}

String salesProdutoTendenciaClassificacaoDescription(
  AppLocalizations l10n,
  String classificacao,
) {
  return switch (classificacao.trim().toUpperCase()) {
    'CRESCENDO' => l10n.salesProdutoTendenciaClassificacaoDescGrowing,
    'CAINDO' => l10n.salesProdutoTendenciaClassificacaoDescFalling,
    'NOVO PRODUTO' => l10n.salesProdutoTendenciaClassificacaoDescNew,
    'PAROU DE VENDER' => l10n.salesProdutoTendenciaClassificacaoDescStopped,
    'ESTAVEL' => l10n.salesProdutoTendenciaClassificacaoDescStable,
    _ => '',
  };
}

AppComparisonBarChartStyle salesTrendClassificacaoComparisonBarChartStyle({
  required AppThemeTokens tokens,
  required AppLocalizations l10n,
  required NumberFormat yAxisFormat,
  double? heightOverride,
}) {
  return salesTrendHomeLikeComparisonBarChartStyle(
    tokens: tokens,
    l10n: l10n,
    yAxisFormat: yAxisFormat,
    heightOverride: heightOverride,
    minPlottedValueShareOfMax: 0.08,
  );
}

class SalesProdutoTendenciaClassificacaoLegend extends StatelessWidget {
  const SalesProdutoTendenciaClassificacaoLegend({
    required this.l10n,
    required this.buckets,
    super.key,
  });

  final AppLocalizations l10n;
  final List<SalesProdutoTendenciaClassBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final colors = theme.appColors;
    final bodyStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.salesProdutoTendenciaSummaryByClassificacaoDrillDownHint,
          style: bodyStyle,
        ),
        if (buckets.isNotEmpty) ...<Widget>[
          SizedBox(height: tokens.gapSm),
          Wrap(
            spacing: tokens.gapMd,
            runSpacing: tokens.gapXs,
            children: <Widget>[
              for (final bucket in buckets)
                _LegendEntry(
                  color: salesProdutoTendenciaClassificacaoColor(
                    colors,
                    bucket.classificacao,
                  ),
                  label: salesProdutoTendenciaClassificacaoLabel(
                    l10n,
                    bucket.classificacao,
                  ),
                  description: salesProdutoTendenciaClassificacaoDescription(
                    l10n,
                    bucket.classificacao,
                  ),
                  bodyStyle: bodyStyle,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.color,
    required this.label,
    required this.description,
    required this.bodyStyle,
  });

  final Color color;
  final String label;
  final String description;
  final TextStyle? bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label. $description',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text.rich(
              TextSpan(
                style: bodyStyle,
                children: <InlineSpan>[
                  TextSpan(
                    text: label,
                    style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ': $description'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildSalesProdutoTendenciaClassificacaoBarChart({
  required BuildContext context,
  required AppLocalizations l10n,
  required List<SalesProdutoTendenciaClassBucket> buckets,
  required NumberFormat countFormat,
  void Function(SalesProdutoTendenciaClassBucket bucket)? onBucketTap,
  double? heightOverride,
  Widget? belowSubtitle,
  VoidCallback? onShare,
  Key? shareProgressKey,
}) {
  final tokens = context.appTokens;
  final colors = Theme.of(context).appColors;

  return AppComparisonBarChart<SalesProdutoTendenciaClassBucket>(
    items: buckets,
    labelBuilder: (bucket) =>
        salesProdutoTendenciaClassificacaoLabel(l10n, bucket.classificacao),
    valueBuilder: (bucket) => bucket.count,
    colorBuilder: (bucket) => salesProdutoTendenciaClassificacaoColor(
      colors,
      bucket.classificacao,
    ),
    plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
    extremeSpreadAccessibilityNotice:
        l10n.chartComparisonExtremeValueSpreadNotice,
    style: salesTrendClassificacaoComparisonBarChartStyle(
      tokens: tokens,
      l10n: l10n,
      yAxisFormat: countFormat,
      heightOverride: heightOverride,
    ),
    dataLabelBuilder: (bucket, _) => countFormat.format(bucket.count),
    tooltipLabelBuilder: (bucket, _) {
      final label = salesProdutoTendenciaClassificacaoLabel(
        l10n,
        bucket.classificacao,
      );
      final description = salesProdutoTendenciaClassificacaoDescription(
        l10n,
        bucket.classificacao,
      );
      return '$label · ${countFormat.format(bucket.count)} · '
          '${countFormat.format(bucket.impacto.round())}\n$description';
    },
    onPointTap: onBucketTap == null ? null : (bucket, _) => onBucketTap(bucket),
    belowSubtitle: belowSubtitle,
    onShare: onShare,
    shareProgressKey: shareProgressKey,
  );
}
