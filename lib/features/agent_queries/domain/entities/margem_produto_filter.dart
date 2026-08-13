import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';

/// Filters and pagination for the product-margin catalog `sql.execute` query.
///
/// **Branch scope:** [codEmpresa] and [codFilial] are required. Replacement
/// cost is stored per company/branch in `CustoProduto`.
///
/// **Ordenação:** [sortBy] sets the primary `ROW_NUMBER` column;
/// [sortDirection] sets ASC/DESC. `CodProduto ASC` is always the stable
/// tie-breaker.
class MargemProdutoFilter {
  const MargemProdutoFilter({
    required this.codEmpresa,
    required this.codFilial,
    this.sortBy = MargemProdutoSortBy.margemLucroProduto,
    this.sortDirection = ResumoProdutoVendaSortDirection.descending,
    this.page = 1,
    this.pageSize = defaultPageSize,
  });

  static const int defaultPageSize = 20;

  /// Upper bound for page size (agent `max_rows` and payload safety).
  static const int maxPageSize = 500;

  final int codEmpresa;
  final int codFilial;

  /// Primary sort column in `ROW_NUMBER() OVER`.
  final MargemProdutoSortBy sortBy;

  /// ASC or DESC for [sortBy]; `CodProduto ASC` follows as a stable
  /// tie-breaker in the SQL.
  final ResumoProdutoVendaSortDirection sortDirection;

  final int page;
  final int pageSize;

  int get offset => (page - 1) * pageSize;

  /// Inclusive 1-based row index for `ROW_NUMBER()` paging (`offset + 1`).
  int get startRow => offset + 1;

  /// Inclusive end row index for `ROW_NUMBER()` paging (`offset + pageSize`).
  int get endRow => offset + pageSize;

  String? validationError() {
    if (codEmpresa < 1) {
      return 'codEmpresa must be >= 1';
    }
    if (codFilial < 0) {
      return 'codFilial must be >= 0';
    }
    if (page < 1) {
      return 'page must be >= 1';
    }
    if (pageSize < 1) {
      return 'pageSize must be >= 1';
    }
    if (pageSize > maxPageSize) {
      return 'pageSize must be <= $maxPageSize';
    }
    return null;
  }
}
