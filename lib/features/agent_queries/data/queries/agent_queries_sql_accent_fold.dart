/// Portable SQL Anywhere / SQL Server accent folding via nested `REPLACE`.
///
/// Avoids `TRANSLATE` so the same text runs on Microsoft SQL Server and SAP
/// SQL Anywhere. Each diacritic becomes its ASCII letter; callers typically
/// wrap the result in `UPPER(...)` for case-insensitive compare or `LIKE`.
abstract final class AgentQueriesSqlAccentFold {
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

  static String _nCharLiteralContent(String singleChar) {
    return singleChar.replaceAll("'", "''");
  }

  /// Nested `REPLACE(source, N'á', N'a')` for each mapped diacritic.
  static String replaceAccents(String sourceSql) {
    final fromRunes = _translateFromAccents.runes.toList();
    final toRunes = _translateToAscii.runes.toList();
    assert(
      fromRunes.length == toRunes.length,
      'accent from/to must have equal length',
    );
    var result = sourceSql;
    for (var i = 0; i < fromRunes.length; i++) {
      final from = _nCharLiteralContent(String.fromCharCode(fromRunes[i]));
      final to = _nCharLiteralContent(String.fromCharCode(toRunes[i]));
      result = "REPLACE($result, N'$from', N'$to')";
    }
    return result;
  }

  /// Accent-fold [sourceSql] then `UPPER`. Does not trim or strip punctuation.
  static String foldUpper(String sourceSql) {
    return 'UPPER(${replaceAccents(sourceSql)})';
  }
}
