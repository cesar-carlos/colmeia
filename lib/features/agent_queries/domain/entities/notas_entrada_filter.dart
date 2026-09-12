/// Date filters, branch scope, supplier search, and numbered pagination
/// for entrada notes.
///
/// The default scope remains company `1` / branch `1`, matching the initial
/// report requirement. A caller can now pass the company and branch resolved
/// from the active-store context instead of relying on SQL literals.
///
/// Dates refer to `Compra.DataInclusao`. Without an explicit date range, the
/// filter defaults to the current month through the supplied reference day.
///
/// **Search:** optional [searchTerm] is a case- and accent-insensitive
/// contains match on supplier name, plus a contains match on supplier code
/// and tax id. Blank values are ignored.
class NotasEntradaFilter {
  factory NotasEntradaFilter({
    DateTime? dataLancamentoInicio,
    DateTime? dataLancamentoFim,
    String? searchTerm,
    int codEmpresa = defaultCodEmpresa,
    int codFilial = defaultCodFilial,
    int page = 1,
    int pageSize = defaultPageSize,
    DateTime? referenceDate,
  }) {
    if (dataLancamentoInicio != null || dataLancamentoFim != null) {
      return NotasEntradaFilter._(
        dataLancamentoInicio: dataLancamentoInicio,
        dataLancamentoFim: dataLancamentoFim,
        searchTerm: searchTerm,
        codEmpresa: codEmpresa,
        codFilial: codFilial,
        page: page,
        pageSize: pageSize,
      );
    }

    final reference = referenceDate ?? DateTime.now();
    return NotasEntradaFilter._(
      dataLancamentoInicio: DateTime(reference.year, reference.month),
      dataLancamentoFim: DateTime(
        reference.year,
        reference.month,
        reference.day,
      ),
      searchTerm: searchTerm,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      page: page,
      pageSize: pageSize,
    );
  }

  const NotasEntradaFilter._({
    required this.dataLancamentoInicio,
    required this.dataLancamentoFim,
    required this.codEmpresa,
    required this.codFilial,
    required this.page,
    required this.pageSize,
    this.searchTerm,
  });

  static const int defaultPageSize = 50;
  static const int maxPageSize = 500;
  static const List<int> allowedPageSizes = <int>[10, 20, 50, 100];
  static const int defaultCodEmpresa = 1;
  static const int defaultCodFilial = 1;

  final DateTime? dataLancamentoInicio;
  final DateTime? dataLancamentoFim;
  final String? searchTerm;
  final int codEmpresa;
  final int codFilial;
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

  NotasEntradaFilter copyWith({
    DateTime? dataLancamentoInicio,
    DateTime? dataLancamentoFim,
    String? searchTerm,
    bool clearSearchTerm = false,
    int? codEmpresa,
    int? codFilial,
    int? page,
    int? pageSize,
  }) {
    return NotasEntradaFilter._(
      dataLancamentoInicio: dataLancamentoInicio ?? this.dataLancamentoInicio,
      dataLancamentoFim: dataLancamentoFim ?? this.dataLancamentoFim,
      searchTerm: clearSearchTerm ? null : (searchTerm ?? this.searchTerm),
      codEmpresa: codEmpresa ?? this.codEmpresa,
      codFilial: codFilial ?? this.codFilial,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  static int sanitizePageSize(int raw) {
    if (allowedPageSizes.contains(raw)) {
      return raw;
    }
    return defaultPageSize;
  }

  static int sanitizePage(int raw) => raw < 1 ? 1 : raw;

  String? validationError() {
    if (codEmpresa <= 0) {
      return 'codEmpresa must be greater than zero';
    }
    if (codFilial < 0) {
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

    final start = _calendarDate(dataLancamentoInicio);
    final end = _calendarDate(dataLancamentoFim);
    if (start != null && end != null && end.isBefore(start)) {
      return 'dataLancamentoFim must be on or after dataLancamentoInicio';
    }
    return null;
  }

  static DateTime? _calendarDate(DateTime? value) {
    if (value == null) {
      return null;
    }
    return DateTime(value.year, value.month, value.day);
  }
}
