import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_direction.dart';

/// Filters and pagination for the product-margin catalog `sql.execute` query.
///
/// **Branch scope:** company and branch are fixed at [fixedCodEmpresa] and
/// [fixedCodFilial]. Replacement cost lives per company/branch in
/// `CustoProduto`; this catalog always reads that one pair.
///
/// **Ordering:** [sortBy] / [sortDirection] drive `ROW_NUMBER`. Default is
/// `NomeProduto ASC`, then `CodProduto ASC` as the stable page key.
///
/// **Search:** optional [searchTerm] is a case- and accent-insensitive
/// contains match on product name, group name, or brand name, and a
/// contains match on `CAST(CodProduto)`. Blank values are ignored.
class MargemProdutoFilter {
  const MargemProdutoFilter({
    this.searchTerm,
    this.page = 1,
    this.pageSize = defaultPageSize,
    this.sortBy = MargemProdutoSortBy.nomeProduto,
    this.sortDirection = MargemProdutoSortDirection.ascending,
  });

  static const int defaultPageSize = 20;

  /// Upper bound for page size (agent `max_rows` and payload safety).
  static const int maxPageSize = 500;

  static const int fixedCodEmpresa = 1;
  static const int fixedCodFilial = 1;

  int get codEmpresa => fixedCodEmpresa;
  int get codFilial => fixedCodFilial;

  /// Optional free-text contains match on name, code, group, or brand.
  final String? searchTerm;

  final int page;
  final int pageSize;
  final MargemProdutoSortBy sortBy;
  final MargemProdutoSortDirection sortDirection;

  String? get normalizedSearchTerm {
    final normalized = searchTerm?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  int get offset => (page - 1) * pageSize;

  /// Inclusive 1-based row index for `ROW_NUMBER()` paging (`offset + 1`).
  int get startRow => offset + 1;

  /// Inclusive end row index for `ROW_NUMBER()` paging (`offset + pageSize`).
  int get endRow => offset + pageSize;

  String? validationError() {
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
