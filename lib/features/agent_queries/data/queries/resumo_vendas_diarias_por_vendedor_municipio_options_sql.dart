import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_bairro_nome_expression.dart';

abstract final class ResumoVendasDiariasPorVendedorMunicipioOptionsSql {
  /// Distinct normalized municipio labels from `Municipio` (cadastro), not
  /// from sales rows. Normalization matches the bairro pipeline so options
  /// align with the report filter. Search and `ROW_NUMBER` / `:limit` apply
  /// after `LEN(NomeMunicipio) > 3`.
  ///
  /// Does not use period filters; callers still validate the date range for UX
  /// consistency with other suggestion queries. `:searchPattern` is a varchar
  /// prefix from `buildPrefixSearchPattern`, bound once in `Parametros`. Empty
  /// search is `'%'` (never JSON `null`). Do not `COALESCE` to `'%'` next to a
  /// bound limit (SQL Server ODBC 245).
  static String get query {
    final nomeExpr =
        ResumoVendasDiariasPorVendedorBairroNomeExpression.nomeMunicipioSql(
          "COALESCE(NomeOriginal, '')",
        );
    return '''
      WITH Parametros AS (
        SELECT
          CAST(:limit AS INTEGER) AS MaxRows,
          CAST(:searchPattern AS VARCHAR(255)) AS SearchPattern
      ),
      Base AS (
        SELECT DISTINCT NomeMunicipio
        FROM (
          SELECT
            $nomeExpr AS NomeMunicipio
          FROM (
            SELECT m.Nome AS NomeOriginal
            FROM Municipio m
            WHERE m.Nome IS NOT NULL
              AND LTRIM(RTRIM(m.Nome)) <> ''
          ) Origem
        ) N
      ),
      Filtered AS (
        SELECT b.NomeMunicipio
        FROM Base b
        CROSS JOIN Parametros p
        WHERE LEN(b.NomeMunicipio) > 3
          AND (
            p.SearchPattern IS NULL
            OR b.NomeMunicipio LIKE p.SearchPattern
          )
      ),
      Numbered AS (
        SELECT
          f.NomeMunicipio,
          ROW_NUMBER() OVER (ORDER BY f.NomeMunicipio) AS Rn
        FROM Filtered f
      )
      SELECT n.NomeMunicipio
      FROM Numbered n
      CROSS JOIN Parametros p
      WHERE n.Rn <= p.MaxRows
      ORDER BY n.Rn
    ''';
  }
}
