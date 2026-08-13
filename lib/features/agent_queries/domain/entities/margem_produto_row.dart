/// One product catalog line from the `MargemProduto` query: list price vs
/// replacement cost for a single company/branch (not period sales).
class MargemProdutoRow {
  const MargemProdutoRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeFilial,
    required this.codProduto,
    required this.nomeProduto,
    required this.custoReposicao,
    required this.precoVendaProduto,
    required this.percentualMarkupCustoCompraProduto,
    required this.margemLucroProduto,
    this.nomeFantasiaFilial,
    this.codUnidadeMedida,
    this.descricaoUnidadeMedida,
    this.codGrupoProduto,
    this.nomeGrupoProduto,
    this.codMarca,
    this.nomeMarca,
  });

  final int codEmpresa;
  final int codFilial;
  final String nomeFilial;
  final String? nomeFantasiaFilial;
  final int codProduto;
  final String nomeProduto;

  /// `Produto.CodUnidadeMedida` is a varchar unit code (`UN`, `P`), not an
  /// integer FK.
  final String? codUnidadeMedida;
  final String? descricaoUnidadeMedida;
  final int? codGrupoProduto;
  final String? nomeGrupoProduto;
  final int? codMarca;
  final String? nomeMarca;

  /// `CustoProduto.CustoCompra` for the requested branch (`0` when missing).
  final double custoReposicao;

  /// `Produto.PrecoVenda` (`0` when missing).
  final double precoVendaProduto;

  /// Markup on replacement cost from SQL:
  /// `(PrecoVenda - Custo) / Custo * 100` when both are positive, else `0`.
  final double percentualMarkupCustoCompraProduto;

  /// Gross margin from SQL:
  /// `(PrecoVenda - Custo) / PrecoVenda * 100` when sale price is positive,
  /// else `0`.
  final double margemLucroProduto;

  /// Absolute list-price profit: `precoVendaProduto - custoReposicao`.
  double get lucro => precoVendaProduto - custoReposicao;

  /// Dart recomputation of markup, used to cross-check the SQL column.
  double get markupSobreCustoPercent {
    if (custoReposicao > 0 && precoVendaProduto > 0) {
      return (lucro / custoReposicao) * 100;
    }
    return 0;
  }

  /// Dart recomputation of gross margin, used to cross-check the SQL column.
  double get margemLucroBrutoPercent {
    if (precoVendaProduto > 0) {
      return (lucro / precoVendaProduto) * 100;
    }
    return 0;
  }
}
