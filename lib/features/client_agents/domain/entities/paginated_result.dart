class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.count,
    required this.total,
    required this.page,
    required this.pageSize,
    this.isStaleCache = false,
  });

  final List<T> items;
  final int count;
  final int total;
  final int page;
  final int pageSize;
  final bool isStaleCache;
}
