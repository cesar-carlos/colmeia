/// Subset of `result.pagination` from a paginated `sql.execute` response.
class AgentSqlPaginationResult {
  const AgentSqlPaginationResult({
    this.page,
    this.pageSize,
    this.returnedRows,
    this.hasNextPage,
    this.hasPreviousPage,
    this.currentCursor,
    this.nextCursor,
  });

  final int? page;
  final int? pageSize;
  final int? returnedRows;
  final bool? hasNextPage;
  final bool? hasPreviousPage;
  final String? currentCursor;
  final String? nextCursor;
}
