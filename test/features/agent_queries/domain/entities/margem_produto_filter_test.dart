import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to company 1, branch 1, pageSize 20', () {
    const filter = MargemProdutoFilter();
    check(filter.codEmpresa).equals(MargemProdutoFilter.fixedCodEmpresa);
    check(filter.codFilial).equals(MargemProdutoFilter.fixedCodFilial);
    check(filter.pageSize).equals(20);
    check(filter.startRow).equals(1);
    check(filter.endRow).equals(20);
    check(filter.validationError()).isNull();
  });

  test('startRow and endRow for page 2', () {
    const filter = MargemProdutoFilter(
      page: 2,
      pageSize: 10,
    );
    check(filter.startRow).equals(11);
    check(filter.endRow).equals(20);
  });

  test('validation rejects pageSize above max', () {
    const filter = MargemProdutoFilter(
      pageSize: MargemProdutoFilter.maxPageSize + 1,
    );
    check(filter.validationError()).equals(
      'pageSize must be <= ${MargemProdutoFilter.maxPageSize}',
    );
  });

  test('validation rejects page below 1', () {
    const filter = MargemProdutoFilter(page: 0);
    check(filter.validationError()).equals('page must be >= 1');
  });

  test('validation rejects pageSize below 1', () {
    const filter = MargemProdutoFilter(pageSize: 0);
    check(filter.validationError()).equals('pageSize must be >= 1');
  });

  test('normalizedSearchTerm trims and treats blank as null', () {
    const blank = MargemProdutoFilter(searchTerm: '  ');
    const padded = MargemProdutoFilter(searchTerm: '  Mel  ');
    check(blank.normalizedSearchTerm).isNull();
    check(padded.normalizedSearchTerm).equals('Mel');
    check(padded.validationError()).isNull();
  });
}
