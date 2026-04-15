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
          'QtdVendas': 566,
          'ValorTotalVenda': 2939701.8,
        },
      );
      check(model.codEmpresa).equals(1);
      check(model.codFilial).equals(6);
      check(model.anoDataVenda).equals(2026);
      check(model.qtdVendas).equals(566);
      check(model.valorTotalVenda).equals(2939701.8);
      final entity = model.toEntity();
      check(entity.qtdVendas).equals(566);
    });

    test('fromMap accepts camelCase keys', () {
      final model = ResumoParcelasAnualRowModel.fromMap(
        <String, dynamic>{
          'codEmpresa': 1,
          'codFilial': 6,
          'anoDataVenda': 2026,
          'qtdVendas': '1',
          'valorTotalVenda': 259.536013,
        },
      );
      check(model.qtdVendas).equals(1);
      check(model.valorTotalVenda).equals(259.536013);
    });

    test('fromMap parses ValorTotalVenda from decimal string with comma', () {
      final model = ResumoParcelasAnualRowModel.fromMap(
        <String, dynamic>{
          'CodEmpresa': 1,
          'CodFilial': 1,
          'AnoDataVenda': 2024,
          'QtdVendas': 1,
          'ValorTotalVenda': '1234,56',
        },
      );
      check(model.valorTotalVenda).equals(1234.56);
    });

    test('fromMap throws FormatException when AnoDataVenda is missing', () {
      expect(
        () => ResumoParcelasAnualRowModel.fromMap(
          <String, dynamic>{
            'CodEmpresa': 1,
            'CodFilial': 1,
            'QtdVendas': 1,
            'ValorTotalVenda': 1.0,
          },
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
