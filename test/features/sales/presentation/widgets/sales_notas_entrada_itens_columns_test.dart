import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_item_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_itens_columns.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hides accessory money columns that are all zero', () {
    final hidden = SalesNotasEntradaItensVisibleColumns.fromRows(
      <NotaEntradaItemRow>[_row()],
    );
    final withDiscount = SalesNotasEntradaItensVisibleColumns.fromRows(
      <NotaEntradaItemRow>[_row(valorDescontoItem: 3)],
    );

    check(hidden.accessoryCount).equals(0);
    check(hidden.descontoItem).isFalse();
    check(withDiscount.descontoItem).isTrue();
    check(withDiscount.accessoryCount).equals(1);
    check(SalesNotasEntradaItensTableLayout.minWidth(withDiscount)).equals(
      SalesNotasEntradaItensTableLayout.minWidth(hidden) +
          SalesNotasEntradaItensTableLayout.moneyWidth,
    );
  });

  test('shows only the accessory columns that have an amount', () {
    final columns = SalesNotasEntradaItensVisibleColumns.fromRows(
      <NotaEntradaItemRow>[
        _row(valorDescontoItem: 1),
        _row(valorDescontoTotal: 2),
      ],
    );

    check(columns.descontoItem).isTrue();
    check(columns.descontoTotal).isTrue();
    check(columns.descontoProporcional).isFalse();
    check(columns.subtotal).isFalse();
    check(columns.accessoryCount).equals(2);
  });
}

NotaEntradaItemRow _row({
  double valorDescontoItem = 0,
  double valorDescontoTotal = 0,
}) {
  return NotaEntradaItemRow(
    codEmpresa: 1,
    codFilial: 1,
    compraId: 80,
    compraCancelada: 'N',
    codProduto: 15,
    nomeProduto: 'Mel',
    quantidade: 1,
    valorUnitario: 10,
    subTotal: 0,
    valorDescontoItem: valorDescontoItem,
    valorTotalDesconto: valorDescontoTotal,
    valorDescontoProporcional: 0,
    valorTotal: 10,
  );
}
