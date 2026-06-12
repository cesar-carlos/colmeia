import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_media_movel_share.dart';
import 'package:colmeia/l10n/app_localizations.dart';

String produtoTendenciaMediaMovelClassificacaoLabel(
  AppLocalizations l10n,
  String value,
) {
  return switch (value.trim().toUpperCase()) {
    'CRESCENDO' => l10n.salesProdutoTendenciaMediaMovelClassificacaoGrowing,
    'CAINDO' => l10n.salesProdutoTendenciaMediaMovelClassificacaoFalling,
    'NOVO' => l10n.salesProdutoTendenciaMediaMovelClassificacaoNew,
    'PAROU' => l10n.salesProdutoTendenciaMediaMovelClassificacaoStopped,
    'ESTAVEL' => l10n.salesProdutoTendenciaMediaMovelClassificacaoStable,
    _ => l10n.salesProdutoTendenciaFilterAllOption,
  };
}

String salesProdutoTendenciaMediaMovelClassificacaoOneLineLegend(
  AppLocalizations l10n,
) {
  return l10n.salesProdutoTendenciaMediaMovelSummaryClassificacaoLegend;
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
