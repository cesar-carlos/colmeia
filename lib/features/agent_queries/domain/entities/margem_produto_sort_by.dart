/// Primary sort column for `ROW_NUMBER() OVER` in the product-margin catalog
/// query. Remaining tie-breakers follow a fixed `CodProduto ASC`.
enum MargemProdutoSortBy {
  /// Sort by product name (`Produto.Nome`). Default.
  nomeProduto,

  /// Sort by replacement cost (`CustoProduto.CustoCompra`).
  custoReposicao,

  /// Sort by markup on replacement cost
  /// (`(PrecoVenda - Custo) / Custo * 100`).
  percentualMarkup,

  /// Sort by gross margin
  /// (`(PrecoVenda - Custo) / PrecoVenda * 100`).
  margemLucroProduto,
}
