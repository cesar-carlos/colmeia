import 'package:flutter_test/flutter_test.dart';

import 'e2e_omit_sales_origem.dart';

void main() {
  test('should drop a named Origem predicate and its bind', () {
    const sql = '''
WHERE pv.DataVenda >= CAST(:dataVendaInicio AS DATE)
  AND pv.Origem = :origem
  AND pv.PreVenda = :preVenda
''';

    final stripped = omitE2eSalesOrigemSql(sql);
    expect(stripped, isNot(contains('Origem')));
    expect(stripped, contains('pv.PreVenda = :preVenda'));
    expect(
      omitE2eSalesOrigemParams(stripped, <String, Object?>{
        'origem': 'FrenteLoja',
        'preVenda': 'N',
      }),
      <String, Object?>{'preVenda': 'N'},
    );
  });

  test('should drop an unqualified Origem predicate', () {
    const sql = '''
WHERE DataVenda >= :dataVendaInicio
      AND Origem = :origem
      AND PreVenda = :preVenda
''';

    final stripped = omitE2eSalesOrigemSql(sql);
    expect(stripped, isNot(contains(':origem')));
    expect(stripped, contains('PreVenda = :preVenda'));
  });

  test('should drop an inlined FrenteLoja literal', () {
    const sql = '''
WHERE pv.DataVenda < CAST(GETDATE() AS DATE)
        AND pv.Origem = 'FrenteLoja'
        AND pv.PreVenda = 'N'
''';

    final stripped = omitE2eSalesOrigemSql(sql);
    expect(stripped, isNot(contains('FrenteLoja')));
    expect(stripped, contains("pv.PreVenda = 'N'"));
  });

  test('should keep CodOrigem and a non-sales Origem predicate', () {
    const sql = '''
        WHERE Origem = 'OB'
        AND vale_ob.CodOrigem = pv.CodOrigem
''';

    expect(omitE2eSalesOrigemSql(sql), sql);
  });
}
