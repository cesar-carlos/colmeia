/// Period sales aggregate by company and branch with branch municipality
/// (`ResumoTotalVendasMunicipioFilialPeriodo`).
///
/// ---
///
/// ## Active joins
///
/// | Alias | Table | Role |
/// |-------|-------|------|
/// | `pv` | `ProdutoVendido` | Fact rows: keys, `DataVenda`, `Origem`, `PreVenda`, `ValorLiquido`, joins to filial and tipo saida |
/// | `tos` | `TipoOperacaoSaida` | Filter `GeraFinanceiro`; join `CodEmpresa`, `CodFilial`, `CodTipoOperacaoSaida` |
/// | `f` | `Filial` | Branch name, fantasy name, CEP; links to branch municipality |
/// | `mf` | `Municipio` | Branch municipality (`f.CodMunicipio`): code, name, UF, IBGE |
///
/// ## Performance notes
///
/// - This query is intentionally period-level, not daily-level. It supports the
///   live sales map without returning one row per filial per calendar day.
/// - The branch municipality join is left-joined so sales from a filial with
///   missing or orphaned municipality registration still count in KPIs and can
///   be flagged as unmapped by the app.
/// - Date filtering uses a half-open calendar range and avoids wrapping
///   `pv.DataVenda` in the predicate.
/// - `MAX(CodigoIBGEMunicipioFilial)` keeps IBGE available for map geolocation
///   without widening the grouping.
abstract final class ResumoTotalVendasMunicipioFilialPeriodoSql {
  static const String query = '''
SELECT
  pv.CodEmpresa,
  pv.CodFilial,
  f.Nome AS NomeFilial,
  f.NomeFantasia AS NomeFantasiaFilial,
  REPLACE(REPLACE(TRIM(f.CEP), '.', ''), '-', '') AS CEPFilial,
  f.CodMunicipio AS CodMunicipioFilial,
  mf.Nome AS NomeMunicipioFilial,
  TRIM(mf.UF) AS UFMunicipioFilial,
  MAX(mf.CodigoIBGE) AS CodigoIBGEMunicipioFilial,
  COUNT(DISTINCT pv.CodProdutoVendido) AS QtdVendas,
  SUM(pv.ValorLiquido) AS TotalVenda
FROM ProdutoVendido pv
INNER JOIN TipoOperacaoSaida tos ON
  tos.CodEmpresa = pv.CodEmpresa
  AND tos.CodFilial = pv.CodFilial
  AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
INNER JOIN Filial f ON
  f.CodEmpresa = pv.CodEmpresa
  AND f.CodFilial = pv.CodFilial
LEFT JOIN Municipio mf ON
  mf.CodMunicipio = f.CodMunicipio
WHERE pv.DataVenda >= CAST(:dataVendaInicio AS DATE)
  AND pv.DataVenda < DATEADD(day, 1, CAST(:dataVendaFim AS DATE))
  AND pv.Origem = :origem
  AND tos.GeraFinanceiro = :geraFinanceiro
  AND pv.PreVenda = :preVenda
GROUP BY
  pv.CodEmpresa,
  pv.CodFilial,
  f.Nome,
  f.NomeFantasia,
  REPLACE(REPLACE(TRIM(f.CEP), '.', ''), '-', ''),
  f.CodMunicipio,
  mf.Nome,
  TRIM(mf.UF)
''';
}
