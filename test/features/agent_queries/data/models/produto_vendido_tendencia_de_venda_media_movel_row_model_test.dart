import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_tendencia_de_venda_media_movel_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProdutoVendidoTendenciaDeVendaMediaMovelRowModel', () {
    test('maps required and optional fields from SQL row map', () {
      final model = ProdutoVendidoTendenciaDeVendaMediaMovelRowModel.fromMap(
        <String, dynamic>{
          'CodEmpresa': 1,
          'CodFilial': 2,
          'CodProduto': 99,
          'NomeProduto': 'Prod A',
          'CodUnidadeMedida': 'UN',
          'CodGrupoProduto': 5,
          'NomeGrupoProduto': 'Grupo',
          'CodMarca': 7,
          'NomeMarca': 'Marca',
          'MediaAtual': '12.5',
          'MediaAnterior': '10.0',
          'Diferenca': '2.5',
          'TendenciaPercentual': '25.0',
          'Classificacao': 'CRESCENDO',
        },
      );

      final entity = model.toEntity();
      check(entity.codEmpresa).equals(1);
      check(entity.codFilial).equals(2);
      check(entity.codProduto).equals(99);
      check(entity.nomeProduto).equals('Prod A');
      check(entity.codUnidadeMedida).equals('UN');
      check(entity.codGrupoProduto).equals(5);
      check(entity.nomeGrupoProduto).equals('Grupo');
      check(entity.codMarca).equals(7);
      check(entity.nomeMarca).equals('Marca');
      check(entity.mediaAtual).equals(12.5);
      check(entity.mediaAnterior).equals(10);
      check(entity.diferenca).equals(2.5);
      check(entity.tendenciaPercentual).equals(25);
      check(entity.classificacao).equals('CRESCENDO');
    });

    test('throws FormatException when required fields are missing', () {
      expect(
        () => ProdutoVendidoTendenciaDeVendaMediaMovelRowModel.fromMap(
          <String, dynamic>{'CodEmpresa': 1},
        ),
        throwsFormatException,
      );
    });
  });
}
