/// Filters and pagination for the municipio catalog `sql.execute` query.
class MunicipioListFilter {
  const MunicipioListFilter({
    this.searchTerm,
    this.uf,
    this.page = 1,
    this.pageSize = defaultPageSize,
  });

  static const int defaultPageSize = 20;

  /// Upper bound for page size (safety on agent `max_rows` and payload).
  static const int maxPageSize = 100;

  final String? searchTerm;

  /// State abbreviation (e.g. `PR`); matched against `Municipio.UF`.
  final String? uf;

  final int page;
  final int pageSize;

  int get offset => (page - 1) * pageSize;

  /// Inclusive 1-based row index for `ROW_NUMBER()` paging (`offset + 1`).
  int get startRow => offset + 1;

  /// Inclusive end row index for `ROW_NUMBER()` paging (`offset + pageSize`).
  int get endRow => offset + pageSize;

  /// Trims [uf]; empty after trim is treated as unset (`null` in SQL params).
  String? get sqlUfParam {
    final raw = uf;
    if (raw == null) {
      return null;
    }
    final t = raw.trim();
    return t.isEmpty ? null : t;
  }

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
