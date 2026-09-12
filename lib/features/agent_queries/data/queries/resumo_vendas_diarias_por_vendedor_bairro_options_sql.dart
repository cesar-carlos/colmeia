import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_bairro_nome_expression.dart';

abstract final class ResumoVendasDiariasPorVendedorBairroOptionsSql {
  /// Distinct normalized bairro labels from `Cliente` and `Fornecedor`, not
  /// from sales rows. Normalization (trim, punctuation, accents, upper)
  /// collapses spelling variants so `DISTINCT` reduces payload. Search pattern
  /// and `ROW_NUMBER` / `:limit` apply after `LEN(NomeBairro) > 3`.
  ///
  /// `Origem` excludes null/blank `Bairro` before normalization.
  /// `:searchPattern` is a varchar prefix from `buildPrefixSearchPattern`,
  /// bound once in `Parametros`. Empty search is `'%'` (never JSON `null`).
  /// Do not `COALESCE(:searchPattern, '%')` next to a bound limit (SQL Server
  /// ODBC 245).
  ///
  /// Does not use period filters; callers still validate the date range for UX
  /// consistency with other suggestion queries.
  static String get query {
    final nomeExpr =
        ResumoVendasDiariasPorVendedorBairroNomeExpression.nomeBairroSql(
          "COALESCE(BairroOriginal, '')",
        );
    return '''
      WITH Parametros AS (
        SELECT
          CAST(:limit AS INTEGER) AS MaxRows,
          CAST(:searchPattern AS VARCHAR(255)) AS SearchPattern
      ),
      Base AS (
        SELECT DISTINCT NomeBairro
        FROM (
          SELECT
            $nomeExpr AS NomeBairro
          FROM (
            SELECT cli.Bairro AS BairroOriginal
            FROM Cliente cli
            WHERE cli.Bairro IS NOT NULL
              AND LTRIM(RTRIM(cli.Bairro)) <> ''
            UNION ALL
            SELECT forn.Bairro AS BairroOriginal
            FROM Fornecedor forn
            WHERE forn.Bairro IS NOT NULL
              AND LTRIM(RTRIM(forn.Bairro)) <> ''
          ) Origem
        ) N
      ),
      Filtered AS (
        SELECT b.NomeBairro
        FROM Base b
        CROSS JOIN Parametros p
        WHERE LEN(b.NomeBairro) > 3
          AND (
            p.SearchPattern IS NULL
            OR b.NomeBairro LIKE p.SearchPattern
          )
      ),
      Numbered AS (
        SELECT
          f.NomeBairro,
          ROW_NUMBER() OVER (ORDER BY f.NomeBairro) AS Rn
        FROM Filtered f
      )
      SELECT n.NomeBairro
      FROM Numbered n
      CROSS JOIN Parametros p
      WHERE n.Rn <= p.MaxRows
      ORDER BY n.Rn
    ''';
  }
}
