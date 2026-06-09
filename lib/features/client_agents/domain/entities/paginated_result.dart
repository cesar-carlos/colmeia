class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.count,
    required this.total,
    required this.page,
    required this.pageSize,
    this.isStaleCache = false,
    this.isResultTruncated = false,
  });

  final List<T> items;
  final int count;
  final int total;
  final int page;
  final int pageSize;
  final bool isStaleCache;

  /// True when fewer items were loaded than [total] because of the pagination
  /// safety cap or an inconsistent/short server response.
  final bool isResultTruncated;
}
