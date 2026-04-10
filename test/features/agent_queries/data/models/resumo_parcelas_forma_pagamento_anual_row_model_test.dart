import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_forma_pagamento_anual_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasFormaPagamentoAnualRowModel', () {
    test('fromMap accepts camelCase keys', () {
      final model = ResumoParcelasFormaPagamentoAnualRowModel.fromMap(
        <String, dynamic>{
          'ano': 2026,
          'descricaoFormaPagamento': 'Dinheiro',
          'quantidade': 3,
          'valorTotal': 99.5,
        },
      );
      check(model.ano).equals(2026);
      check(model.descricaoFormaPagamento).equals('Dinheiro');
      check(model.quantidade).equals(3);
      check(model.valorTotal).equals(99.5);
      check(model.toEntity().descricaoFormaPagamento).equals('Dinheiro');
    });

    test('fromMap accepts all-lowercase keys (bridge JSON)', () {
      final model = ResumoParcelasFormaPagamentoAnualRowModel.fromMap(
        <String, dynamic>{
          'ano': 2025,
          'descricaoformapagamento': 'Cartao',
          'quantidade': '10',
          'valortotal': '50.2500000',
        },
      );
      check(model.ano).equals(2025);
      check(model.descricaoFormaPagamento).equals('Cartao');
      check(model.quantidade).equals(10);
      check(model.valorTotal).equals(50.25);
    });

    test(
      'fromMap throws FormatException when DescricaoFormaPagamento missing',
      () {
        expect(
          () => ResumoParcelasFormaPagamentoAnualRowModel.fromMap(
            <String, dynamic>{
              'Ano': 2024,
              'Quantidade': 1,
              'ValorTotal': 1.0,
            },
          ),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });
}
