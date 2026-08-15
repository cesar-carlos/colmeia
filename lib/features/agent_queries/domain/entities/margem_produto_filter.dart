/// Filters and pagination for the product-margin catalog `sql.execute` query.
///
/// **Branch scope:** company and branch are fixed at [fixedCodEmpresa] and
/// [fixedCodFilial]. Replacement cost lives per company/branch in
/// `CustoProduto`; this catalog always reads that one pair.
///
/// **Ordering:** the SQL always numbers rows by `NomeProduto ASC`, then
/// `CodProduto ASC`. That fixed key keeps page windows stable.
///
/// **Search:** optional [searchTerm] is a case- and accent-insensitive
/// contains match on `Produto.Nome`. Blank values are ignored.
class MargemProdutoFilter {
  const MargemProdutoFilter({
    this.searchTerm,
    this.page = 1,
    this.pageSize = defaultPageSize,
  });

  static const int defaultPageSize = 20;

  /// Upper bound for page size (agent `max_rows` and payload safety).
  static const int maxPageSize = 500;

  static const int fixedCodEmpresa = 1;
  static const int fixedCodFilial = 1;

  int get codEmpresa => fixedCodEmpresa;
  int get codFilial => fixedCodFilial;

  /// Optional free-text contains match on product name.
  final String? searchTerm;

  final int page;
  final int pageSize;

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
