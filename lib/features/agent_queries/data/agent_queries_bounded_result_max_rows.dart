/// Conservative `max_rows` for `sql.execute` on aggregate queries with bounded
/// row counts (safety net if SQL or grouping changes).
abstract final class AgentQueriesBoundedResultMaxRows {
  /// Shared cap for aggregates that return many buckets across companies and
  /// branches (e.g. weekday or month per filial).
  static const int aggregateMultiBranchCap = 1600;

  /// `GROUP BY` company, branch, and weekday (up to seven buckets per branch).
  static const int resumoParcelasDiaSemana = aggregateMultiBranchCap;

  /// Company, branch, user, and weekday — higher cardinality than
  /// [resumoParcelasDiaSemana].
  static const int resumoParcelasDiaSemanaUsuario = 5000;

  /// One row per calendar month per company/branch; deployments with many
  /// branches exceed [aggregateMultiBranchCap] (12 months × filiais).
  static const int resumoParcelasMensal = 8000;

  /// Company, branch, sale year, and payment method buckets in the range.
  static const int resumoParcelasAnual = aggregateMultiBranchCap;

  /// Payment method × month × user (and similar); overview forma pagamento.
  static const int resumoParcelaFormaPagamento = 5000;

  /// Company, branch, and sale user — one bucket per operator per branch.
  static const int resumoParcelaPorUsuario = 5000;

  /// Same cardinality as `resumoParcelaFormaPagamento` (por-mes report).
  static const int resumoParcelasFormaPagamentoPorMes = 5000;

  /// One row per sold product line in the filtered period.
  static const int resumoParcelaFormaPagamentoDiario = 10000;

  /// Daily sales by seller grid rows.
  static const int resumoVendasDiariasPorVendedor = 5000;

  /// One row per company, branch, and calendar day — long ranges × filiais.
  static const int resumoTotalDiarioVendas = 8000;

  /// Same cardinality as [resumoTotalDiarioVendas] with branch municipality
  /// dimensions in each row.
  static const int resumoTotalVendasMunicipioFilialDiario = 8000;

  /// One row per company and branch for the sales live map period aggregate.
  static const int resumoTotalVendasMunicipioFilialPeriodo = 2000;

  /// Suggestion lists for vendedor/bairro/município (`TOP` limits; bridge cap).
  static const int vendasDiariasSuggestionOptions = 128;

  /// One page of `Municipio` list rows (same order of magnitude as list filter
  /// max page size in domain).
  static const int municipioListPage = 100;

  /// One page of branch registration rows.
  /// Branch catalog pages (`cadastro_filial`). Kept aligned with
  /// `CadastroFilialFilter.maxPageSize` so ROW_NUMBER windows and `max_rows`
  /// stay consistent for `loadAll` pagination (see `docs/bridge_agent_sql_api_options.md`).
  static const int cadastroFilialPage = 500;

  /// Full product-group catalog (`GrupoProduto`) ordered by name.
  static const int grupoProdutoOptions = 2000;

  /// Full product-brand catalog (`Marca`) ordered by name.
  static const int marcaProdutoOptions = 2000;

  /// One page of cliente catalog rows plus total-count row.
  /// Kept aligned with `ClienteOptionsFilter.maxPageSize`.
  static const int clienteOptionsPage = 501;

  /// One page of fornecedor catalog rows plus total-count row.
  /// Kept aligned with `FornecedorOptionsFilter.maxPageSize`.
  static const int fornecedorOptionsPage = 501;

  /// Monthly product profitability buckets: `(months in range) × filiais`.
  /// At most ~13 months × many branches; 2 000 is a conservative safety cap.
  static const int resumoProdutoVendaLucratividadeMensal = 2000;

  /// Period product profitability: one row per `CodEmpresa/CodFilial`.
  /// Bounded by the number of active branches; 200 is a generous safety cap.
  static const int resumoProdutoVendaLucratividade = 200;

  /// `TOP 15` product ranking rows — margin above the nominal cap as a safety net.
  static const int produtoVendidoProdutoRankLucro = 32;

  /// Billing ranking per branch: up to (N+1) rows × filiais.
  ///
  /// Keep this well below [aggregateMultiBranchCap]. On the E2E SQL Anywhere
  /// agent, `max_rows` around 1600 for this heavy CTE query returned an empty
  /// success payload while the same SQL with `max_rows` 50–400 returned the
  /// expected Top-N + DIVERSOS rows. Paired with
  /// `RankingProdutosFaturamentoRepositoryImpl.maxFilialEstimate` (25): default
  /// top-15 needs `(15 + 1) * 25 = 400`. Prefer single-branch filters when the
  /// live catalog exceeds that estimate.
  static const int rankingProdutosFaturamento = 400;

  /// Trend rows by product between two periods; can be high cardinality for
  /// catalogs with many active SKUs.
  static const int produtoVendidoTendenciaDeVenda = 10000;

  /// Moving-average trend rows by product; same order of magnitude as the
  /// explicit-period trend report.
  static const int produtoVendidoTendenciaDeVendaMediaMovel = 10000;

  /// Summary grouped by moving-average trend classification.
  static const int produtoVendidoTendenciaDeVendaMediaMovelSummary = 32;

  /// Summary grouped by trend classification (`CRESCENDO`, `CAINDO`, etc.).
  static const int produtoVendidoTendenciaDeVendaSummary = 32;

  /// Top gainers/losers (`TOP 15` each) for explicit-period trend screens.
  static const int produtoVendidoTendenciaDeVendaTopMovers = 15;
}
