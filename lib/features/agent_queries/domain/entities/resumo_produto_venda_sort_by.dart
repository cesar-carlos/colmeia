/// Primary sort column for `ROW_NUMBER() OVER` in the resumo produto venda
/// query. `CodEmpresa` and `CodFilial` always lead in ascending order; the
/// chosen column follows with the direction from `ResumoProdutoVendaSortDirection`.
/// Remaining columns serve as stable tiebreakers.
enum ResumoProdutoVendaSortBy {
  /// Sort by product code.
  codProduto,

  /// Sort by quantity sold — most-sold products first (descending recommended).
  qtdVendas,

  /// Sort alphabetically by product name (default — empresa, filial, nome, qtdVendas DESC).
  nomeProduto,
}
