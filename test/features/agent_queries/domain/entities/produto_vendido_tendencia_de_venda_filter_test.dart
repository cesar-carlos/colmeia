import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProdutoVendidoTendenciaDeVendaFilter', () {
    ProdutoVendidoTendenciaDeVendaFilter buildValid({
      String? classificacao,
      int? codGrupoProduto,
      int? codMarca,
      String? searchTerm,
    }) {
      return ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: DateTime(2026, 3),
        periodoAtualFim: DateTime(2026, 3, 31),
        periodoAnteriorInicio: DateTime(2026, 2),
        periodoAnteriorFim: DateTime(2026, 2, 28),
        classificacao: classificacao,
        codGrupoProduto: codGrupoProduto,
        codMarca: codMarca,
        searchTerm: searchTerm,
      );
    }

    test('accepts valid optional detail filters', () {
      final filter = buildValid(
        classificacao: 'CRESCENDO',
        codGrupoProduto: 14,
        codMarca: 490,
        searchTerm: 'smart fox',
      );

      check(filter.validationError()).isNull();
      check(filter.normalizedClassificacao).equals('CRESCENDO');
      check(filter.normalizedSearchTerm).equals('smart fox');
    });

    test('rejects unsupported classificacao', () {
      final filter = buildValid(classificacao: 'invalida');
      check(filter.validationError()).equals('classificacao is not allowed');
    });

    test('rejects non-positive codGrupoProduto', () {
      final filter = buildValid(codGrupoProduto: 0);
      check(filter.validationError()).equals(
        'codGrupoProduto must be > 0 when provided',
      );
    });

    test('rejects non-positive codMarca', () {
      final filter = buildValid(codMarca: -1);
      check(filter.validationError()).equals(
        'codMarca must be > 0 when provided',
      );
    });
  });
}
