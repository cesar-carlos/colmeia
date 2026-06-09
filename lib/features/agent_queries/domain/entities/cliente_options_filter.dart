/// Filters and pagination for the cliente catalog `sql.execute` query.
class ClienteOptionsFilter {
  const ClienteOptionsFilter({
    this.searchTerm,
    this.page = 1,
    this.pageSize = defaultPageSize,
  });

  static const int defaultPageSize = 20;

  /// Upper bound for page size (safety on agent `max_rows` and payload).
  /// Must stay <= `AgentQueriesBoundedResultMaxRows.clienteOptionsPage`.
  static const int maxPageSize = 500;

  final String? searchTerm;
  final int page;
  final int pageSize;

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
