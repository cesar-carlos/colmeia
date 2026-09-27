import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_item_row.dart';
import 'package:colmeia/features/sales/presentation/sales_notas_entrada_itens_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches product name or code and ignores blank search', () {
    final rows = <NotaEntradaItemRow>[
      _row(codProduto: 1204, nomeProduto: 'Erva mate menta'),
      _row(codProduto: 21150, nomeProduto: 'Capa protetora'),
    ];

    check(SalesNotasEntradaItensSearch.filter(rows, '  ').length).equals(2);
    check(
      SalesNotasEntradaItensSearch.filter(rows, 'menta').single.codProduto,
    ).equals(1204);
    check(
      SalesNotasEntradaItensSearch.filter(rows, '211').single.codProduto,
    ).equals(21150);
    check(SalesNotasEntradaItensSearch.filter(rows, 'xyz')).isEmpty();
  });
}

NotaEntradaItemRow _row({
  required int codProduto,
  required String nomeProduto,
}) {
  return NotaEntradaItemRow(
    codEmpresa: 1,
    codFilial: 1,
    compraId: 80,
    compraCancelada: 'N',
    codProduto: codProduto,
    nomeProduto: nomeProduto,
    quantidade: 1,
    valorUnitario: 10,
    subTotal: 10,
    valorDescontoItem: 0,
    valorTotalDesconto: 0,
    valorDescontoProporcional: 0,
    valorTotal: 10,
  );
}
