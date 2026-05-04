import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_tendencia_de_venda_media_movel_summary_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRowModel', () {
    test('fromMap parses summary keys and numeric values', () {
      final model =
          ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRowModel.fromMap(
            <String, dynamic>{
              'Classificacao': 'NOVO',
              'QuantidadeProdutos': '7',
              'ImpactoLiquido': '13.25',
            },
          );

      check(model.classificacao).equals('NOVO');
      check(model.quantidadeProdutos).equals(7);
      check(model.impactoLiquido).equals(13.25);
      check(model.toEntity().impactoLiquido).equals(13.25);
    });

    test('fromMap throws when mandatory keys are missing', () {
      expect(
        () => ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRowModel.fromMap(
          <String, dynamic>{'Classificacao': 'ESTAVEL'},
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
