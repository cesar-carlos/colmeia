/// One row from the product billing ranking query.
///
/// Ranked products have `codProduto` > 0 and `posicao` set. The optional
/// DIVERSOS aggregate per branch uses `codProduto` = 0 and `posicao` null.
///
/// Expected invariants for ranked products: `percentual` in `[0, 100]` within
/// the same branch. Currency and percent formatting belong in presentation.
class RankingProdutosFaturamentoRow {
  const RankingProdutosFaturamentoRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.codProduto,
    required this.nomeProduto,
    required this.valorVenda,
    required this.percentual,
    this.posicao,
    this.codUnidadeMedida,
    this.codGrupoProduto,
    this.nomeGrupoProduto,
  });

  static const String diversosNomeProduto = 'DIVERSOS';

  final int codEmpresa;
  final int codFilial;
  final int codProduto;
  final String nomeProduto;
  final String? codUnidadeMedida;
  final int? codGrupoProduto;
  final String? nomeGrupoProduto;
  final double valorVenda;
  final double percentual;

  /// Rank position within the branch (`1` = highest [valorVenda]); null for DIVERSOS.
  final int? posicao;

  bool get isDiversos => codProduto == 0 && nomeProduto == diversosNomeProduto;
}
