import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_forma_pagamento_row_model_v2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelaFormaPagamentoRowModelV2', () {
    test('fromMap accepts camelCase keys', () {
      final model = ResumoParcelaFormaPagamentoRowModelV2.fromMap(
        <String, dynamic>{
          'codEmpresa': 10,
          'codFilial': 20,
          'codFormaPagamento': 'P',
          'descricaoFormaPagamento': 'Pix',
          'qtdVendas': 2,
          'valorParcela': 50.0,
        },
      );
      check(model.codEmpresa).equals(10);
      check(model.codFilial).equals(20);
      check(model.toEntity().codFormaPagamento).equals('P');
    });

    test('fromMap accepts all-lowercase keys (bridge JSON)', () {
      final model = ResumoParcelaFormaPagamentoRowModelV2.fromMap(
        <String, dynamic>{
          'codempresa': 1,
          'codfilial': 2,
          'codformapagamento': 'PIX',
          'descricaoformapagamento': 'PIX 1',
          'qtdvendas': 5,
          'valorparcela': '123.4500000',
        },
      );
      check(model.codEmpresa).equals(1);
      check(model.valorParcela).equals(123.45);
    });

    test('fromMap parses ValorParcela from decimal string', () {
      final model = ResumoParcelaFormaPagamentoRowModelV2.fromMap(
        <String, dynamic>{
          'codEmpresa': 1,
          'codFilial': 1,
          'codFormaPagamento': 'X',
          'descricaoFormaPagamento': 'Y',
          'qtdVendas': 1,
          'valorParcela': '14704.2900000',
        },
      );
      check(model.valorParcela).equals(14704.29);
    });
  });
}
