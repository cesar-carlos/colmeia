/// Paged fornecedor catalog with total count in one `sql.execute` round-trip.
///
/// Uses `WITH Base/Tot/Numbered` and `Tot LEFT JOIN Numbered ON Rn BETWEEN …`
/// so when the filter matches zero rows or the requested page is empty, the
/// result still includes a single row with `TotalCount` and `NULL` fornecedor
/// columns (see repository mapping).
///
/// Named params: `:searchPattern`, `:searchDigitsPattern`, `:startRow`, `:endRow`.
///
/// `:searchPattern` is a contains literal (e.g. `%term%`) from
/// `ResumoVendasDiariasSuggestionSqlParams.buildSearchPattern`.
abstract final class FornecedorOptionsSql {
  static const String pagedQuery = '''
    WITH Parametros AS (
      SELECT
        CAST(:searchPattern AS VARCHAR(255)) AS SearchPattern,
        CAST(:searchDigitsPattern AS VARCHAR(255)) AS SearchDigitsPattern
    ),
    Base AS (
      SELECT
        f.CodFornecedor,
        f.RazaoSocial AS NomeFornecedor,
        f.NomeFantasia,
        f.CNPJ_CPF,
        f.EMail,
        f.Telefone,
        f.Endereco,
        f.Numero AS NumeroEndereco,
        f.Bairro,
        f.Complemento,
        f.CEP,
        f.CodMunicipio,
        m.Nome AS NomeMunicipio,
        m.UF AS UFMunicipio,
        m.CodigoIBGE
      FROM Fornecedor f
      INNER JOIN Municipio m ON m.CodMunicipio = f.CodMunicipio
      CROSS JOIN Parametros p
      WHERE (
        p.SearchPattern IS NULL
        OR UPPER(f.RazaoSocial) LIKE UPPER(p.SearchPattern)
        OR UPPER(f.NomeFantasia) LIKE UPPER(p.SearchPattern)
        OR UPPER(f.CNPJ_CPF) LIKE UPPER(p.SearchPattern)
        OR UPPER(f.EMail) LIKE UPPER(p.SearchPattern)
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
            b.NomeFornecedor ASC,
            b.CodFornecedor ASC
        ) AS Rn
      FROM Base b
    )
    SELECT
      Tot.TotalCount,
      N.CodFornecedor,
      N.NomeFornecedor,
      N.NomeFantasia,
      N.CNPJ_CPF,
      N.EMail,
      N.Telefone,
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
