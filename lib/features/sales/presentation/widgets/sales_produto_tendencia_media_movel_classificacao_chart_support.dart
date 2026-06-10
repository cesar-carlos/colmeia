import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_classificacao_labels.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_summary_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_trend_comparison_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const List<String> kSalesProdutoTendenciaMediaMovelClassificacaoDisplayOrder =
    <String>[
      'CRESCENDO',
      'CAINDO',
      'NOVO',
      'PAROU',
      'ESTAVEL',
    ];

List<SalesProdutoTendenciaMediaMovelClassBucket>
salesProdutoTendenciaMediaMovelOrderedClassBuckets(
  List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow> summaryRows, {
  bool includeZeroCounts = false,
}) {
  final summary = buildSalesProdutoTendenciaMediaMovelSummary(summaryRows);
  final byClassificacao = <String, SalesProdutoTendenciaMediaMovelClassBucket>{
    for (final bucket in summary.buckets) bucket.classificacao: bucket,
  };

  final ordered = <SalesProdutoTendenciaMediaMovelClassBucket>[];
  for (final classificacao
      in kSalesProdutoTendenciaMediaMovelClassificacaoDisplayOrder) {
    final bucket = byClassificacao[classificacao];
    if (bucket != null) {
      ordered.add(bucket);
      continue;
    }
    if (includeZeroCounts) {
      ordered.add(
        SalesProdutoTendenciaMediaMovelClassBucket(
          classificacao: classificacao,
          count: 0,
          impacto: 0,
        ),
      );
    }
  }
  return ordered;
}

Color salesProdutoTendenciaMediaMovelClassificacaoColor(
  AppColors colors,
  String classificacao,
) {
  return switch (classificacao.trim().toUpperCase()) {
    'CRESCENDO' => colors.tertiary,
    'CAINDO' => colors.error,
    'NOVO' => colors.primary,
    'PAROU' => colors.onSurfaceVariant,
    'ESTAVEL' => colors.outline,
    _ => colors.primary,
  };
}

String salesProdutoTendenciaMediaMovelClassificacaoOneLineLegend(
  AppLocalizations l10n,
) {
  return l10n.salesProdutoTendenciaMediaMovelSummaryClassificacaoLegend;
}

String salesProdutoTendenciaMediaMovelClassificacaoDescription(
  AppLocalizations l10n,
  String classificacao,
) {
  return switch (classificacao.trim().toUpperCase()) {
    'CRESCENDO' => l10n.salesProdutoTendenciaMediaMovelClassificacaoDescGrowing,
    'CAINDO' => l10n.salesProdutoTendenciaMediaMovelClassificacaoDescFalling,
    'NOVO' => l10n.salesProdutoTendenciaMediaMovelClassificacaoDescNew,
    'PAROU' => l10n.salesProdutoTendenciaMediaMovelClassificacaoDescStopped,
    'ESTAVEL' => l10n.salesProdutoTendenciaMediaMovelClassificacaoDescStable,
    _ => '',
  };
}

String salesProdutoTendenciaMediaMovelClassificacaoPdfLegend(
  AppLocalizations l10n,
  List<SalesProdutoTendenciaMediaMovelClassBucket> buckets,
) {
  if (buckets.isEmpty) {
    return salesProdutoTendenciaMediaMovelClassificacaoOneLineLegend(l10n);
  }
  return buckets
      .map(
        (bucket) =>
            '${produtoTendenciaMediaMovelClassificacaoLabel(l10n, bucket.classificacao)}: '
            '${salesProdutoTendenciaMediaMovelClassificacaoDescription(l10n, bucket.classificacao)}',
      )
      .join(' · ');
}

Widget buildSalesProdutoTendenciaMediaMovelClassificacaoBarChart({
  required BuildContext context,
  required AppLocalizations l10n,
  required List<SalesProdutoTendenciaMediaMovelClassBucket> buckets,
  required NumberFormat countFormat,
  void Function(SalesProdutoTendenciaMediaMovelClassBucket bucket)? onBucketTap,
  double? heightOverride,
  Widget? belowSubtitle,
}) {
  final tokens = context.appTokens;
  final colors = Theme.of(context).appColors;

  return AppComparisonBarChart<SalesProdutoTendenciaMediaMovelClassBucket>(
    items: buckets,
    labelBuilder: (bucket) => produtoTendenciaMediaMovelClassificacaoLabel(
      l10n,
      bucket.classificacao,
    ),
    valueBuilder: (bucket) => bucket.count,
    colorBuilder: (bucket) => salesProdutoTendenciaMediaMovelClassificacaoColor(
      colors,
      bucket.classificacao,
    ),
    plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
    extremeSpreadAccessibilityNotice:
        l10n.chartComparisonExtremeValueSpreadNotice,
    style: salesTrendHomeLikeComparisonBarChartStyle(
      tokens: tokens,
      l10n: l10n,
      yAxisFormat: countFormat,
      heightOverride: heightOverride,
      minPlottedValueShareOfMax: 0.08,
    ),
    dataLabelBuilder: (bucket, _) => countFormat.format(bucket.count),
    tooltipLabelBuilder: (bucket, _) {
      final label = produtoTendenciaMediaMovelClassificacaoLabel(
        l10n,
        bucket.classificacao,
      );
      final description =
          salesProdutoTendenciaMediaMovelClassificacaoDescription(
            l10n,
            bucket.classificacao,
          );
      return '$label · ${countFormat.format(bucket.count)} · '
          '${countFormat.format(bucket.impacto.round())}\n$description';
    },
    onPointTap: onBucketTap == null ? null : (bucket, _) => onBucketTap(bucket),
    belowSubtitle: belowSubtitle,
  );
}
