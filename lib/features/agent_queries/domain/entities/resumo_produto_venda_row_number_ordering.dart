/// How `ROW_NUMBER() OVER (ORDER BY …)` is built for the resumo produto venda SQL.
///
/// [ledgerDefault] — empresa/filial first (ledger-style paging). [metricGlobal]
/// — sort key first, then empresa/filial (top-N by metric across the cadastro).
enum ResumoProdutoVendaRowNumberOrdering {
  ledgerDefault,
  metricGlobal,
}
