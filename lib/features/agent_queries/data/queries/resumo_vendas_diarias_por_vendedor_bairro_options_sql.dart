import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_bairro_nome_expression.dart';

abstract final class ResumoVendasDiariasPorVendedorBairroOptionsSql {
  /// Distinct normalized bairro labels from `Cliente` and `Fornecedor`, not
  /// from sales rows. Normalization (trim, punctuation, accents, upper)
  /// collapses spelling variants so `DISTINCT` reduces payload. Search pattern
  /// and `TOP (:limit)` apply after `LEN(NomeBairro) > 3`.
  ///
  /// `Base` excludes null/blank `Bairro` before normalization. `:searchPattern`
  /// should be a prefix pattern from `buildPrefixSearchPattern` (suggestion
  /// params).
  ///
  /// Does not use period filters; callers still validate the date range for UX
  /// consistency with other suggestion queries.
  static String get query {
    final nomeExpr =
        ResumoVendasDiariasPorVendedorBairroNomeExpression.nomeBairroSql(
      "COALESCE(BairroOriginal, '')",
    );
    return '''
SELECT TOP (:limit)
  NomeBairro
FROM (
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
    ) Base
  ) N
) R
WHERE LEN(NomeBairro) > 3
  AND (
    :searchPattern IS NULL
    OR NomeBairro LIKE :searchPattern
  )
ORDER BY NomeBairro
''';
  }
}
