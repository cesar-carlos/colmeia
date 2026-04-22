/// Coluna da métrica no `ROW_NUMBER() OVER`, após `CodEmpresa`/`CodFilial`
/// ASC; a direção vem de `ResumoProdutoVendaSortDirection`. Desempates: colunas
/// do agrupamento em ASC.
enum ResumoProdutoVendaSortBy {
  qtdVendas,
  qtdItensVendido,
  percentualLucro,
}
