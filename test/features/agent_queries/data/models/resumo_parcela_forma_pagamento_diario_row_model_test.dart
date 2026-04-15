import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_forma_pagamento_diario_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoVendaProdutoDiarioRowModel', () {
    test('fromMap accepts camelCase keys and DateTime DataVenda', () {
      final model = ResumoVendaProdutoDiarioRowModel.fromMap(
        <String, dynamic>{
          'codEmpresa': 1,
          'codFilial': 6,
          'codProdutoVendido': 266255,
          'origem': 'OB',
          'codOrigem': 275134,
          'dataVenda': DateTime.utc(2026, 4, 10, 15, 30),
          'anoMesDataVenda': '2026/04',
          'nomeUsuario': 'Welber',
          'codVendedor': 248,
          'nomeVendedor': 'MARCELO - PI',
          'qtdVendas': 1,
          'valorTotalVenda': 4159.04,
        },
      );
      check(model.dataVenda).equals(DateTime(2026, 4, 10));
      check(model.codEmpresa).equals(1);
      check(model.codFilial).equals(6);
      check(model.codProdutoVendido).equals(266255);
      check(model.origem).equals('OB');
      check(model.codOrigem).equals(275134);
      check(model.anoMesDataVenda).equals('2026/04');
      check(model.nomeUsuario).equals('Welber');
      check(model.codVendedor).equals(248);
      check(model.nomeVendedor).equals('MARCELO - PI');
      check(model.qtdVendas).equals(1);
      check(model.valorTotalVenda).equals(4159.04);
    });

    test('fromMap parses DataVenda from yyyy-MM-dd string', () {
      final model = ResumoVendaProdutoDiarioRowModel.fromMap(
        <String, dynamic>{
          'DataVenda': '2025-03-01T00:00:00',
          'CodEmpresa': 1,
          'CodFilial': 2,
          'CodProdutoVendido': 3,
          'Origem': 'OB',
          'CodOrigem': 9,
          'AnoMesDataVenda': '2025/03',
          'NomeUsuario': 'U',
          'qtdvendas': '10',
          'valortotalvenda': '50.2500000',
        },
      );
      check(model.dataVenda).equals(DateTime(2025, 3));
      check(model.qtdVendas).equals(10);
      check(model.valorTotalVenda).equals(50.25);
    });

    test('fromMap leaves codVendedor and nomeVendedor null when absent', () {
      final model = ResumoVendaProdutoDiarioRowModel.fromMap(
        <String, dynamic>{
          'DataVenda': '2026-01-01',
          'CodEmpresa': 1,
          'CodFilial': 1,
          'CodProdutoVendido': 1,
          'Origem': 'OB',
          'CodOrigem': 1,
          'AnoMesDataVenda': '2026/01',
          'NomeUsuario': 'U',
          'QtdVendas': 1,
          'ValorTotalVenda': 1.0,
        },
      );
      check(model.codVendedor).isNull();
      check(model.nomeVendedor).isNull();
    });

    test('fromMap throws when CodVendedor is non-numeric string', () {
      expect(
        () => ResumoVendaProdutoDiarioRowModel.fromMap(
          <String, dynamic>{
            'DataVenda': '2026-01-01',
            'CodEmpresa': 1,
            'CodFilial': 1,
            'CodProdutoVendido': 1,
            'Origem': 'OB',
            'CodOrigem': 1,
            'AnoMesDataVenda': '2026/01',
            'NomeUsuario': 'U',
            'CodVendedor': 'not-a-number',
            'QtdVendas': 1,
            'ValorTotalVenda': 1.0,
          },
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromMap throws when NomeVendedor is num', () {
      expect(
        () => ResumoVendaProdutoDiarioRowModel.fromMap(
          <String, dynamic>{
            'DataVenda': '2026-01-01',
            'CodEmpresa': 1,
            'CodFilial': 1,
            'CodProdutoVendido': 1,
            'Origem': 'OB',
            'CodOrigem': 1,
            'AnoMesDataVenda': '2026/01',
            'NomeUsuario': 'U',
            'NomeVendedor': 42,
            'QtdVendas': 1,
            'ValorTotalVenda': 1.0,
          },
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromMap throws when CodEmpresa missing', () {
      expect(
        () => ResumoVendaProdutoDiarioRowModel.fromMap(
          <String, dynamic>{
            'DataVenda': '2026-01-01',
            'CodFilial': 1,
            'CodProdutoVendido': 1,
            'Origem': 'OB',
            'CodOrigem': 1,
            'AnoMesDataVenda': '2026/01',
            'NomeUsuario': 'U',
            'QtdVendas': 1,
            'ValorTotalVenda': 1.0,
          },
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
