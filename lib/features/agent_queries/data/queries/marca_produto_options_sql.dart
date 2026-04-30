/// Product-brand catalog options used by product filter UIs.
///
/// Named params: `:startRow`, `:endRow`, `:nomeMarca`.
abstract final class MarcaProdutoOptionsSql {
  static const String pagedQuery = '''
    WITH Parametros AS (
      SELECT
        CAST(:nomeMarca AS VARCHAR(255)) AS NomeMarca
    ),
    Numbered AS (
      SELECT
        CodMarca,
        Nome AS NomeMarca,
        ROW_NUMBER() OVER (
          ORDER BY
            Nome ASC,
            CodMarca ASC
        ) AS Rn
      FROM Marca m
      CROSS JOIN Parametros p
      WHERE (
        p.NomeMarca IS NULL
        OR UPPER(m.Nome) LIKE UPPER(p.NomeMarca)
      )
    )
    SELECT
      CodMarca,
      NomeMarca
    FROM Numbered
    WHERE Rn BETWEEN :startRow AND :endRow
    ORDER BY
      Rn ASC
  ''';
}
