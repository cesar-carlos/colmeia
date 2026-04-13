import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_anual_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasAnualRowModel', () {
    test('fromMap accepts PascalCase keys', () {
      final model = ResumoParcelasAnualRowModel.fromMap(
        <String, dynamic>{
          'CodEmpresa': 1,
          'CodFilial': 6,
          'AnoDataVenda': 2026,
          'CodFormaPagamento': 'BL',
          'DescricaoFormaPagamento': 'BOLETO',
          'QtdVendas': 566,
          'ValorParcela': 2939701.8,
        },
      );
      check(model.codEmpresa).equals(1);
      check(model.codFilial).equals(6);
      check(model.anoDataVenda).equals(2026);
      check(model.codFormaPagamento).equals('BL');
      check(model.descricaoFormaPagamento).equals('BOLETO');
      check(model.qtdVendas).equals(566);
      check(model.valorParcela).equals(2939701.8);
      final entity = model.toEntity();
      check(entity.qtdVendas).equals(566);
    });

    test('fromMap accepts camelCase keys', () {
      final model = ResumoParcelasAnualRowModel.fromMap(
        <String, dynamic>{
          'codEmpresa': 1,
          'codFilial': 6,
          'anoDataVenda': 2026,
          'codFormaPagamento': 'CC',
          'descricaoFormaPagamento': 'CARTÃO CRÉDITO',
          'qtdVendas': '1',
          'valorParcela': 259.536013,
        },
      );
      check(model.qtdVendas).equals(1);
      check(model.codFormaPagamento).equals('CC');
    });

    test('fromMap parses CodFormaPagamento from int', () {
      final model = ResumoParcelasAnualRowModel.fromMap(
        <String, dynamic>{
          'CodEmpresa': 1,
          'CodFilial': 1,
          'AnoDataVenda': 2025,
          'CodFormaPagamento': 99,
          'DescricaoFormaPagamento': 'X',
          'QtdVendas': 0,
          'ValorParcela': 0,
        },
      );
      check(model.codFormaPagamento).equals('99');
    });

    test('fromMap parses ValorParcela from decimal string with comma', () {
      final model = ResumoParcelasAnualRowModel.fromMap(
        <String, dynamic>{
          'CodEmpresa': 1,
          'CodFilial': 1,
          'AnoDataVenda': 2024,
          'CodFormaPagamento': 'DH',
          'DescricaoFormaPagamento': 'DINHEIRO',
          'QtdVendas': 1,
          'ValorParcela': '1234,56',
        },
      );
      check(model.valorParcela).equals(1234.56);
    });

    test('fromMap throws FormatException when AnoDataVenda is missing', () {
      expect(
        () => ResumoParcelasAnualRowModel.fromMap(
          <String, dynamic>{
            'CodEmpresa': 1,
            'CodFilial': 1,
            'CodFormaPagamento': 'BL',
            'DescricaoFormaPagamento': 'BOLETO',
            'QtdVendas': 1,
            'ValorParcela': 1.0,
          },
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
