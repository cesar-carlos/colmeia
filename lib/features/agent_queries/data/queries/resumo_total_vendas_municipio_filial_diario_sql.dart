/// Daily sales aggregate by company, branch (with **filial** municipality), and
/// calendar day (`ResumoTotalVendasMunicipioFilialDiario`).
///
/// ---
///
/// ## Active joins (inner query)
///
/// | Alias | Table | Role |
/// |-------|-------|------|
/// | `pv` | `ProdutoVendido` | Fact rows: keys, `DataVenda`, `Origem`, `PreVenda`, `ValorLiquido`, joins to filial and tipo saída |
/// | `tos` | `TipoOperacaoSaida` | Filter `GeraFinanceiro`; join `CodEmpresa`, `CodFilial`, `CodTipoOperacaoSaida` |
/// | `f` | `Filial` | Branch name, fantasy name, CEP; links to branch municipality |
/// | `mf` | `Municipio` | **Branch** municipality (`f.CodMunicipio`): code, name, UF, IBGE |
///
/// Relationship sketch:
///
/// ```text
/// ProdutoVendido (pv)
///   -> TipoOperacaoSaida (tos) on empresa + filial + tipo saída
///   -> Filial (f) on empresa + filial
///        -> Municipio (mf) on filial.CodMunicipio   -- geography of the branch
/// ```
///
/// ## Removed from an earlier hand-written variant (not projected here)
///
/// These were dropped intentionally — they are **not** part of the outer
/// `GROUP BY` and only increased scan cost. If you need them again, add back to
/// the inner `SELECT` **and** decide how they affect grouping or filters:
///
/// | Source | Columns / join removed |
/// |--------|-------------------------|
/// | `LEFT JOIN Vendedor v` | `CodVendedor`, `NomeVendedor` |
/// | `pv` / client geo | `CodCliente`, `CEPCliente` (client CEP on sale) |
/// | `INNER JOIN Municipio mc` on `pv.CodMunicipio` | `CodMunicipioCliente`, `NomeMunicipioCliente`, `UFMunicipioCliente`, `CodigoIBGEMunicipioCliente` — join enforced “sale must resolve cliente municipio”; **removed** so rows are not excluded when `pv.CodMunicipio` is missing or orphan in `Municipio` |
///
/// ## Performance notes
///
/// - Date filter avoids wrapping `pv.DataVenda` in `CAST` in the **predicate**
///   (half-open range by calendar day).
/// - `pv.Origem = :origem` (exact); wildcards rejected in
///   `resumo_vendas_produto_vendido_sql_periodo_filter.dart`.
/// - Outer `MAX(CodigoIBGEMunicipioFilial)` collapses duplicate IBGE values for
///   the same branch-municipio-day bucket instead of widening `GROUP BY`.
///
/// Suggested indexes (validate with DBA / actual plans):
///
/// ```sql
/// CREATE NONCLUSTERED INDEX IX_ProdutoVendido_ResumoMunicipioFilial
/// ON ProdutoVendido (CodEmpresa, CodFilial, DataVenda)
/// INCLUDE (CodProdutoVendido, Origem, PreVenda, CodTipoOperacaoSaida, ValorLiquido);
///
/// CREATE NONCLUSTERED INDEX IX_TipoOperacaoSaida_Join
/// ON TipoOperacaoSaida (CodEmpresa, CodFilial, CodTipoOperacaoSaida)
/// INCLUDE (GeraFinanceiro);
///
/// CREATE NONCLUSTERED INDEX IX_Filial_Municipio
/// ON Filial (CodEmpresa, CodFilial)
/// INCLUDE (Nome, NomeFantasia, CEP, CodMunicipio);
/// ```
abstract final class ResumoTotalVendasMunicipioFilialDiarioSql {
  static const String query = '''
SELECT
  CodEmpresa,
  CodFilial,
  NomeFilial,
  NomeFantasiaFilial,
  CEPFilial,
  CodMunicipioFilial,
  NomeMunicipioFilial,
  UFMunicipioFilial,
  MAX(CodigoIBGEMunicipioFilial) AS CodigoIBGEMunicipioFilial,
  DataVenda,
  COUNT(DISTINCT CodProdutoVendido) AS QtdVendas,
  SUM(ValorTotalVenda) AS TotalVenda
FROM (
  SELECT
    pv.CodEmpresa,
    pv.CodFilial,
    f.Nome AS NomeFilial,
    f.NomeFantasia AS NomeFantasiaFilial,
    REPLACE(REPLACE(TRIM(f.CEP), '.', ''), '-', '') AS CEPFilial,
    mf.CodMunicipio AS CodMunicipioFilial,
    mf.Nome AS NomeMunicipioFilial,
    TRIM(mf.UF) AS UFMunicipioFilial,
    mf.CodigoIBGE AS CodigoIBGEMunicipioFilial,
    pv.CodProdutoVendido,
    CAST(pv.DataVenda AS DATE) AS DataVenda,
    pv.ValorLiquido AS ValorTotalVenda
  FROM ProdutoVendido pv
  INNER JOIN TipoOperacaoSaida tos ON
    tos.CodEmpresa = pv.CodEmpresa
    AND tos.CodFilial = pv.CodFilial
    AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
  INNER JOIN Filial f ON
    f.CodEmpresa = pv.CodEmpresa
    AND f.CodFilial = pv.CodFilial
  INNER JOIN Municipio mf ON
    mf.CodMunicipio = f.CodMunicipio
  WHERE pv.DataVenda >= CAST(:dataVendaInicio AS DATE)
    AND pv.DataVenda < DATEADD(day, 1, CAST(:dataVendaFim AS DATE))
    AND pv.Origem = :origem
    AND tos.GeraFinanceiro = :geraFinanceiro
    AND pv.PreVenda = :preVenda
) AS ResumoTotalVendasMunicipioFilialDiario
GROUP BY
  CodEmpresa,
  CodFilial,
  NomeFilial,
  NomeFantasiaFilial,
  CEPFilial,
  CodMunicipioFilial,
  NomeMunicipioFilial,
  UFMunicipioFilial,
  DataVenda
ORDER BY
  CodEmpresa,
  CodFilial,
  DataVenda
''';
}
