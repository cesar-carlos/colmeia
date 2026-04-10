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
        'CodVendedor': 5,
        'NomeVendedor': 'Ana',
        'QtdeItens': 3.5,
        'ValorAcrescimo': 1.25,
        'ValorDesconto': 0.5,
        'ValorBruto': 100.0,
        'ValorLiquido': 99.75,
      };
    }

    test('fromMap accepts PascalCase', () {
      final model = ResumoVendasDiariasPorVendedorRowModel.fromMap(baseRow());
      check(model.codEmpresa).equals(1);
      check(model.dataVenda.year).equals(2026);
      check(model.dataVenda.month).equals(4);
      check(model.dataVenda.day).equals(10);
      check(model.codVendedor).equals(5);
      check(model.nomeVendedor).equals('Ana');
      check(model.qtdeItens).equals(3.5);
    });

    test('fromMap accepts camelCase and null CodVendedor', () {
      final model = ResumoVendasDiariasPorVendedorRowModel.fromMap(
        <String, dynamic>{
          'codEmpresa': 1,
          'codFilial': 1,
          'dataVenda': '2026-04-01T00:00:00Z',
          'codVendedor': null,
          'nomeVendedor': '  ',
          'qtdeItens': 1,
          'valorAcrescimo': 0,
          'valorDesconto': 0,
          'valorBruto': 10,
          'valorLiquido': '10,00',
        },
      );
      check(model.codVendedor).isNull();
      check(model.nomeVendedor).equals('Vendedor nao informado');
    });

    test('fromMap throws on invalid row', () {
      expect(
        () => ResumoVendasDiariasPorVendedorRowModel.fromMap(
          <String, dynamic>{
            'CodEmpresa': 1,
            'CodFilial': 1,
            'DataVenda': 'not-a-date',
            'NomeVendedor': 'X',
            'QtdeItens': 1,
            'ValorAcrescimo': 0,
            'ValorDesconto': 0,
            'ValorBruto': 1,
            'ValorLiquido': 1,
          },
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
