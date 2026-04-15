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
  static const String _translateFromAccents =
      'áàâãäåæçéèêëíìîïñóòôõöúùûüýÿ'
      'ÁÀÂÃÄÅÆÇÉÈÊËÍÌÎÏÑÓÒÔÕÖÚÙÛÜÝŸ';

  static const String _translateToAscii =
      'aaaaaaa'
      'c'
      'eeee'
      'iiii'
      'n'
      'ooooo'
      'uuuu'
      'yy'
      'AAAAAAA'
      'C'
      'EEEE'
      'IIII'
      'N'
      'OOOOO'
      'UUUU'
      'YY';

  /// Escapes a single character for use inside an `N'…'` literal in T-SQL /
  /// SQL Anywhere (double internal single quotes).
  static String _nCharLiteralContent(String singleChar) {
    return singleChar.replaceAll("'", "''");
  }

  static String _wrapAccentReplaceChain(String innerSql) {
    final fromRunes = _translateFromAccents.runes.toList();
    final toRunes = _translateToAscii.runes.toList();
    assert(
      fromRunes.length == toRunes.length,
      'accent from/to must have equal length',
    );
    var result = innerSql;
    for (var i = 0; i < fromRunes.length; i++) {
      final from = _nCharLiteralContent(String.fromCharCode(fromRunes[i]));
      final to = _nCharLiteralContent(String.fromCharCode(toRunes[i]));
      result = "REPLACE($result, N'$from', N'$to')";
    }
    return result;
  }

  /// [sourceSql] must be a single scalar expression, e.g.
  /// `COALESCE(Bairro, '')` or `COALESCE(:bairro, '')`.
  static String nomeBairroSql(String sourceSql) {
    var inner =
        '''
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
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
    inner = _wrapAccentReplaceChain(inner);
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
}
