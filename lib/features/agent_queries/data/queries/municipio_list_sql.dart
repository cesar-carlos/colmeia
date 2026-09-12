/// Paged municipio list with total count in one `sql.execute` round-trip.
///
/// Uses `WITH Parametros/Base/Tot/Numbered` and
/// `Tot LEFT JOIN Numbered ON Rn BETWEEN …` so when the filter matches zero
/// rows or the requested page is empty, the result still includes a single
/// row with `TotalCount` and `NULL` municipio columns (see repository
/// mapping).
///
/// Pagination uses `ROW_NUMBER() OVER (ORDER BY NomeMunicipio)` (SQL Server
/// 2005+, SAP SQL Anywhere with window functions).
///
/// `:searchPattern` must be a prefix literal (e.g. `Cur%`) from
/// `ResumoVendasDiariasSuggestionSqlParams.buildPrefixSearchPattern` so
/// `m.Nome LIKE p.SearchPattern` can seek an index on `Nome` when present.
/// Optional DBA index (example): `Municipio (UF, Nome)`.
///
/// Named params: `:uf`, `:searchPattern`, `:startRow`, `:endRow`. Each name
/// appears once. Empty search is `NULL` on `Parametros.SearchPattern` — do
/// not `LIKE COALESCE(:searchPattern, '%')` (SQL Server ODBC may bind the
/// `'%'` literal as an extra positional value).
abstract final class MunicipioListSql {
  static const String pagedQuery = '''
    WITH Parametros AS (
      SELECT
        CAST(:uf AS VARCHAR(8)) AS Uf,
        CAST(:searchPattern AS VARCHAR(255)) AS SearchPattern
    ),
    Base AS (
      SELECT
        m.CodMunicipio,
        m.Nome AS NomeMunicipio,
        m.CodigoIBGE,
        COALESCE(e.Nome, m.UF) AS NomeEstado,
        m.UF
      FROM Municipio m
      LEFT JOIN Estado e ON
        e.SiglaEstado = m.UF
      CROSS JOIN Parametros p
      WHERE (p.Uf IS NULL OR m.UF = p.Uf)
        AND (
          p.SearchPattern IS NULL
          OR m.Nome LIKE p.SearchPattern
        )
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
