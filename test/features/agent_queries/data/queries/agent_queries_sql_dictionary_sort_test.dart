import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/agent_queries_sql_dictionary_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentQueriesSqlDictionarySort', () {
    test('should strip punctuation then accent-fold and upper the source', () {
      final sql = AgentQueriesSqlDictionarySort.foldUpperStripPunctuation(
        'm.NomeProduto',
      );

      check(sql.startsWith('UPPER(')).isTrue();
      check(sql).contains('m.NomeProduto');
      check(sql).contains("'(', ''");
      check(sql).contains("'*', ''");
      check(sql).contains("'-', ''");
      check(sql).contains("CHAR(39), ''");
      check(sql).contains("'  ', ' '");
      check(sql).contains("N'á'");
    });
  });
}
