/// Seller suggestion query for the daily-sales filter — reads directly from
/// the `Vendedor` catalog table instead of joining `ProdutoVendido` by period.
///
/// Reading from the cadastro is better for autocomplete: it returns all
/// registered sellers (including those without sales in the current period)
/// and avoids the date-range scan over `ProdutoVendido`.
///
/// ---
///
/// ## Available columns from active joins
///
/// | Alias | Table | Columns |
/// |---|---|---|
/// | `v` | `Vendedor` | `CodVendedor`, `Nome` (→ `NomeVendedor`), `NomeReduzido` (→ `Apelido`), `Ativo`, `CNPJ_CPF`, `Telefone`, `Celular`, `EMail`, `Endereco`, `Numero` (→ `NumeroEndereco`), `Bairro`, `CEP`, `CodMunicipio` |
/// | `m` | `Municipio` (LEFT JOIN) | `Nome` (→ `NomeMunicipio`), `UF` (→ `UFMunicipio`) |
///
/// ## Currently projected
///
/// Only `CodVendedor` and `NomeVendedor` are projected to keep the query
/// lightweight for autocomplete. Add the columns above to the SELECT when a
/// richer option list is needed (extend entity and model accordingly).
///
/// ---
///
/// ## Query parameters
///
/// Named params: `:limit`, `:searchPattern` (two binds — well within the
/// five-bind bridge cap). Each name appears once, materialized in
/// `Parametros`, because SQL Anywhere **and** SQL Server Native Client treat
/// repeated `:name` tokens as extra positional binds.
///
/// Do **not** use `SELECT TOP (:limit)` with `LIKE COALESCE(:searchPattern,
/// '%')`. SQL Server ODBC binds `'%'` into `TOP`, which raises native error
/// 245 (`varchar '%' to int`). Cap rows with `ROW_NUMBER`. Empty search
/// binds `'%'` as varchar (never JSON `null`).
///
/// `:searchPattern` is always a varchar prefix literal from
/// `ResumoVendasDiariasSuggestionSqlParams.buildPrefixSearchPattern`
/// (`'%'` when the box is empty — never JSON `null`).
abstract final class ResumoVendasDiariasPorVendedorVendedorOptionsSql {
  static const String query = '''
    WITH Parametros AS (
      SELECT
        CAST(:limit AS INTEGER) AS MaxRows,
        CAST(:searchPattern AS VARCHAR(255)) AS SearchPattern
    ),
    Base AS (
      SELECT
        s.CodVendedor,
        s.NomeVendedor
      FROM (
        SELECT
          v.CodVendedor,
          COALESCE(
            NULLIF(LTRIM(RTRIM(v.Nome)), ''),
            'Vendedor nao informado'
          ) AS NomeVendedor
        FROM Vendedor v
        WHERE v.CodVendedor IS NOT NULL
      ) s
      CROSS JOIN Parametros p
      WHERE p.SearchPattern IS NULL
        OR s.NomeVendedor LIKE p.SearchPattern
    ),
    Numbered AS (
      SELECT
        b.CodVendedor,
        b.NomeVendedor,
        ROW_NUMBER() OVER (
          ORDER BY b.NomeVendedor, b.CodVendedor
        ) AS Rn
      FROM Base b
    )
    SELECT
      n.CodVendedor,
      n.NomeVendedor
    FROM Numbered n
    CROSS JOIN Parametros p
    WHERE n.Rn <= p.MaxRows
    ORDER BY n.Rn
  ''';
}
