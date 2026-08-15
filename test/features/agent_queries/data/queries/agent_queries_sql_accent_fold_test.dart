import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/agent_queries_sql_accent_fold.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentQueriesSqlAccentFold', () {
    test('replaceAccents nests REPLACE with N-char diacritic literals', () {
      final sql = AgentQueriesSqlAccentFold.replaceAccents('p.Nome');

      check(sql).contains('REPLACE(');
      check(sql).contains("N'á'");
      check(sql).contains("N'a'");
      check(sql).contains("N'ç'");
      check(sql).contains("N'c'");
      check(sql).contains('p.Nome');
    });

    test('foldUpper wraps accent REPLACE in UPPER', () {
      final sql = AgentQueriesSqlAccentFold.foldUpper('TRIM(p.Nome)');

      check(sql.startsWith('UPPER(')).isTrue();
      check(sql.endsWith(')')).isTrue();
      check(sql).contains('TRIM(p.Nome)');
      check(sql).contains("N'ã'");
    });
  });
}
