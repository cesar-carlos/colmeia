import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/nota_entrada_item_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a cancelled line from lowercase bridge keys', () {
    final row = NotaEntradaItemRowModel.fromMap(<String, dynamic>{
      'codempresa': 2,
      'codfilial': 17,
      'compraid': 80,
      'compracancelada': 'S',
      'codproduto': 15,
      'nomeproduto': 'Mel silvestre',
      'codunidademedida': 'UN',
      'descricaounidademedida': 'UN',
      'codgrupoproduto': 3,
      'nomegrupoproduto': 'Alimentos',
      'quantidade': 2,
      'valorunitario': 22.75,
      'subtotal': 45.5,
      'valordescontoitem': 0,
      'valortotaldesconto': 0,
      'valordescontoproporcional': 0,
      'valortotal': 45.5,
    }).toEntity();

    check(row.codEmpresa).equals(2);
    check(row.codFilial).equals(17);
    check(row.compraId).equals(80);
    check(row.compraCancelada).equals('S');
    check(row.isCancelled).isTrue();
    check(row.nomeProduto).equals('Mel silvestre');
    check(row.codUnidadeMedida).equals('UN');
  });

  test('keeps the line when product, unit, and group are null', () {
    final row = NotaEntradaItemRowModel.fromMap(
      _row(
        nomeProduto: null,
        codUnidadeMedida: null,
        descricaoUnidadeMedida: null,
        codGrupoProduto: null,
        nomeGrupoProduto: null,
      ),
    ).toEntity();

    check(row.nomeProduto).equals('');
    check(row.codUnidadeMedida).isNull();
    check(row.descricaoUnidadeMedida).isNull();
    check(row.codGrupoProduto).isNull();
    check(row.nomeGrupoProduto).isNull();
    check(row.codProduto).equals(15);
  });

  test('maps a textual unit code and a Sim/Nao cancelled flag', () {
    final cancelled = NotaEntradaItemRowModel.fromMap(
      _row(compraCancelada: 'Sim', codUnidadeMedida: 'UNIDADE'),
    ).toEntity();
    final active = NotaEntradaItemRowModel.fromMap(
      _row(compraCancelada: 'Nao'),
    ).toEntity();

    check(cancelled.isCancelled).isTrue();
    check(cancelled.codUnidadeMedida).equals('UNIDADE');
    check(active.isCancelled).isFalse();
    check(active.codUnidadeMedida).equals('UN');
  });
}

Map<String, dynamic> _row({
  Object? nomeProduto = 'Mel silvestre',
  Object? codUnidadeMedida = 'UN',
  Object? descricaoUnidadeMedida = 'UNIDADE',
  Object? codGrupoProduto = 3,
  Object? nomeGrupoProduto = 'Alimentos',
  String compraCancelada = 'N',
}) {
  return <String, dynamic>{
    'CodEmpresa': 1,
    'CodFilial': 1,
    'CompraId': 80,
    'CompraCancelada': compraCancelada,
    'CodProduto': 15,
    'NomeProduto': nomeProduto,
    'CodUnidadeMedida': codUnidadeMedida,
    'DescricaoUnidadeMedida': descricaoUnidadeMedida,
    'CodGrupoProduto': codGrupoProduto,
    'NomeGrupoProduto': nomeGrupoProduto,
    'Quantidade': 2,
    'ValorUnitario': 22.75,
    'SubTotal': 45.5,
    'ValorDescontoItem': 0,
    'ValorTotalDesconto': 0,
    'ValorDescontoProporcional': 0,
    'ValorTotal': 45.5,
  };
}
