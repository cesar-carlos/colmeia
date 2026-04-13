import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_periodo_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasPeriodoFilter', () {
    test('validationError when dataVendaFim is before dataVendaInicio', () {
      final filter = ResumoParcelasPeriodoFilter(
        dataVendaInicio: DateTime.utc(2026, 4, 30),
        dataVendaFim: DateTime.utc(2026, 4),
      );
      check(filter.validationError()).isNotNull();
    });

    test('validationError when geraFinanceiro is invalid', () {
      final filter = ResumoParcelasPeriodoFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
        geraFinanceiro: 'X',
      );
      check(filter.validationError()).isNotNull();
    });

    test('validationError is null for default flags and valid range', () {
      final filter = ResumoParcelasPeriodoFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      );
      check(filter.validationError()).isNull();
    });

    test('anual and forma pagamento por mes filters delegate period', () {
      final a = ResumoParcelasAnualFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      );
      final b = ResumoParcelasFormaPagamentoPorMesFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      );
      check(a.validationError()).isNull();
      check(b.validationError()).isNull();
    });

    test('anual filter rejects non-positive codEmpresa', () {
      final filter = ResumoParcelasAnualFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
        codEmpresa: 0,
      );
      check(filter.validationError()).isNotNull();
    });

    test('anual filter rejects codFilial without codEmpresa', () {
      final filter = ResumoParcelasAnualFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
        codFilial: 1,
      );
      check(filter.validationError()).isNotNull();
    });

    test('anual filter accepts empresa, filial, vendedor', () {
      final filter = ResumoParcelasAnualFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
        codEmpresa: 1,
        codFilial: 2,
        codVendedor: 3,
      );
      check(filter.validationError()).isNull();
    });

    test('por mes filter rejects non-positive codEmpresa', () {
      final filter = ResumoParcelasFormaPagamentoPorMesFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
        codEmpresa: 0,
      );
      check(filter.validationError()).isNotNull();
    });

    test('por mes filter rejects codFilial without codEmpresa', () {
      final filter = ResumoParcelasFormaPagamentoPorMesFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
        codFilial: 1,
      );
      check(filter.validationError()).isNotNull();
    });

    test('por mes filter accepts empresa, filial, vendedor', () {
      final filter = ResumoParcelasFormaPagamentoPorMesFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
        codEmpresa: 1,
        codFilial: 2,
        codVendedor: 3,
      );
      check(filter.validationError()).isNull();
    });

    test('diario filter typedef shares validation', () {
      final d = ResumoParcelaFormaPagamentoDiarioFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      );
      check(d.validationError()).isNull();
    });

    test('dia semana filter class shares period validation', () {
      final f = ResumoParcelasDiaSemanaFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      );
      check(f.validationError()).isNull();
    });

    test('dia semana filter rejects non-positive codEmpresa', () {
      final filter = ResumoParcelasDiaSemanaFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
        codEmpresa: 0,
      );
      check(filter.validationError()).isNotNull();
    });

    test('dia semana filter rejects codFilial without codEmpresa', () {
      final filter = ResumoParcelasDiaSemanaFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
        codFilial: 1,
      );
      check(filter.validationError()).isNotNull();
    });

    test('dia semana filter accepts empresa, filial, vendedor', () {
      final filter = ResumoParcelasDiaSemanaFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
        codEmpresa: 1,
        codFilial: 2,
        codVendedor: 3,
      );
      check(filter.validationError()).isNull();
    });

    test('mensal filter shares period validation', () {
      final m = ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      );
      check(m.validationError()).isNull();
    });

    test('mensal filter rejects non-positive codEmpresa', () {
      final filter = ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
        codEmpresa: 0,
      );
      check(filter.validationError()).isNotNull();
    });

    test('mensal filter rejects codFilial without codEmpresa', () {
      final filter = ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
        codFilial: 1,
      );
      check(filter.validationError()).isNotNull();
    });

    test('mensal filter accepts empresa, filial, vendedor', () {
      final filter = ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
        codEmpresa: 1,
        codFilial: 2,
        codVendedor: 3,
      );
      check(filter.validationError()).isNull();
    });
  });
}
