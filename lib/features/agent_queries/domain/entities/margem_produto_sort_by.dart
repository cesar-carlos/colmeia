/// Primary sort column for `ROW_NUMBER() OVER` in the product-margin catalog.
///
/// Identifiers are interpolated from this whitelist only — never from user
/// input. Tie-breakers are `NomeProduto` then `CodProduto` (omitted when they
/// are already the primary column).
enum MargemProdutoSortBy {
  codProduto,
  nomeProduto,
  nomeGrupoProduto,
  nomeMarca,
  custoReposicao,
  precoVendaProduto,
  percentualMarkup,
  margemLucro,
}
