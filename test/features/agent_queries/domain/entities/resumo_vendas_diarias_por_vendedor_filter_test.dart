import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoVendasDiariasPorVendedorFilter', () {
    test('validationError when dataVendaFim is before dataVendaInicio', () {
      final filter = ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: DateTime.utc(2026, 4, 10),
        dataVendaFim: DateTime.utc(2026, 4, 9),
      );
      check(filter.validationError()).isNotNull();
    });

    test('validationError when codVendedor is zero', () {
      final filter = ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
        codVendedor: 0,
      );
      check(filter.validationError()).isNotNull();
    });

    test('sqlCodVendedor is null when codVendedor is absent', () {
      final filter = ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
      );
      check(filter.sqlCodVendedor).isNull();
      check(filter.sqlBairro).isNull();
      check(filter.sqlMunicipio).isNull();
      check(filter.validationError()).isNull();
    });

    test('sqlBairro and sqlMunicipio trim and collapse empty to null', () {
      final filter = ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
        bairro: '  Centro  ',
        municipio: '   ',
      );
      check(filter.sqlBairro).equals('Centro');
      check(filter.sqlMunicipio).isNull();
    });

    test('validationError when origem is empty', () {
      final filter = ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
        origem: '   ',
      );
      check(filter.validationError()).isNotNull();
    });

    test('validationError when geraFinanceiro is not S or N', () {
      final filter = ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
        geraFinanceiro: 'X',
      );
      check(filter.validationError()).isNotNull();
    });
  });
}
