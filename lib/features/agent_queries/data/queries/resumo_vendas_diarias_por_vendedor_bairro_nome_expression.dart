import 'package:colmeia/features/agent_queries/data/queries/agent_queries_sql_accent_fold.dart';

/// Shared SQL to derive a canonical bairro label (`NomeBairro`): trim,
/// punctuation to spaces, repeated `REPLACE('  ', ' ')` to collapse long space
/// runs, per-character `REPLACE` to strip accents (portable), then `UPPER`.
///
/// Used by the vendedor bairro/municipio options queries and the matching
/// predicates on the daily sales-by-seller report. Apostrophe in the input is
/// normalized with
/// `CHAR(39)` (same intent as quadruple single-quotes in hand-written T-SQL).
///
/// Avoids `TRANSLATE` so the same text runs on Microsoft SQL Server (all
/// versions) and SAP SQL Anywhere — both support `REPLACE` and `N'…'` string
/// literals.
abstract final class ResumoVendasDiariasPorVendedorBairroNomeExpression {
  /// [sourceSql] must be a single scalar expression, e.g.
  /// `COALESCE(Bairro, '')` or `COALESCE(:bairro, '')`.
  static String nomeBairroSql(String sourceSql) {
    // 13 REPLACE calls: 7 punctuation (. , - / * " ') + 6 double-space collapses.
    // Sybase SQL Anywhere and SQL Server both require exactly 3 args per REPLACE.
    var inner =
        '''
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(
          LTRIM(RTRIM($sourceSql)),
          '.', ' '),
          ',', ' '),
          '-', ' '),
          '/', ' '),
          '*', ' '),
          '"', ' '),
          CHAR(39), ' '),
        '  ', ' '),
        '  ', ' '),
        '  ', ' '),
        '  ', ' '),
        '  ', ' '),
        '  ', ' ')
      ''';
    inner = AgentQueriesSqlAccentFold.replaceAccents(inner);
    return 'UPPER($inner)';
  }

  /// Same normalization pipeline as [nomeBairroSql]; use at municipio call
  /// sites for readable SQL composition.
  static String nomeMunicipioSql(String sourceSql) => nomeBairroSql(sourceSql);

  /// Predicate matching sale rows when `:[paramName]` is set; compares
  /// normalized [columnSql] to the normalized bound parameter.
  static String equalsNormalizedNamedParam({
    required String columnSql,
    String paramName = 'bairro',
  }) {
    return '(:$paramName IS NULL OR '
        '${nomeBairroSql("COALESCE($columnSql, '')")} = '
        '${nomeBairroSql("COALESCE(:$paramName, '')")})';
  }

  /// Predicate when [normalizedColumnName] is already `nomeBairroSql` on data
  /// (e.g. `BairroNomeNorm` projected once in an inner `SELECT`).
  static String equalsNormalizedParamToPrecomputedColumn({
    required String normalizedColumnName,
    String paramName = 'bairro',
  }) {
    return '(:$paramName IS NULL OR '
        '$normalizedColumnName = '
        '${nomeBairroSql("COALESCE(:$paramName, '')")})';
  }

  /// Outer-report filter: tautology when unset; otherwise compare
  /// `BairroNomeNorm` to the same normalization used for named parameters, but
  /// with an inlined `N'…'` literal (Agent SQL bridge named-parameter cap).
  static String outerWhereNormalizedBairro(String? sqlBairro) {
    if (sqlBairro == null) {
      return '        AND (1 = 1)';
    }
    final escaped = sqlBairro.replaceAll("'", "''");
    final rhs = nomeBairroSql("COALESCE(N'$escaped', '')");
    return '        AND (BairroNomeNorm = $rhs)';
  }

  /// Same as [outerWhereNormalizedBairro] for `NomeMunicipioNomeNorm`.
  static String outerWhereNormalizedMunicipio(String? sqlMunicipio) {
    if (sqlMunicipio == null) {
      return '        AND (1 = 1)';
    }
    final escaped = sqlMunicipio.replaceAll("'", "''");
    final rhs = nomeMunicipioSql("COALESCE(N'$escaped', '')");
    return '        AND (NomeMunicipioNomeNorm = $rhs)';
  }
}
