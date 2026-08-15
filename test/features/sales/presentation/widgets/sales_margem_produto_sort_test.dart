import 'package:checks/checks.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesMargemProdutoSort.sanitizePageSize', () {
    test('keeps allowed sizes and falls back otherwise', () {
      check(SalesMargemProdutoSort.sanitizePageSize(10)).equals(10);
      check(SalesMargemProdutoSort.sanitizePageSize(20)).equals(20);
      check(SalesMargemProdutoSort.sanitizePageSize(50)).equals(50);
      check(SalesMargemProdutoSort.sanitizePageSize(99)).equals(20);
      check(SalesMargemProdutoSort.sanitizePageSize('50')).equals(50);
      check(SalesMargemProdutoSort.sanitizePageSize(null)).equals(20);
    });
  });

  group('SalesMargemProdutoSort.restore', () {
    test('restores page size and search term', () {
      final restored = SalesMargemProdutoSort.restore(<String, Object?>{
        'sortBy': 'custoReposicao',
        'sortDirection': 'descending',
        'pageSize': 50,
        'searchTerm': '  Mel  ',
        'codEmpresa': 2,
        'codFilial': 0,
      });

      check(restored.pageSize).equals(50);
      check(restored.searchTerm).equals('Mel');
    });

    test('sanitizes invalid page size', () {
      final restored = SalesMargemProdutoSort.restore(<String, Object?>{
        'pageSize': 500,
      });

      check(restored.pageSize).equals(20);
    });

    test('drops blank search terms', () {
      final restored = SalesMargemProdutoSort.restore(<String, Object?>{
        'searchTerm': '  ',
      });

      check(restored.searchTerm).isNull();
    });
  });

  group('SalesMargemProdutoSort.persistMap', () {
    test('does not persist sort keys', () {
      final persisted = SalesMargemProdutoSort.persistMap(
        pageSize: 10,
        searchTerm: '  Mel  ',
      );

      check(persisted.containsKey('sortBy')).isFalse();
      check(persisted.containsKey('sortDirection')).isFalse();
      check(persisted.containsKey('codEmpresa')).isFalse();
      check(persisted.containsKey('codFilial')).isFalse();
      check(persisted['pageSize']).equals(10);
      check(persisted['searchTerm']).equals('Mel');
    });
  });

  group('SalesMargemProdutoSort.queryFor', () {
    test('builds a page query without sorts', () {
      final query = SalesMargemProdutoSort.queryFor(page: 2, pageSize: 10);

      check(query.page).equals(2);
      check(query.pageSize).equals(10);
      check(query.sorts).isEmpty();
    });

    test('keeps pageSize 50 when replacing a previous page-16 query', () {
      final query = SalesMargemProdutoSort.queryFor(
        page: 1,
        pageSize: 50,
        previous: SalesMargemProdutoSort.queryFor(page: 16, pageSize: 20),
      );

      check(query.page).equals(1);
      check(query.pageSize).equals(50);
      check(query.sorts).isEmpty();
    });

    test('keeps previous searchTerm when paging', () {
      final query = SalesMargemProdutoSort.queryFor(
        page: 2,
        pageSize: 20,
        previous: SalesMargemProdutoSort.queryFor(
          page: 1,
          pageSize: 20,
          searchTerm: 'Mel',
        ),
      );

      check(query.page).equals(2);
      check(query.searchTerm).equals('Mel');
    });

    test('clears searchTerm when requested', () {
      final query = SalesMargemProdutoSort.queryFor(
        page: 1,
        pageSize: 20,
        clearSearchTerm: true,
        previous: SalesMargemProdutoSort.queryFor(
          page: 2,
          pageSize: 20,
          searchTerm: 'Mel',
        ),
      );

      check(query.searchTerm).isNull();
      check(query.page).equals(1);
    });
  });

  group('SalesMargemProdutoSort.searchDebounce', () {
    test('waits after the last keystroke before catalog SQL', () {
      check(
        SalesMargemProdutoSort.searchDebounce,
      ).equals(const Duration(milliseconds: 400));
    });
  });

  group('SalesMargemProdutoSort.pageInfo', () {
    test('computes total pages from the server totalCount', () {
      final info = SalesMargemProdutoSort.pageInfo(
        page: 2,
        pageSize: 20,
        totalCount: 45,
      );

      check(info.currentPage).equals(2);
      check(info.pageSize).equals(20);
      check(info.totalRows).equals(45);
      check(info.totalPages).equals(3);
    });

    test('returns zero pages when the catalog is empty', () {
      final info = SalesMargemProdutoSort.pageInfo(
        page: 1,
        pageSize: 20,
        totalCount: 0,
      );

      check(info.totalPages).equals(0);
      check(info.totalRows).equals(0);
    });
  });
}
