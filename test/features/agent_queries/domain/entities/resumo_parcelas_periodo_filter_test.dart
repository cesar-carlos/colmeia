import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_filter.dart';
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

    test('typedef filters share validation with periodo filter', () {
      final a = ResumoParcelasAnualFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      );
      final b = ResumoParcelasFormaPagamentoAnualFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      );
      check(a.validationError()).isNull();
      check(b.validationError()).isNull();
    });

    test('diario filter typedef shares validation', () {
      final d = ResumoParcelaFormaPagamentoDiarioFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      );
      check(d.validationError()).isNull();
    });

    test('dia semana filter typedef shares validation', () {
      final f = ResumoParcelasDiaSemanaFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      );
      check(f.validationError()).isNull();
    });
  });
}
