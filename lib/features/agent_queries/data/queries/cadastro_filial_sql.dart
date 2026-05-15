/// Paged branch registration query with total count in one `sql.execute`.
///
/// Reads `Filial` and left-joins `Municipio` for municipality metadata.
/// Optional filters are bound through named params:
/// `:codEmpresa`, `:codFilial`, `:startRow`, and `:endRow`.
abstract final class CadastroFilialSql {
  static const String pagedQuery = '''
    WITH Base AS (
      SELECT
        f.CodEmpresa,
        f.CodFilial,
        f.Nome AS NomeFilial,
        f.NomeFantasia AS NomeFantasia,
        f.CNPJ,
        f.Logradouro AS Endereco,
        f.NumeroLogradouro AS NumeroEndereco,
        f.Bairro,
        REPLACE(REPLACE(REPLACE(TRIM(f.CEP), '.', ''), '-', ''), ' ', '') AS CEP,
        f.CodMunicipio,
        TRIM(m.Nome) AS NomeMunicipio,
        m.CodigoIBGE AS CodigoIBGE,
        TRIM(m.UF) AS UFMunicipio
      FROM Filial f
      LEFT JOIN Municipio m ON
        m.CodMunicipio = f.CodMunicipio
      WHERE f.CodEmpresa = COALESCE(:codEmpresa, f.CodEmpresa)
        AND f.CodFilial = COALESCE(:codFilial, f.CodFilial)
    ),
    Tot AS (
      SELECT COUNT(*) AS TotalCount FROM Base
    ),
    Numbered AS (
      SELECT
        b.*,
        ROW_NUMBER() OVER (ORDER BY b.CodEmpresa, b.CodFilial) AS Rn
      FROM Base b
    )
    SELECT
      Tot.TotalCount,
      N.CodEmpresa,
      N.CodFilial,
      N.NomeFilial,
      N.NomeFantasia,
      N.CNPJ,
      N.Endereco,
      N.NumeroEndereco,
      N.Bairro,
      N.CEP,
      N.CodMunicipio,
      N.NomeMunicipio,
      N.CodigoIBGE,
      N.UFMunicipio,
      N.Rn
    FROM Tot
    LEFT JOIN Numbered N ON N.Rn BETWEEN :startRow AND :endRow
    ORDER BY COALESCE(N.Rn, 2147483647)
  ''';
}
