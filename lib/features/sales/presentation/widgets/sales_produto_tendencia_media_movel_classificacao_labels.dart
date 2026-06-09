import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
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

String produtoTendenciaMediaMovelSortLabel(
  AppLocalizations l10n,
  ProdutoVendidoTendenciaDeVendaMediaMovelSortBy sortBy,
) {
  return switch (sortBy) {
    ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.tendenciaPercentualDesc =>
      l10n.salesProdutoTendenciaMediaMovelSortTrendPercent,
    ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.diferencaDesc =>
      l10n.salesProdutoTendenciaMediaMovelSortDifference,
    ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.nomeProdutoAsc =>
      l10n.salesProdutoTendenciaMediaMovelSortProductName,
  };
}
