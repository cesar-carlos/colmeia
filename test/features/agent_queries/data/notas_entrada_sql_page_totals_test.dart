import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/notas_entrada_sql_page_totals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads catalog totals from the Tot CTE aliases', () {
    final row = <String, dynamic>{
      'TotalCount': 86,
      'TotalValorCompra': 1250.5,
    };

    check(NotasEntradaSqlPageTotals.readTotalCount(row)).equals(86);
    check(NotasEntradaSqlPageTotals.readTotalValorCompra(row)).equals(1250.5);
  });

  test('throws when the purchase total is missing', () {
    check(
      () => NotasEntradaSqlPageTotals.readTotalValorCompra(
        const <String, dynamic>{'TotalCount': 0},
      ),
    ).throws<FormatException>();
  });
}
