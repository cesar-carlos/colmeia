class PaginatedQuery {
  const PaginatedQuery({
    this.page = 1,
    this.pageSize = 20,
  });

  final int page;
  final int pageSize;

  PaginatedQuery copyWith({
    int? page,
    int? pageSize,
  }) {
    return PaginatedQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}
