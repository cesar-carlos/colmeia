import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_vendas_diarias_por_vendedor_vendedor_option_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromMap accepts PascalCase keys', () {
    final model = ResumoVendasDiariasPorVendedorVendedorOptionModel.fromMap(
      <String, dynamic>{
        'CodVendedor': 5,
        'NomeVendedor': '  Ana  ',
      },
    );
    check(model.codVendedor).equals(5);
    check(model.nomeVendedor).equals('Ana');
    check(model.toEntity().codVendedor).equals(5);
  });

  test('fromMap accepts camelCase keys', () {
    final model = ResumoVendasDiariasPorVendedorVendedorOptionModel.fromMap(
      <String, dynamic>{
        'codVendedor': 8,
        'nomeVendedor': 'Bob',
      },
    );
    check(model.codVendedor).equals(8);
    check(model.nomeVendedor).equals('Bob');
  });

  test('fromMap accepts lowercase keys and parses cod from string', () {
    final model = ResumoVendasDiariasPorVendedorVendedorOptionModel.fromMap(
      <String, dynamic>{
        'codvendedor': '12',
        'nomevendedor': 'Cia',
      },
    );
    check(model.codVendedor).equals(12);
    check(model.nomeVendedor).equals('Cia');
  });

  test('fromMap throws FormatException when cod is missing', () {
    expect(
      () => ResumoVendasDiariasPorVendedorVendedorOptionModel.fromMap(
        <String, dynamic>{'NomeVendedor': 'X'},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('fromMap throws FormatException when nome is empty', () {
    expect(
      () => ResumoVendasDiariasPorVendedorVendedorOptionModel.fromMap(
        <String, dynamic>{'CodVendedor': 1, 'NomeVendedor': '   '},
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
