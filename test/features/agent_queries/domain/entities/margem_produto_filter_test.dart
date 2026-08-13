import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'default pageSize is 20 and sort is margemLucroProduto descending',
    () {
      const filter = MargemProdutoFilter(codEmpresa: 1, codFilial: 1);
      check(filter.sortBy).equals(MargemProdutoSortBy.margemLucroProduto);
      check(
        filter.sortDirection,
      ).equals(ResumoProdutoVendaSortDirection.descending);
      check(filter.pageSize).equals(20);
      check(filter.startRow).equals(1);
      check(filter.endRow).equals(20);
      check(filter.validationError()).isNull();
    },
  );

  test('startRow and endRow for page 2', () {
    const filter = MargemProdutoFilter(
      codEmpresa: 1,
      codFilial: 1,
      page: 2,
      pageSize: 10,
    );
    check(filter.startRow).equals(11);
    check(filter.endRow).equals(20);
  });

  test('validation rejects pageSize above max', () {
    const filter = MargemProdutoFilter(
      codEmpresa: 1,
      codFilial: 1,
      pageSize: MargemProdutoFilter.maxPageSize + 1,
    );
    check(filter.validationError()).equals(
      'pageSize must be <= ${MargemProdutoFilter.maxPageSize}',
    );
  });

  test('validation rejects page below 1', () {
    const filter = MargemProdutoFilter(
      codEmpresa: 1,
      codFilial: 1,
      page: 0,
    );
    check(filter.validationError()).equals('page must be >= 1');
  });

  test('validation rejects pageSize below 1', () {
    const filter = MargemProdutoFilter(
      codEmpresa: 1,
      codFilial: 1,
      pageSize: 0,
    );
    check(filter.validationError()).equals('pageSize must be >= 1');
  });

  test('validation rejects codEmpresa below 1', () {
    const filter = MargemProdutoFilter(codEmpresa: 0, codFilial: 1);
    check(filter.validationError()).equals('codEmpresa must be >= 1');
  });

  test('validation rejects negative codFilial', () {
    const filter = MargemProdutoFilter(codEmpresa: 1, codFilial: -1);
    check(filter.validationError()).equals('codFilial must be >= 0');
  });
}
