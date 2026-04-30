import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_tendencia_de_venda_summary_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProdutoVendidoTendenciaDeVendaSummaryRowModel', () {
    test('fromMap parses summary keys and numeric values', () {
      final model = ProdutoVendidoTendenciaDeVendaSummaryRowModel.fromMap(
        <String, dynamic>{
          'Classificacao': 'CRESCENDO',
          'QuantidadeProdutos': '12',
          'ImpactoLiquido': '34.5',
        },
      );

      check(model.classificacao).equals('CRESCENDO');
      check(model.quantidadeProdutos).equals(12);
      check(model.impactoLiquido).equals(34.5);
      check(model.toEntity().impactoLiquido).equals(34.5);
    });

    test('fromMap throws when mandatory keys are missing', () {
      expect(
        () => ProdutoVendidoTendenciaDeVendaSummaryRowModel.fromMap(
          <String, dynamic>{'Classificacao': 'ESTAVEL'},
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
