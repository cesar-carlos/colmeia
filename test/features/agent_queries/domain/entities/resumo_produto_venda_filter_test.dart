import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_row_number_ordering.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 3);
  final end = DateTime(2026, 3, 31);

  test('default pageSize is 100', () {
    final filter = ResumoProdutoVendaFilter(
      dataVendaInicio: start,
      dataVendaFim: end,
    );
    check(filter.trimmedOrigem).equals('FrenteLoja');
    check(filter.sortBy).equals(ResumoProdutoVendaSortBy.qtdVendas);
    check(filter.sortDirection).equals(
      ResumoProdutoVendaSortDirection.descending,
    );
    check(filter.rowNumberOrdering).equals(
      ResumoProdutoVendaRowNumberOrdering.ledgerDefault,
    );
    check(filter.pageSize).equals(100);
    check(filter.startRow).equals(1);
    check(filter.endRow).equals(100);
  });

  test('startRow and endRow for page 2', () {
    final filter = ResumoProdutoVendaFilter(
      dataVendaInicio: start,
      dataVendaFim: end,
      page: 2,
      pageSize: 10,
    );
    check(filter.startRow).equals(11);
    check(filter.endRow).equals(20);
  });

  test('validation rejects pageSize above max', () {
    final filter = ResumoProdutoVendaFilter(
      dataVendaInicio: start,
      dataVendaFim: end,
      pageSize: ResumoProdutoVendaFilter.maxPageSize + 1,
    );
    check(filter.validationError()).isNotNull();
  });

  test('validation rejects inverted date range', () {
    final filter = ResumoProdutoVendaFilter(
      dataVendaInicio: end,
      dataVendaFim: start,
    );
    check(filter.validationError()).isNotNull();
  });

  test('validation rejects empty origem', () {
    final filter = ResumoProdutoVendaFilter(
      dataVendaInicio: start,
      dataVendaFim: end,
      origem: '   ',
    );
    check(filter.validationError()).isNotNull();
  });

  test('validation rejects range longer than maxDateRangeDays', () {
    final filter = ResumoProdutoVendaFilter(
      dataVendaInicio: start,
      dataVendaFim: start.add(
        const Duration(days: ResumoProdutoVendaFilter.maxDateRangeDays),
      ),
    );
    check(filter.validationError()).isNotNull();
  });
}
