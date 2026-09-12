import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to the current-month range and initial branch scope', () {
    final filter = NotasEntradaFilter(
      referenceDate: DateTime(2026, 9, 12, 18),
    );

    check(filter.dataLancamentoInicio).equals(DateTime(2026, 9));
    check(filter.dataLancamentoFim).equals(DateTime(2026, 9, 12));
    check(filter.codEmpresa).equals(NotasEntradaFilter.defaultCodEmpresa);
    check(filter.codFilial).equals(NotasEntradaFilter.defaultCodFilial);
    check(filter.page).equals(1);
    check(filter.pageSize).equals(NotasEntradaFilter.defaultPageSize);
    check(filter.normalizedSearchTerm).isNull();
    check(filter.startRow).equals(1);
    check(filter.endRow).equals(NotasEntradaFilter.defaultPageSize);
    check(filter.validationError()).isNull();
  });

  test('keeps a caller-provided one-sided launch-date filter', () {
    final filter = NotasEntradaFilter(
      dataLancamentoInicio: DateTime(2026, 1, 1, 15),
    );

    check(filter.dataLancamentoInicio).equals(DateTime(2026, 1, 1, 15));
    check(filter.dataLancamentoFim).isNull();
    check(filter.validationError()).isNull();
  });

  test('accepts an explicit branch scope for the future active store', () {
    final filter = NotasEntradaFilter(
      codEmpresa: 2,
      codFilial: 17,
    );

    check(filter.codEmpresa).equals(2);
    check(filter.codFilial).equals(17);
  });

  test('rejects a launch-date end before the start calendar day', () {
    final filter = NotasEntradaFilter(
      dataLancamentoInicio: DateTime(2026, 2, 2, 23),
      dataLancamentoFim: DateTime(2026, 2, 1, 1),
    );

    check(filter.validationError()).equals(
      'dataLancamentoFim must be on or after dataLancamentoInicio',
    );
  });

  test('rejects an invalid branch scope and page size', () {
    final invalidBranch = NotasEntradaFilter(codEmpresa: 0);
    final oversized = NotasEntradaFilter(
      pageSize: NotasEntradaFilter.maxPageSize + 1,
    );

    check(invalidBranch.validationError()).equals(
      'codEmpresa must be greater than zero',
    );
    check(oversized.validationError()).equals(
      'pageSize must be <= ${NotasEntradaFilter.maxPageSize}',
    );
  });

  test('maps numbered pages onto inclusive ROW_NUMBER bounds', () {
    final filter = NotasEntradaFilter(
      dataLancamentoInicio: DateTime(2026, 8),
      dataLancamentoFim: DateTime(2026, 8, 31),
      page: 2,
      pageSize: 25,
    );

    check(filter.startRow).equals(26);
    check(filter.endRow).equals(50);

    final next = filter.copyWith(page: 3);
    check(next.page).equals(3);
    check(next.pageSize).equals(25);
    check(next.startRow).equals(51);
    check(next.dataLancamentoInicio).equals(filter.dataLancamentoInicio);
  });

  test('sanitizes page size to the allowed catalog options', () {
    check(NotasEntradaFilter.sanitizePageSize(50)).equals(50);
    check(NotasEntradaFilter.sanitizePageSize(12)).equals(
      NotasEntradaFilter.defaultPageSize,
    );
    check(NotasEntradaFilter.sanitizePage(0)).equals(1);
  });

  test('normalizes supplier search and can clear it on copy', () {
    final filter = NotasEntradaFilter(
      searchTerm: '  Casa do Mel  ',
      dataLancamentoInicio: DateTime(2026, 8),
      dataLancamentoFim: DateTime(2026, 8, 31),
    );

    check(filter.normalizedSearchTerm).equals('Casa do Mel');

    final cleared = filter.copyWith(clearSearchTerm: true);
    check(cleared.normalizedSearchTerm).isNull();
    check(cleared.dataLancamentoInicio).equals(filter.dataLancamentoInicio);

    final next = filter.copyWith(searchTerm: 'Apiário');
    check(next.normalizedSearchTerm).equals('Apiário');
  });
}
