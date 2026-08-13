import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_fullscreen.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveSalesMargemProdutoGridHeight', () {
    test('uses remaining height when the viewport is tall enough', () {
      expect(
        resolveSalesMargemProdutoGridHeight(
          maxHeight: 800,
          chromeHeight: kSalesMargemProdutoFullscreenChromeHeight,
        ),
        800 - kSalesMargemProdutoFullscreenChromeHeight,
      );
    });

    test('caps the page grid at the configured maximum', () {
      expect(
        resolveSalesMargemProdutoGridHeight(
          maxHeight: 1200,
          chromeHeight: kSalesMargemProdutoPageChromeHeight,
          maxGridHeight: kSalesMargemProdutoPageGridMaxHeight,
        ),
        kSalesMargemProdutoPageGridMaxHeight,
      );
    });

    test('shrinks below the preferred minimum on short viewports', () {
      expect(
        resolveSalesMargemProdutoGridHeight(
          maxHeight: 200,
          chromeHeight: kSalesMargemProdutoFullscreenChromeHeight,
        ),
        200 - kSalesMargemProdutoFullscreenChromeHeight,
      );
    });

    test('does not throw when chrome exceeds available height', () {
      expect(
        resolveSalesMargemProdutoGridHeight(
          maxHeight: 100,
          chromeHeight: kSalesMargemProdutoPageChromeHeight,
          maxGridHeight: kSalesMargemProdutoPageGridMaxHeight,
        ),
        0,
      );
    });
  });

  group('SalesMargemProdutoGridSnapshot', () {
    test('treats equivalent grid state as equal for ValueNotifier', () {
      final rows = <MargemProdutoRow>[
        const MargemProdutoRow(
          codEmpresa: 1,
          codFilial: 1,
          nomeFilial: 'Loja',
          codProduto: 1,
          nomeProduto: 'Mel',
          custoReposicao: 4.5,
          precoVendaProduto: 9,
          percentualMarkupCustoCompraProduto: 100,
          margemLucroProduto: 50,
        ),
      ];
      const failure = ValidationFailure(message: 'load_failed');

      SalesMargemProdutoGridSnapshot snapshot() {
        return SalesMargemProdutoGridSnapshot(
          rows: rows,
          pageInfo: SalesMargemProdutoSort.pageInfo(
            page: 2,
            pageSize: 20,
            totalCount: 40,
          ),
          query: SalesMargemProdutoSort.queryFor(
            sortBy: SalesMargemProdutoSort.defaultSortBy,
            sortDirection: SalesMargemProdutoSort.defaultSortDirection,
            page: 2,
            pageSize: 20,
          ),
          isLoading: false,
          loadFailure: failure,
        );
      }

      expect(snapshot(), snapshot());
    });

    test('notifies when the row list instance changes', () {
      final first = SalesMargemProdutoGridSnapshot.initial();
      final otherRows = <MargemProdutoRow>[];
      final second = SalesMargemProdutoGridSnapshot(
        rows: otherRows,
        pageInfo: first.pageInfo,
        query: first.query,
        isLoading: first.isLoading,
      );

      expect(first == second, isFalse);
    });
  });
}
