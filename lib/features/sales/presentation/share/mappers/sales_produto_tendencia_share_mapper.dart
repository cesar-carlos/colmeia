import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_share.dart';
import 'package:colmeia/l10n/app_localizations.dart';

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
