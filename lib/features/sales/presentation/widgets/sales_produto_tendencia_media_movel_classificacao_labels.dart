import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/l10n/app_localizations.dart';

export 'package:colmeia/features/sales/presentation/share/mappers/sales_produto_tendencia_media_movel_share_mapper.dart'
    show produtoTendenciaMediaMovelClassificacaoLabel;

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
