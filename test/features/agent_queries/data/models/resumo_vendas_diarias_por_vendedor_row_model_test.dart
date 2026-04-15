import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_vendas_diarias_por_vendedor_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoVendasDiariasPorVendedorRowModel', () {
    Map<String, dynamic> baseRow() {
      return <String, dynamic>{
        'CodEmpresa': 1,
        'CodFilial': 2,
        'DataVenda': '2026-04-10',
        'AnoMesDataVenda': '2026/04',
        'CodVendedor': 5,
        'NomeVendedor': 'Ana',
        'QtdVendas': 3,
        'ValorTotalVenda': 99.75,
      };
    }

    test('fromMap accepts PascalCase', () {
      final model = ResumoVendasDiariasPorVendedorRowModel.fromMap(baseRow());
      check(model.codEmpresa).equals(1);
      check(model.dataVenda.year).equals(2026);
      check(model.dataVenda.month).equals(4);
      check(model.dataVenda.day).equals(10);
      check(model.anoMesDataVenda).equals('2026/04');
      check(model.codVendedor).equals(5);
      check(model.nomeVendedor).equals('Ana');
      check(model.qtdVendas).equals(3);
      check(model.valorTotalVenda).equals(99.75);
    });

    test('fromMap accepts camelCase and null CodVendedor', () {
      final model = ResumoVendasDiariasPorVendedorRowModel.fromMap(
        <String, dynamic>{
          'codEmpresa': 1,
          'codFilial': 1,
          'dataVenda': '2026-04-01T00:00:00Z',
          'anoMesDataVenda': '2026/04',
          'codVendedor': null,
          'nomeVendedor': '  ',
          'qtdVendas': 1,
          'valorTotalVenda': '10,00',
        },
      );
      check(model.codVendedor).isNull();
      check(model.nomeVendedor).isNull();
      check(model.qtdVendas).equals(1);
      check(model.valorTotalVenda).equals(10);
    });

    test('fromMap throws on invalid row', () {
      expect(
        () => ResumoVendasDiariasPorVendedorRowModel.fromMap(
          <String, dynamic>{
            'CodEmpresa': 1,
            'CodFilial': 1,
            'DataVenda': 'not-a-date',
            'AnoMesDataVenda': '2026/04',
            'NomeVendedor': 'X',
            'QtdVendas': 1,
            'ValorTotalVenda': 1,
          },
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromMap throws when NomeVendedor is num', () {
      expect(
        () => ResumoVendasDiariasPorVendedorRowModel.fromMap(
          <String, dynamic>{
            'CodEmpresa': 1,
            'CodFilial': 1,
            'DataVenda': '2026-04-10',
            'AnoMesDataVenda': '2026/04',
            'CodVendedor': 1,
            'NomeVendedor': 99,
            'QtdVendas': 1,
            'ValorTotalVenda': 1.0,
          },
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
