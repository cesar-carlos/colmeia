import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_forma_pagamento_row_model.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelaFormaPagamentoRowModel', () {
    test('fromMap accepts camelCase keys', () {
      final model = ResumoParcelaFormaPagamentoRowModel.fromMap(
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

    test('fromMap accepts all-lowercase keys (bridge JSON)', () {
      final model = ResumoParcelaFormaPagamentoRowModel.fromMap(
        <String, dynamic>{
          'codempresa': 1,
          'codfilial': 2,
          'nomeusuario': 'CAIXA1',
          'anodatavenda': 2026,
          'mesdatavenda': 3,
          'anomesdatavenda': '2026/3',
          'codformapagamento': 'PIX',
          'descricaoformapagamento': 'PIX 1',
          'qtdvendas': 5,
          'valorparcela': '123.4500000',
        },
      );
      check(model.codEmpresa).equals(1);
      check(model.valorParcela).equals(123.45);
      check(model.anoMesDataVenda).equals('2026/3');
      check(model.toEntity().isAnoMesConsistentWithParts).isTrue();
    });

    test('fromMap parses ValorParcela from decimal string', () {
      final model = ResumoParcelaFormaPagamentoRowModel.fromMap(
        <String, dynamic>{
          'codEmpresa': 1,
          'codFilial': 1,
          'nomeUsuario': 'U',
          'anoDataVenda': 2026,
          'mesDataVenda': 4,
          'anoMesDataVenda': '2026/04',
          'codFormaPagamento': 'X',
          'descricaoFormaPagamento': 'Y',
          'qtdVendas': 1,
          'valorParcela': '14704.2900000',
        },
      );
      check(model.valorParcela).equals(14704.29);
    });

    test(
      'fromMap throws FormatException when AnoMes disagrees with parts',
      () {
        expect(
          () => ResumoParcelaFormaPagamentoRowModel.fromMap(
            <String, dynamic>{
              'codEmpresa': 1,
              'codFilial': 1,
              'nomeUsuario': 'U',
              'anoDataVenda': 2026,
              'mesDataVenda': 4,
              'anoMesDataVenda': '2026/05',
              'codFormaPagamento': 'X',
              'descricaoFormaPagamento': 'Y',
              'qtdVendas': 1,
              'valorParcela': 1.0,
            },
          ),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });

  group('ResumoParcelaFormaPagamentoRow.isAnoMesConsistent', () {
    test('returns true for padded month label', () {
      check(
        ResumoParcelaFormaPagamentoRow.isAnoMesConsistent(
          anoMesDataVenda: '2026/04',
          anoDataVenda: 2026,
          mesDataVenda: 4,
        ),
      ).isTrue();
    });

    test('returns false when parts do not match ints', () {
      check(
        ResumoParcelaFormaPagamentoRow.isAnoMesConsistent(
          anoMesDataVenda: '2026/05',
          anoDataVenda: 2026,
          mesDataVenda: 4,
        ),
      ).isFalse();
    });
  });
}
