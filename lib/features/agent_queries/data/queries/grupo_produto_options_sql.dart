/// Product-group catalog options used by product filter UIs.
///
/// Named params: `:startRow`, `:endRow`, `:nomeGrupoProduto`.
abstract final class GrupoProdutoOptionsSql {
  static const String pagedQuery = '''
    WITH Parametros AS (
      SELECT
        CAST(:nomeGrupoProduto AS VARCHAR(255)) AS NomeGrupoProduto
    ),
    Numbered AS (
      SELECT
        CodGrupoProduto,
        Nome AS NomeGrupoProduto,
        ROW_NUMBER() OVER (
          ORDER BY
            Nome ASC,
            CodGrupoProduto ASC
        ) AS Rn
      FROM GrupoProduto gp
      CROSS JOIN Parametros p
      WHERE (
        p.NomeGrupoProduto IS NULL
        OR UPPER(gp.Nome) LIKE UPPER(p.NomeGrupoProduto)
      )
    )
    SELECT
      CodGrupoProduto,
      NomeGrupoProduto
    FROM Numbered
    WHERE Rn BETWEEN :startRow AND :endRow
    ORDER BY
      Rn ASC
  ''';
}
