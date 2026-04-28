/// Paged municipio list with total count in one `sql.execute` round-trip.
///
/// Uses `WITH Base/Tot/Numbered` and `Tot LEFT JOIN Numbered ON Rn BETWEEN …`
/// so when the filter matches zero rows or the requested page is empty, the
/// result still includes a single row with `TotalCount` and `NULL` municipio
/// columns (see repository mapping).
///
/// Pagination uses `ROW_NUMBER() OVER (ORDER BY NomeMunicipio)` (SQL Server
/// 2005+, SAP SQL Anywhere with window functions).
///
/// `:searchPattern` must be a prefix literal (e.g. `Cur%`) from
/// `ResumoVendasDiariasSuggestionSqlParams.buildPrefixSearchPattern` so
/// `m.Nome LIKE :searchPattern` can seek an index on `Nome` when present.
/// Optional DBA index (example): `Municipio (UF, Nome)`.
///
/// Named params: `:uf`, `:searchPattern`, `:startRow`, `:endRow`.
abstract final class MunicipioListSql {
  static const String pagedQuery = '''
    WITH Base AS (
      SELECT
        m.CodMunicipio,
        m.Nome AS NomeMunicipio,
        m.CodigoIBGE,
        COALESCE(e.Nome, m.UF) AS NomeEstado,
        m.UF
      FROM Municipio m
      LEFT JOIN Estado e ON
        e.SiglaEstado = m.UF
      WHERE m.UF = COALESCE(:uf, m.UF)
        AND m.Nome LIKE COALESCE(:searchPattern, '%')
    ),
    Tot AS (
      SELECT COUNT(*) AS TotalCount FROM Base
    ),
    Numbered AS (
      SELECT
        b.*,
        ROW_NUMBER() OVER (ORDER BY b.NomeMunicipio) AS Rn
      FROM Base b
    )
    SELECT
      Tot.TotalCount,
      N.CodMunicipio,
      N.NomeMunicipio,
      N.CodigoIBGE,
      N.NomeEstado,
      N.UF
    FROM Tot
    LEFT JOIN Numbered N ON N.Rn BETWEEN :startRow AND :endRow
    ORDER BY COALESCE(N.Rn, 2147483647)
  ''';
}
