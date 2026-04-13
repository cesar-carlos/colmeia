import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_forma_pagamento_por_mes_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasFormaPagamentoPorMesRowModel', () {
    test('fromMap accepts camelCase keys', () {
      final model = ResumoParcelasFormaPagamentoPorMesRowModel.fromMap(
        <String, dynamic>{
          'codEmpresa': 1,
          'codFilial': 6,
          'nomeUsuario': 'Ada',
          'anoMesDataVenda': '2026/01',
          'codFormaPagamento': 'PX',
          'descricaoFormaPagamento': 'PIX',
          'qtdVendas': 3,
          'valorParcela': 99.5,
        },
      );
      check(model.codEmpresa).equals(1);
      check(model.codFilial).equals(6);
      check(model.nomeUsuario).equals('Ada');
      check(model.anoMesDataVenda).equals('2026/01');
      check(model.codFormaPagamento).equals('PX');
      check(model.descricaoFormaPagamento).equals('PIX');
      check(model.qtdVendas).equals(3);
      check(model.valorParcela).equals(99.5);
      check(model.toEntity().descricaoFormaPagamento).equals('PIX');
    });

    test('fromMap accepts all-lowercase keys (bridge JSON)', () {
      final model = ResumoParcelasFormaPagamentoPorMesRowModel.fromMap(
        <String, dynamic>{
          'codempresa': 2,
          'codfilial': 10,
          'nomeusuario': 'Bob',
          'anomesdatavenda': '2025/12',
          'codformapagamento': 42,
          'descricaoformapagamento': 'Cartao',
          'qtdvendas': '10',
          'valorparcela': '50.2500000',
        },
      );
      check(model.codEmpresa).equals(2);
      check(model.codFormaPagamento).equals('42');
      check(model.qtdVendas).equals(10);
      check(model.valorParcela).equals(50.25);
    });

    test(
      'fromMap throws FormatException when DescricaoFormaPagamento missing',
      () {
        expect(
          () => ResumoParcelasFormaPagamentoPorMesRowModel.fromMap(
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 1,
              'NomeUsuario': 'x',
              'AnoMesDataVenda': '2024/01',
              'CodFormaPagamento': 'PX',
              'QtdVendas': 1,
              'ValorParcela': 1.0,
            },
          ),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });
}
