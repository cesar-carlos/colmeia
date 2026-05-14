import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';

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
  static String query({
    Iterable<ResumoTotalVendasMunicipioFilialPeriodoBranchRef> branches =
        const <ResumoTotalVendasMunicipioFilialPeriodoBranchRef>[],
  }) {
    final branchPredicate = _branchPredicate(branches);
    return '''
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
$branchPredicate
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

  static String _branchPredicate(
    Iterable<ResumoTotalVendasMunicipioFilialPeriodoBranchRef> branches,
  ) {
    final byKey = <String, ResumoTotalVendasMunicipioFilialPeriodoBranchRef>{};
    for (final branch in branches) {
      byKey['${branch.codEmpresa}:${branch.codFilial}'] = branch;
    }
    final uniqueBranches = byKey.values.toList(growable: false)
      ..sort((left, right) {
        final company = left.codEmpresa.compareTo(right.codEmpresa);
        if (company != 0) {
          return company;
        }
        return left.codFilial.compareTo(right.codFilial);
      });
    if (uniqueBranches.isEmpty) {
      return '';
    }

    final branchesByCompany = <int, List<int>>{};
    for (final branch in uniqueBranches) {
      branchesByCompany
          .putIfAbsent(branch.codEmpresa, () => <int>[])
          .add(branch.codFilial);
    }

    final clauses = branchesByCompany.entries.map((entry) {
      final filiais = entry.value;
      if (filiais.length == 1) {
        return '(pv.CodEmpresa = ${entry.key} AND pv.CodFilial = ${filiais.single})';
      }

      return '(pv.CodEmpresa = ${entry.key} '
          'AND pv.CodFilial IN (${filiais.join(', ')}))';
    });
    return '\n  AND (${clauses.join(' OR ')})';
  }
}
