import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_metric_mode.dart';
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
      check(filter.validationError()).equals(
        ProdutoVendidoTendenciaDeVendaFilter.errorClassificacaoNotAllowed,
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

    test('rejects previous period that does not end before current starts', () {
      final filter = ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: DateTime(2026, 3),
        periodoAtualFim: DateTime(2026, 3, 31),
        periodoAnteriorInicio: DateTime(2026, 3),
        periodoAnteriorFim: DateTime(2026, 3, 31),
      );

      check(filter.validationError()).equals(
        ProdutoVendidoTendenciaDeVendaFilter
            .errorPeriodoAnteriorMustBeBeforeAtual,
      );
    });

    test('accepts equivalent full-month comparison windows', () {
      final filter = ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: DateTime(2026, 4),
        periodoAtualFim: DateTime(2026, 4, 30),
        periodoAnteriorInicio: DateTime(2026, 3),
        periodoAnteriorFim: DateTime(2026, 3, 31),
      );

      check(filter.validationError()).isNull();
    });

    test('accepts month-to-date windows aligned to the previous month', () {
      final filter = ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: DateTime(2026, 7),
        periodoAtualFim: DateTime(2026, 7, 21),
        periodoAnteriorInicio: DateTime(2026, 6),
        periodoAnteriorFim: DateTime(2026, 6, 21),
      );

      check(filter.validationError()).isNull();
      check(
        ProdutoVendidoTendenciaDeVendaFilter.defaultMinVolumeUnits,
      ).equals(10);
    });

    test('normalizes legacy classificacao labels', () {
      final filter = buildValid(classificacao: 'NOVO PRODUTO');
      check(filter.validationError()).isNull();
      check(filter.normalizedClassificacao).equals('NOVO');
    });

    test('accepts filial, metric, volume, and threshold knobs', () {
      final filter = ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: DateTime(2026, 3),
        periodoAtualFim: DateTime(2026, 3, 31),
        periodoAnteriorInicio: DateTime(2026, 2),
        periodoAnteriorFim: DateTime(2026, 2, 28),
        codFilial: 2,
        metricMode: SalesTrendMetricMode.revenue,
        minVolumeUnits: 50,
        trendThresholdPercent: 0.1,
      );
      check(filter.validationError()).isNull();
    });

    test(
      'accepts month-to-date when previous month is clamped to its last day',
      () {
        final filter = ProdutoVendidoTendenciaDeVendaFilter(
          periodoAtualInicio: DateTime(2026, 3),
          periodoAtualFim: DateTime(2026, 3, 30),
          periodoAnteriorInicio: DateTime(2026, 2),
          periodoAnteriorFim: DateTime(2026, 2, 28),
        );

        check(filter.validationError()).isNull();
      },
    );

    test('rejects full-month windows with different month spans', () {
      final filter = ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: DateTime(2026, 4),
        periodoAtualFim: DateTime(2026, 4, 30),
        periodoAnteriorInicio: DateTime(2026, 2),
        periodoAnteriorFim: DateTime(2026, 3, 31),
      );

      check(filter.validationError()).equals(
        ProdutoVendidoTendenciaDeVendaFilter
            .errorPeriodsMustCoverEquivalentWindows,
      );
    });

    test('rejects custom comparison windows with different inclusive days', () {
      final filter = ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: DateTime(2026, 4, 10),
        periodoAtualFim: DateTime(2026, 4, 20),
        periodoAnteriorInicio: DateTime(2026, 3, 25),
        periodoAnteriorFim: DateTime(2026, 4, 2),
      );

      check(filter.validationError()).equals(
        ProdutoVendidoTendenciaDeVendaFilter
            .errorPeriodsMustCoverEquivalentWindows,
      );
    });
  });
}
