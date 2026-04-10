import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasAnualFilter', () {
    test('validationError when dataVendaFim is before dataVendaInicio', () {
      final filter = ResumoParcelasAnualFilter(
        dataVendaInicio: DateTime.utc(2026, 4, 30),
        dataVendaFim: DateTime.utc(2026, 4),
      );
      check(filter.validationError()).isNotNull();
    });

    test('validationError when geraFinanceiro is invalid', () {
      final filter = ResumoParcelasAnualFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
        geraFinanceiro: 'X',
      );
      check(filter.validationError()).isNotNull();
    });

    test('validationError is null for default flags and valid range', () {
      final filter = ResumoParcelasAnualFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      );
      check(filter.validationError()).isNull();
    });
  });
}
