import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_bairro_nome_expression.dart';

abstract final class ResumoVendasDiariasPorVendedorMunicipioOptionsSql {
  /// Distinct normalized municipio labels from `Municipio` (cadastro), not
  /// from sales rows. Normalization matches the bairro pipeline so options
  /// align with the report filter. Search and `TOP (:limit)` apply after
  /// `LEN(NomeMunicipio) > 3`.
  ///
  /// Does not use period filters; callers still validate the date range for UX
  /// consistency with other suggestion queries. `:searchPattern` should be a
  /// prefix pattern from `buildPrefixSearchPattern` (suggestion params).
  static String get query {
    final nomeExpr =
        ResumoVendasDiariasPorVendedorBairroNomeExpression.nomeMunicipioSql(
          "COALESCE(NomeOriginal, '')",
        );
    return '''
      SELECT TOP (:limit)
        NomeMunicipio
      FROM (
        SELECT DISTINCT NomeMunicipio
        FROM (
          SELECT
            $nomeExpr AS NomeMunicipio
          FROM (
            SELECT m.Nome AS NomeOriginal
            FROM Municipio m
            WHERE m.Nome IS NOT NULL
              AND LTRIM(RTRIM(m.Nome)) <> ''
          ) Base
        ) N
      ) R
      WHERE LEN(NomeMunicipio) > 3
        AND (
          :searchPattern IS NULL
          OR NomeMunicipio LIKE :searchPattern
        )
      ORDER BY NomeMunicipio
    ''';
  }
}
