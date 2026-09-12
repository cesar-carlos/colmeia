import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/nota_entrada_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps supported SQL date values and optional supplier fields', () {
    final row = NotaEntradaRowModel.fromMap(<String, dynamic>{
      'CompraId': 42,
      'CodEmpresa': 1,
      'CodFilial': 1,
      'NomeFilial': 'Matriz',
      'NomeFantasiaFilial': null,
      'CodTipoOperacaoCompra': 5,
      'DescricaoTipoOperacaoCompra': 'Compra para estoque',
      'NumeroDocumento': 'NF-100',
      'DataEmissao': '2026-03-05T10:30:00',
      'DataEntrada': DateTime(2026, 3, 6, 8),
      'DataLancamento': '2026-03-06T09:15:00',
      'CodFornecedor': 9,
      'NomeFornecedor': 'Fornecedor Teste',
      'NomeFantasiaFornecedor': 'Teste',
      'CnpjCpfFornecedor': null,
      'ValorTotalCompra': '125.50',
    }).toEntity();

    check(row.compraId).equals(42);
    check(row.codEmpresa).equals(1);
    check(row.codTipoOperacaoCompra).equals(5);
    check(row.numeroDocumento).equals('NF-100');
    check(row.dataEmissao).equals(DateTime(2026, 3, 5, 10, 30));
    check(row.dataEntrada).equals(DateTime(2026, 3, 6, 8));
    check(row.dataLancamento).equals(DateTime(2026, 3, 6, 9, 15));
    check(row.nomeFantasiaFilial).isNull();
    check(row.cnpjCpfFornecedor).isNull();
    check(row.valorTotalCompra).equals(125.5);
  });

  test('rejects an invalid required launch date', () {
    final map = <String, dynamic>{
      'CompraId': 42,
      'CodEmpresa': 1,
      'CodFilial': 1,
      'NomeFilial': 'Matriz',
      'CodTipoOperacaoCompra': 5,
      'DescricaoTipoOperacaoCompra': 'Compra',
      'NumeroDocumento': 'NF-1',
      'DataLancamento': 'invalid',
      'CodFornecedor': 9,
      'NomeFornecedor': 'Fornecedor',
      'ValorTotalCompra': 10,
    };

    expect(
      () => NotaEntradaRowModel.fromMap(map),
      throwsA(isA<FormatException>()),
    );
  });
}
