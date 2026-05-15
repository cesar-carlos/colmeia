/// Filters and pagination for the branch registration catalog query.
class CadastroFilialFilter {
  const CadastroFilialFilter({
    this.codEmpresa,
    this.codFilial,
    this.page = 1,
    this.pageSize = defaultPageSize,
  });

  static const int defaultPageSize = 20;

  /// Upper bound for page size (safety on agent `max_rows` and payload).
  static const int maxPageSize = 100;

  final int? codEmpresa;
  final int? codFilial;
  final int page;
  final int pageSize;

  CadastroFilialFilter copyWith({
    int? codEmpresa,
    int? codFilial,
    int? page,
    int? pageSize,
  }) {
    return CadastroFilialFilter(
      codEmpresa: codEmpresa ?? this.codEmpresa,
      codFilial: codFilial ?? this.codFilial,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  int get offset => (page - 1) * pageSize;

  /// Inclusive 1-based row index for `ROW_NUMBER()` paging (`offset + 1`).
  int get startRow => offset + 1;

  /// Inclusive end row index for `ROW_NUMBER()` paging (`offset + pageSize`).
  int get endRow => offset + pageSize;

  String? validationError() {
    final empresa = codEmpresa;
    if (empresa != null && empresa <= 0) {
      return 'codEmpresa must be greater than zero';
    }
    final filial = codFilial;
    if (filial != null && filial < 0) {
      return 'codFilial must be greater than or equal to zero';
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
