import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/municipio_list_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sql = MunicipioListSql.pagedQuery;

  test('binds each named parameter once without a LIKE percent fallback', () {
    check(_count(sql, ':uf')).equals(1);
    check(_count(sql, ':searchPattern')).equals(1);
    check(_count(sql, ':startRow')).equals(1);
    check(_count(sql, ':endRow')).equals(1);
    check(sql).contains('p.SearchPattern IS NULL');
    check(sql).contains('p.Uf IS NULL OR m.UF = p.Uf');
    check(sql).not((it) => it.contains("COALESCE(:searchPattern, '%')"));
    check(sql).not((it) => it.contains('SELECT TOP'));
  });

  test('pages with row numbers and a total count', () {
    check(sql).contains('FROM Municipio m');
    check(sql).contains('LEFT JOIN Estado e');
    check(sql).contains('COUNT(*) AS TotalCount');
    check(sql).contains('ROW_NUMBER() OVER');
    check(sql).contains('N.Rn BETWEEN :startRow AND :endRow');
  });
}

int _count(String source, String needle) {
  var count = 0;
  var from = 0;
  while (true) {
    final index = source.indexOf(needle, from);
    if (index < 0) {
      return count;
    }
    count += 1;
    from = index + needle.length;
  }
}
