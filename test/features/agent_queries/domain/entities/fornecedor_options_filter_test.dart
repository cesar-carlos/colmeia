import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/fornecedor_options_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FornecedorOptionsFilter', () {
    test('defaults page and pageSize', () {
      const filter = FornecedorOptionsFilter();
      check(filter.page).equals(1);
      check(filter.pageSize).equals(FornecedorOptionsFilter.defaultPageSize);
      check(filter.startRow).equals(1);
      check(filter.endRow).equals(20);
    });

    test('computes startRow and endRow for custom page', () {
      const filter = FornecedorOptionsFilter(page: 3, pageSize: 10);
      check(filter.startRow).equals(21);
      check(filter.endRow).equals(30);
    });

    test('validationError rejects invalid page', () {
      check(
        const FornecedorOptionsFilter(page: 0).validationError(),
      ).equals('page must be >= 1');
    });

    test('validationError rejects pageSize above max', () {
      check(
        const FornecedorOptionsFilter(
          pageSize: FornecedorOptionsFilter.maxPageSize + 1,
        ).validationError(),
      ).equals('pageSize must be <= ${FornecedorOptionsFilter.maxPageSize}');
    });

    test('validationError returns null for valid filter', () {
      check(const FornecedorOptionsFilter().validationError()).isNull();
    });
  });
}
