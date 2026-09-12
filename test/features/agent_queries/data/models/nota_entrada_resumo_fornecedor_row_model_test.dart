import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/nota_entrada_resumo_fornecedor_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps supplier totals and optional identity fields', () {
    final row = NotaEntradaResumoFornecedorRowModel.fromMap(<String, dynamic>{
      'CodEmpresa': 1,
      'CodFilial': 1,
      'NomeFilial': 'Matriz',
      'NomeFantasiaFilial': null,
      'CodFornecedor': 9,
      'NomeFornecedor': 'Fornecedor Teste',
      'NomeFantasiaFornecedor': 'Teste',
      'CnpjCpfFornecedor': null,
      'QtdNotas': 3,
      'TicketMedio': '41.8333',
      'ValorTotalCompra': '125.50',
    }).toEntity();

    check(row.codEmpresa).equals(1);
    check(row.codFilial).equals(1);
    check(row.nomeFilial).equals('Matriz');
    check(row.nomeFantasiaFilial).isNull();
    check(row.codFornecedor).equals(9);
    check(row.nomeFornecedor).equals('Fornecedor Teste');
    check(row.nomeFantasiaFornecedor).equals('Teste');
    check(row.cnpjCpfFornecedor).isNull();
    check(row.qtdNotas).equals(3);
    check(row.ticketMedio).equals(41.8333);
    check(row.valorTotalCompra).equals(125.5);
  });

  test('rejects a missing required supplier name', () {
    final map = <String, dynamic>{
      'CodEmpresa': 1,
      'CodFilial': 1,
      'NomeFilial': 'Matriz',
      'CodFornecedor': 9,
      'NomeFornecedor': '',
      'QtdNotas': 1,
      'TicketMedio': 10,
      'ValorTotalCompra': 10,
    };

    expect(
      () => NotaEntradaResumoFornecedorRowModel.fromMap(map),
      throwsA(isA<FormatException>()),
    );
  });
}
