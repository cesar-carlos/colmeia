import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/notas_entrada_itens_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('binds CompraId once without company, branch, or SELECT *', () {
    const sql = NotasEntradaItensSql.query;

    check(_count(sql, ':compraId')).equals(1);
    check(_count(sql, ':codEmpresa')).equals(0);
    check(_count(sql, ':codFilial')).equals(0);
    check(sql).not((it) => it.contains('SELECT *'));
    check(sql).not((it) => it.contains('/*'));
  });

  test('joins item, product, unit, group, and purchase tables', () {
    const sql = NotasEntradaItensSql.query;

    check(sql).contains('FROM Compra.ItemCompra cic');
    check(sql).contains(
      'LEFT JOIN Produto p ON p.CodProduto = cic.CodProduto',
    );
    check(sql).contains(
      'LEFT JOIN UnidadeMedida um ON um.CodUnidadeMedida = cic.CodUnidadeMedida',
    );
    check(sql).contains(
      'LEFT JOIN GrupoProduto gp ON gp.CodGrupoProduto = p.CodGrupoProduto',
    );
    check(sql).contains(
      'INNER JOIN Compra.Compra cc ON cc.Id = cic.CompraID',
    );
    check(sql).contains('cic.CodUnidadeMedida');
    check(sql).contains('cc.Cancelada AS CompraCancelada');
    check(sql).contains('WHERE cc.Id = :compraId');
    check(sql).not((it) => it.contains('WITH Parametros'));
    check(sql).not((it) => it.contains('CAST(:compraId'));
    check(sql).contains(
      'ORDER BY p.Nome, cic.CodProduto',
    );
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
