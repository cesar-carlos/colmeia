import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_classificacao.dart';
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
  return switch (SalesTrendClassificacao.normalize(classificacao)) {
    SalesTrendClassificacao.crescendo =>
      l10n.salesProdutoTendenciaClassificacaoDescGrowing,
    SalesTrendClassificacao.caindo =>
      l10n.salesProdutoTendenciaClassificacaoDescFalling,
    SalesTrendClassificacao.novo =>
      l10n.salesProdutoTendenciaClassificacaoDescNew,
    SalesTrendClassificacao.parou =>
      l10n.salesProdutoTendenciaClassificacaoDescStopped,
    SalesTrendClassificacao.estavel =>
      l10n.salesProdutoTendenciaClassificacaoDescStable,
    _ => '',
  };
}
