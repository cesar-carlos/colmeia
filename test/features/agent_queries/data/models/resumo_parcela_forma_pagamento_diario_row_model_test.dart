import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_forma_pagamento_diario_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelaFormaPagamentoDiarioRowModel', () {
    test('fromMap accepts camelCase keys and DateTime DataVenda', () {
      final model = ResumoParcelaFormaPagamentoDiarioRowModel.fromMap(
        <String, dynamic>{
          'dataVenda': DateTime.utc(2026, 4, 10, 15, 30),
          'descricaoFormaPagamento': 'Pix',
          'quantidade': 3,
          'valorTotal': 99.5,
        },
      );
      check(model.dataVenda).equals(DateTime(2026, 4, 10));
      check(model.descricaoFormaPagamento).equals('Pix');
      check(model.quantidade).equals(3);
      check(model.valorTotal).equals(99.5);
    });

    test('fromMap parses DataVenda from yyyy-MM-dd string', () {
      final model = ResumoParcelaFormaPagamentoDiarioRowModel.fromMap(
        <String, dynamic>{
          'DataVenda': '2025-03-01T00:00:00',
          'descricaoformapagamento': 'Dinheiro',
          'quantidade': '10',
          'valortotal': '50.2500000',
        },
      );
      check(model.dataVenda).equals(DateTime(2025, 3));
      check(model.descricaoFormaPagamento).equals('Dinheiro');
      check(model.quantidade).equals(10);
      check(model.valorTotal).equals(50.25);
    });

    test('fromMap throws when DescricaoFormaPagamento missing', () {
      expect(
        () => ResumoParcelaFormaPagamentoDiarioRowModel.fromMap(
          <String, dynamic>{
            'dataVenda': '2026-01-01',
            'quantidade': 1,
            'valorTotal': 1.0,
          },
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
