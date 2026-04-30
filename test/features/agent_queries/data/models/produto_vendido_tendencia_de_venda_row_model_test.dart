import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_tendencia_de_venda_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProdutoVendidoTendenciaDeVendaRowModel', () {
    test('fromMap accepts camelCase keys and decimal strings', () {
      final model = ProdutoVendidoTendenciaDeVendaRowModel.fromMap(
        <String, dynamic>{
          'codEmpresa': 1,
          'codFilial': 2,
          'codProduto': 4051,
          'nomeProduto': 'BOMBA DE AR',
          'codUnidadeMedida': 'PT',
          'codGrupoProduto': 14,
          'nomeGrupoProduto': 'SUSPENSAO',
          'codMarca': 490,
          'nomeMarca': 'SMART FOX',
          'qtdAnterior': '1.0000000',
          'qtdAtual': '20.0000000',
          'diferenca': '19.0000000',
          'percentualTendencia': '1900.0000000',
          'classificacao': 'CRESCENDO',
        },
      );

      check(model.codEmpresa).equals(1);
      check(model.codFilial).equals(2);
      check(model.codProduto).equals(4051);
      check(model.codUnidadeMedida).equals('PT');
      check(model.qtdAnterior).equals(1);
      check(model.qtdAtual).equals(20);
      check(model.diferenca).equals(19);
      check(model.percentualTendencia).equals(1900);
      check(model.classificacao).equals('CRESCENDO');
    });

    test('fromMap accepts lowercase keys and nullable metadata columns', () {
      final model = ProdutoVendidoTendenciaDeVendaRowModel.fromMap(
        <String, dynamic>{
          'codempresa': 1,
          'codfilial': 1,
          'codproduto': 22937,
          'nomeproduto': 'MOLA PTE',
          'codunidademedida': 'P',
          'codgrupoproduto': null,
          'nomegrupoproduto': null,
          'codmarca': null,
          'nomemarca': null,
          'qtdanterior': 1,
          'qtdatual': 62,
          'diferenca': 61,
          'percentualtendencia': 6100,
          'classificacao': 'CRESCENDO',
        },
      );

      check(model.codGrupoProduto).isNull();
      check(model.nomeGrupoProduto).isNull();
      check(model.codMarca).isNull();
      check(model.nomeMarca).isNull();
      check(model.toEntity().percentualTendencia).equals(6100);
    });

    test('fromMap parses decimal values with comma', () {
      final model = ProdutoVendidoTendenciaDeVendaRowModel.fromMap(
        <String, dynamic>{
          'CodEmpresa': 1,
          'CodFilial': 1,
          'CodProduto': 1,
          'NomeProduto': 'Teste',
          'CodUnidadeMedida': 'UN',
          'QtdAnterior': '12,5',
          'QtdAtual': '14,25',
          'Diferenca': '1,75',
          'PercentualTendencia': '14,0',
          'Classificacao': 'ESTAVEL',
        },
      );

      check(model.qtdAnterior).equals(12.5);
      check(model.qtdAtual).equals(14.25);
      check(model.diferenca).equals(1.75);
      check(model.percentualTendencia).equals(14);
    });

    test('fromMap throws FormatException when CodProduto is missing', () {
      expect(
        () => ProdutoVendidoTendenciaDeVendaRowModel.fromMap(
          <String, dynamic>{
            'CodEmpresa': 1,
            'CodFilial': 1,
            'NomeProduto': 'Teste',
            'CodUnidadeMedida': 'UN',
            'QtdAnterior': 1,
            'QtdAtual': 2,
            'Diferenca': 1,
            'PercentualTendencia': 100,
            'Classificacao': 'CRESCENDO',
          },
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
