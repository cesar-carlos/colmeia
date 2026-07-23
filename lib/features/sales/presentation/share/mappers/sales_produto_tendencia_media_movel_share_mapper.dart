import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_classificacao.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_media_movel_share.dart';
import 'package:colmeia/l10n/app_localizations.dart';

String produtoTendenciaMediaMovelClassificacaoLabel(
  AppLocalizations l10n,
  String value,
) {
  return switch (SalesTrendClassificacao.normalize(value)) {
    SalesTrendClassificacao.crescendo =>
      l10n.salesProdutoTendenciaMediaMovelClassificacaoGrowing,
    SalesTrendClassificacao.caindo =>
      l10n.salesProdutoTendenciaMediaMovelClassificacaoFalling,
    SalesTrendClassificacao.novo =>
      l10n.salesProdutoTendenciaMediaMovelClassificacaoNew,
    SalesTrendClassificacao.parou =>
      l10n.salesProdutoTendenciaMediaMovelClassificacaoStopped,
    SalesTrendClassificacao.estavel =>
      l10n.salesProdutoTendenciaMediaMovelClassificacaoStable,
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
  return switch (SalesTrendClassificacao.normalize(classificacao)) {
    SalesTrendClassificacao.crescendo =>
      l10n.salesProdutoTendenciaMediaMovelClassificacaoDescGrowing,
    SalesTrendClassificacao.caindo =>
      l10n.salesProdutoTendenciaMediaMovelClassificacaoDescFalling,
    SalesTrendClassificacao.novo =>
      l10n.salesProdutoTendenciaMediaMovelClassificacaoDescNew,
    SalesTrendClassificacao.parou =>
      l10n.salesProdutoTendenciaMediaMovelClassificacaoDescStopped,
    SalesTrendClassificacao.estavel =>
      l10n.salesProdutoTendenciaMediaMovelClassificacaoDescStable,
    _ => '',
  };
}
