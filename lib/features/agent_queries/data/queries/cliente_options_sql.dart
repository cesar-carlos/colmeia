/// Paged cliente catalog with total count in one `sql.execute` round-trip.
///
/// Uses `WITH Base/Tot/Numbered` and `Tot LEFT JOIN Numbered ON Rn BETWEEN …`
/// so when the filter matches zero rows or the requested page is empty, the
/// result still includes a single row with `TotalCount` and `NULL` cliente
/// columns (see repository mapping).
///
/// Named params: `:searchPattern`, `:searchDigitsPattern`, `:startRow`, `:endRow`.
///
/// `:searchPattern` is a contains literal (e.g. `%term%`) from
/// `ResumoVendasDiariasSuggestionSqlParams.buildSearchPattern`.
abstract final class ClienteOptionsSql {
  static const String pagedQuery = '''
    WITH Parametros AS (
      SELECT
        CAST(:searchPattern AS VARCHAR(255)) AS SearchPattern,
        CAST(:searchDigitsPattern AS VARCHAR(255)) AS SearchDigitsPattern
    ),
    Base AS (
      SELECT
        c.CodCliente,
        c.Nome AS NomeCliente,
        c.NomeFantasia,
        c.CNPJ_CPF,
        c.EMail,
        c.Telefone,
        c.Celular,
        c.Endereco,
        c.Numero AS NumeroEndereco,
        c.Bairro,
        c.Complemento,
        c.CEP,
        c.CodMunicipio,
        m.Nome AS NomeMunicipio,
        m.UF AS UFMunicipio,
        m.CodigoIBGE
      FROM Cliente c
      INNER JOIN Municipio m ON m.CodMunicipio = c.CodMunicipio
      CROSS JOIN Parametros p
      WHERE (
        p.SearchPattern IS NULL
        OR UPPER(c.Nome) LIKE UPPER(p.SearchPattern)
        OR UPPER(c.NomeFantasia) LIKE UPPER(p.SearchPattern)
        OR UPPER(c.CNPJ_CPF) LIKE UPPER(p.SearchPattern)
        OR UPPER(c.EMail) LIKE UPPER(p.SearchPattern)
        OR UPPER(m.Nome) LIKE UPPER(p.SearchPattern)
        OR (
          p.SearchDigitsPattern IS NOT NULL
          AND CAST(m.CodigoIBGE AS VARCHAR(20)) LIKE p.SearchDigitsPattern
        )
      )
    ),
    Tot AS (
      SELECT COUNT(*) AS TotalCount FROM Base
    ),
    Numbered AS (
      SELECT
        b.*,
        ROW_NUMBER() OVER (
          ORDER BY
            b.NomeCliente ASC,
            b.CodCliente ASC
        ) AS Rn
      FROM Base b
    )
    SELECT
      Tot.TotalCount,
      N.CodCliente,
      N.NomeCliente,
      N.NomeFantasia,
      N.CNPJ_CPF,
      N.EMail,
      N.Telefone,
      N.Celular,
      N.Endereco,
      N.NumeroEndereco,
      N.Bairro,
      N.Complemento,
      N.CEP,
      N.CodMunicipio,
      N.NomeMunicipio,
      N.UFMunicipio,
      N.CodigoIBGE
    FROM Tot
    LEFT JOIN Numbered N ON N.Rn BETWEEN :startRow AND :endRow
    ORDER BY COALESCE(N.Rn, 2147483647)
  ''';
}
