import 'package:colmeia/features/sales/domain/sales_card_descriptor.dart';
import 'package:colmeia/l10n/app_localizations.dart';

extension SalesCardDescriptorL10n on SalesCardDescriptor {
  String resolvedTitle(AppLocalizations l10n) {
    return switch (id) {
      'produto_rank_lucro' => l10n.salesCardProdutoRankLucroTitle,
      'ranking_produtos_faturamento' =>
        l10n.salesCardRankingProdutosFaturamentoTitle,
      'margem_produto' => l10n.salesCardMargemProdutoTitle,
      'monthly_pnl' => l10n.salesCardMonthlyPnlTitle,
      'resumo_total_diario_vendas' =>
        l10n.salesCardResumoTotalDiarioVendasTitle,
      'produto_tendencia_venda' => l10n.salesCardProdutoTendenciaTitle,
      'produto_tendencia_venda_media_movel' =>
        l10n.salesCardProdutoTendenciaMediaMovelTitle,
      _ => id,
    };
  }
}
