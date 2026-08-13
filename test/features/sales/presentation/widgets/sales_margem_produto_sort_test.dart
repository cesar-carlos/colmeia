import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_sort.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesMargemProdutoSort.fromSorts', () {
    test('uses the first whitelisted column and maps direction', () {
      final mapped = SalesMargemProdutoSort.fromSorts(
        const <AppReportSortDescriptor>[
          AppReportSortDescriptor(
            columnKey: SalesMargemProdutoSort.columnMarkup,
            direction: AppReportSortDirection.ascending,
          ),
        ],
      );

      check(mapped.$1).equals(MargemProdutoSortBy.percentualMarkup);
      check(mapped.$2).equals(ResumoProdutoVendaSortDirection.ascending);
    });

    test('skips non-whitelisted keys and falls back to default', () {
      final mapped = SalesMargemProdutoSort.fromSorts(
        const <AppReportSortDescriptor>[
          AppReportSortDescriptor(
            columnKey: SalesMargemProdutoSort.columnProduto,
            direction: AppReportSortDirection.ascending,
          ),
        ],
      );

      check(mapped.$1).equals(MargemProdutoSortBy.margemLucroProduto);
      check(mapped.$2).equals(ResumoProdutoVendaSortDirection.descending);
    });

    test('prefers the first whitelist hit when mixed keys are present', () {
      final mapped = SalesMargemProdutoSort.fromSorts(
        const <AppReportSortDescriptor>[
          AppReportSortDescriptor(
            columnKey: SalesMargemProdutoSort.columnProduto,
            direction: AppReportSortDirection.ascending,
          ),
          AppReportSortDescriptor(
            columnKey: SalesMargemProdutoSort.columnCustoReposicao,
            direction: AppReportSortDirection.descending,
          ),
        ],
      );

      check(mapped.$1).equals(MargemProdutoSortBy.custoReposicao);
      check(mapped.$2).equals(ResumoProdutoVendaSortDirection.descending);
    });
  });

  group('SalesMargemProdutoSort.descriptor round-trip', () {
    test('maps each SQL sort key to the matching column', () {
      for (final sortBy in MargemProdutoSortBy.values) {
        final descriptor = SalesMargemProdutoSort.descriptorFor(
          sortBy: sortBy,
          sortDirection: ResumoProdutoVendaSortDirection.ascending,
        );
        final mapped = SalesMargemProdutoSort.fromSorts(
          <AppReportSortDescriptor>[descriptor],
        );

        check(mapped.$1).equals(sortBy);
        check(mapped.$2).equals(ResumoProdutoVendaSortDirection.ascending);
        check(
          SalesMargemProdutoSort.tryParseColumnKey(descriptor.columnKey),
        ).equals(sortBy);
      }
    });
  });

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
    test('sanitizes persisted filters against the SQL whitelist', () {
      final restored = SalesMargemProdutoSort.restore(<String, Object?>{
        'sortBy': 'nomeProduto',
        'sortDirection': 'sideways',
        'pageSize': 500,
        'codEmpresa': 2,
        'codFilial': 0,
      });

      check(restored.sortBy).equals(MargemProdutoSortBy.margemLucroProduto);
      check(
        restored.sortDirection,
      ).equals(ResumoProdutoVendaSortDirection.descending);
      check(restored.pageSize).equals(20);
      check(restored.codEmpresa).equals(2);
      check(restored.codFilial).equals(0);
    });

    test('accepts a valid persisted sort and page size', () {
      final restored = SalesMargemProdutoSort.restore(<String, Object?>{
        'sortBy': 'custoReposicao',
        'sortDirection': 'ascending',
        'pageSize': 10,
        'codEmpresa': 1,
        'codFilial': 3,
      });

      check(restored.sortBy).equals(MargemProdutoSortBy.custoReposicao);
      check(
        restored.sortDirection,
      ).equals(ResumoProdutoVendaSortDirection.ascending);
      check(restored.pageSize).equals(10);
      check(restored.codEmpresa).equals(1);
      check(restored.codFilial).equals(3);
    });

    test('drops invalid company codes', () {
      final restored = SalesMargemProdutoSort.restore(<String, Object?>{
        'codEmpresa': 0,
        'codFilial': -1,
      });

      check(restored.codEmpresa).isNull();
      check(restored.codFilial).isNull();
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
