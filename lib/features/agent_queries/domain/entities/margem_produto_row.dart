/// One product catalog line from the `MargemProduto` query: list price vs
/// replacement cost for a single company/branch (not period sales).
class MargemProdutoRow {
  const MargemProdutoRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeFilial,
    required this.codProduto,
    required this.nomeProduto,
    required this.precoVendaProduto,
    this.custoReposicao,
    this.percentualMarkupCustoCompraProduto,
    this.margemLucroProduto,
    this.nomeFantasiaFilial,
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
  final int? codGrupoProduto;
  final String? nomeGrupoProduto;
  final int? codMarca;
  final String? nomeMarca;

  /// `CustoProduto.CustoCompra` for the requested branch (`null` when missing).
  final double? custoReposicao;

  /// `Produto.PrecoVenda` (`0` when missing).
  final double precoVendaProduto;

  /// Markup on replacement cost from SQL:
  /// `null` when cost is missing; `(PrecoVenda - Custo) / Custo * 100` when
  /// both are positive; otherwise `0`.
  final double? percentualMarkupCustoCompraProduto;

  /// Gross margin from SQL:
  /// `null` when cost is missing; `(PrecoVenda - Custo) / PrecoVenda * 100`
  /// when sale price is positive; otherwise `0`.
  final double? margemLucroProduto;

  /// Absolute list-price profit: `precoVendaProduto - custoReposicao`.
  double? get lucro {
    final cost = custoReposicao;
    if (cost == null) {
      return null;
    }
    return precoVendaProduto - cost;
  }

  /// Dart recomputation of markup, used to cross-check the SQL column.
  double? get markupSobreCustoPercent {
    final cost = custoReposicao;
    final profit = lucro;
    if (cost == null || profit == null) {
      return null;
    }
    if (cost > 0 && precoVendaProduto > 0) {
      return (profit / cost) * 100;
    }
    return 0;
  }

  /// Dart recomputation of gross margin, used to cross-check the SQL column.
  double? get margemLucroBrutoPercent {
    final profit = lucro;
    if (profit == null) {
      return null;
    }
    if (precoVendaProduto > 0) {
      return (profit / precoVendaProduto) * 100;
    }
    return 0;
  }
}
