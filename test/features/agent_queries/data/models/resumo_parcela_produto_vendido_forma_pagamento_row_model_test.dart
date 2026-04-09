import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_produto_vendido_forma_pagamento_row_model.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_produto_vendido_forma_pagamento_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelaProdutoVendidoFormaPagamentoRowModel', () {
    test('fromMap accepts camelCase keys', () {
      final model = ResumoParcelaProdutoVendidoFormaPagamentoRowModel.fromMap(
        <String, dynamic>{
          'codEmpresa': 10,
          'codFilial': 20,
          'nomeUsuario': 'U',
          'anoDataVenda': 2026,
          'mesDataVenda': 3,
          'anoMesDataVenda': '2026/03',
          'codFormaPagamento': 'P',
          'descricaoFormaPagamento': 'Pix',
          'qtdVendas': 2,
          'valorParcela': 50.0,
        },
      );
      check(model.codEmpresa).equals(10);
      check(model.anoMesDataVenda).equals('2026/03');
      check(model.toEntity().isAnoMesConsistentWithParts).isTrue();
    });
  });

  group('ResumoParcelaProdutoVendidoFormaPagamentoRow.isAnoMesConsistent', () {
    test('returns true for padded month label', () {
      check(
        ResumoParcelaProdutoVendidoFormaPagamentoRow.isAnoMesConsistent(
          anoMesDataVenda: '2026/04',
          anoDataVenda: 2026,
          mesDataVenda: 4,
        ),
      ).isTrue();
    });

    test('returns false when parts do not match ints', () {
      check(
        ResumoParcelaProdutoVendidoFormaPagamentoRow.isAnoMesConsistent(
          anoMesDataVenda: '2026/05',
          anoDataVenda: 2026,
          mesDataVenda: 4,
        ),
      ).isFalse();
    });
  });
}
