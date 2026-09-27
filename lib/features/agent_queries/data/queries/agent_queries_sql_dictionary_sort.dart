import 'package:colmeia/features/agent_queries/data/queries/agent_queries_sql_accent_fold.dart';

/// Dictionary-style SQL sort key: strip punctuation, collapse spaces, then
/// accent-fold and `UPPER`.
///
/// Matches the E2E helper `foldNomeProdutoForSortOrder` so `ROW_NUMBER` on
/// product names agrees with Dart (`( NAO VENDER )` sorts with `NAO VENDER`,
/// not before `*`). Portable `REPLACE` only — no `TRANSLATE`.
abstract final class AgentQueriesSqlDictionarySort {
  static const List<String> _punctuation = <String>[
    '(',
    ')',
    '[',
    ']',
    '{',
    '}',
    '*',
    '-',
    '/',
    '.',
    ',',
    '"',
    '+',
    '&',
    '_',
    '!',
    '?',
    ':',
    ';',
    '#',
    '@',
  ];

  /// [sourceSql] must be a single scalar expression, e.g. `m.NomeProduto`.
  static String foldUpperStripPunctuation(String sourceSql) {
    var inner = 'LTRIM(RTRIM($sourceSql))';
    for (final mark in _punctuation) {
      inner = "REPLACE($inner, '$mark', '')";
    }
    inner = "REPLACE($inner, CHAR(39), '')";
    for (var i = 0; i < 6; i++) {
      inner = "REPLACE($inner, '  ', ' ')";
    }
    inner = 'LTRIM(RTRIM($inner))';
    return AgentQueriesSqlAccentFold.foldUpper(inner);
  }
}
