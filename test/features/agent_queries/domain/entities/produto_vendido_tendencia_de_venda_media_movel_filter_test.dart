import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProdutoVendidoTendenciaDeVendaMediaMovelFilter', () {
    ProdutoVendidoTendenciaDeVendaMediaMovelFilter buildValid({
      int quantidadeDias = 7,
      String? classificacao,
      int? codGrupoProduto,
      int? codMarca,
      String? searchTerm,
    }) {
      return ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
        quantidadeDias: quantidadeDias,
        classificacao: classificacao,
        codGrupoProduto: codGrupoProduto,
        codMarca: codMarca,
        searchTerm: searchTerm,
      );
    }

    test('accepts valid optional detail filters', () {
      final filter = buildValid(
        quantidadeDias: 14,
        classificacao: 'CRESCENDO',
        codGrupoProduto: 14,
        codMarca: 490,
        searchTerm: 'smart fox',
      );

      check(filter.validationError()).isNull();
      check(filter.normalizedClassificacao).equals('CRESCENDO');
      check(filter.normalizedSearchTerm).equals('smart fox');
      check(filter.startRow).equals(1);
      check(filter.endRow).equals(20);
      check(
        ProdutoVendidoTendenciaDeVendaMediaMovelFilter.defaultMinVolumeUnits,
      ).equals(10);
    });

    test('rejects non-positive quantidadeDias', () {
      final filter = buildValid(quantidadeDias: 0);
      check(filter.validationError()).equals(
        ProdutoVendidoTendenciaDeVendaMediaMovelFilter
            .errorQuantidadeDiasMustBePositive,
      );
    });

    test('rejects unsupported classificacao', () {
      final filter = buildValid(classificacao: 'invalida');
      check(filter.validationError()).equals(
        ProdutoVendidoTendenciaDeVendaMediaMovelFilter
            .errorClassificacaoNotAllowed,
      );
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

    test('maps custom page bounds', () {
      final filter = buildValid(quantidadeDias: 21).copyWith(page: 3);
      check(filter.startRow).equals(41);
      check(filter.endRow).equals(60);
    });

    test('keeps sortBy when provided', () {
      final filter = buildValid().copyWith(
        sortBy: ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.diferencaDesc,
      );

      check(filter.sortBy).equals(
        ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.diferencaDesc,
      );
    });
  });
}

extension on ProdutoVendidoTendenciaDeVendaMediaMovelFilter {
  ProdutoVendidoTendenciaDeVendaMediaMovelFilter copyWith({
    int? quantidadeDias,
    String? origem,
    String? searchTerm,
    String? classificacao,
    int? codGrupoProduto,
    int? codMarca,
    ProdutoVendidoTendenciaDeVendaMediaMovelSortBy? sortBy,
    int? page,
    int? pageSize,
  }) {
    return ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
      quantidadeDias: quantidadeDias ?? this.quantidadeDias,
      origem: origem ?? this.origem,
      searchTerm: searchTerm ?? this.searchTerm,
      classificacao: classificacao ?? this.classificacao,
      codGrupoProduto: codGrupoProduto ?? this.codGrupoProduto,
      codMarca: codMarca ?? this.codMarca,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}
