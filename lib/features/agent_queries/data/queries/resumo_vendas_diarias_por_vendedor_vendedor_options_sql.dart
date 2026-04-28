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
/// five-bind bridge cap).
///
/// `:searchPattern` is used only once — Sybase SQL Anywhere ODBC treats each
/// named-parameter occurrence as a separate positional bind, so never repeat
/// a named parameter in the same SQL statement.
abstract final class ResumoVendasDiariasPorVendedorVendedorOptionsSql {
  static const String query = '''
      SELECT TOP (:limit)
        v.CodVendedor,
        COALESCE(
          NULLIF(LTRIM(RTRIM(v.Nome)), ''),
          'Vendedor nao informado'
        ) AS NomeVendedor
      FROM Vendedor v
      WHERE v.CodVendedor IS NOT NULL
        AND COALESCE(
          NULLIF(LTRIM(RTRIM(v.Nome)), ''),
          'Vendedor nao informado'
        ) LIKE COALESCE(:searchPattern, '%')
      ORDER BY NomeVendedor, v.CodVendedor
    ''';
}
