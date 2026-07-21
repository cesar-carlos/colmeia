/// Filters for the product sales trend query (`ATUAL` versus `ANTERIOR`).
///
/// Both periods are inclusive calendar windows evaluated in SQL with half-open
/// predicates on `pv.DataVenda` (start inclusive, end exclusive via
/// `DATEADD(day, 1, …)`).
class ProdutoVendidoTendenciaDeVendaFilter {
  const ProdutoVendidoTendenciaDeVendaFilter({
    required this.periodoAtualInicio,
    required this.periodoAtualFim,
    required this.periodoAnteriorInicio,
    required this.periodoAnteriorFim,
    this.origem = 'FrenteLoja',
    this.searchTerm,
    this.classificacao,
    this.codGrupoProduto,
    this.codMarca,
    this.page = 1,
    this.pageSize = defaultPageSize,
  });

  /// Allows up to one full year per period.
  static const int maxDateRangeDays = 366;
  static const int defaultPageSize = 20;
  static const int maxPageSize = 500;
  static const String errorOrigemMustNotBeEmpty = 'origem must not be empty';
  static const String errorPageMustBePositive = 'page must be >= 1';
  static const String errorPageSizeMustBePositive = 'pageSize must be >= 1';
  static const String errorClassificacaoNotAllowed =
      'classificacao is not allowed';
  static const String errorPeriodoAtualFimBeforeInicio =
      'periodoAtualFim must be on or after periodoAtualInicio';
  static const String errorPeriodoAnteriorFimBeforeInicio =
      'periodoAnteriorFim must be on or after periodoAnteriorInicio';
  static const String errorPeriodoAnteriorMustBeBeforeAtual =
      'periodoAnterior must end before periodoAtual starts';
  static const String errorPeriodsMustCoverEquivalentWindows =
      'periodoAtual and periodoAnterior must cover equivalent windows';
  static const Set<String> allowedClassificacoes = <String>{
    'PAROU DE VENDER',
    'NOVO PRODUTO',
    'CRESCENDO',
    'CAINDO',
    'ESTAVEL',
  };

  final DateTime periodoAtualInicio;
  final DateTime periodoAtualFim;
  final DateTime periodoAnteriorInicio;
  final DateTime periodoAnteriorFim;

  /// Bound to `pv.Origem = :origem` (exact match; wildcards rejected by
  /// [validationError]).
  final String origem;
  final String? searchTerm;
  final String? classificacao;
  final int? codGrupoProduto;
  final int? codMarca;
  final int page;
  final int pageSize;

  String get trimmedOrigem => origem.trim();
  String? get normalizedSearchTerm => _normalizeOptionalText(searchTerm);
  String? get normalizedClassificacao =>
      _normalizeOptionalText(classificacao)?.toUpperCase();
  int get offset => (page - 1) * pageSize;
  int get startRow => offset + 1;
  int get endRow => offset + pageSize;

  String? validationError() {
    final origemTrim = trimmedOrigem;
    if (origemTrim.isEmpty) {
      return errorOrigemMustNotBeEmpty;
    }
    if (origemTrim.contains('%') || origemTrim.contains('_')) {
      return 'origem must not contain SQL LIKE wildcards (% or _) '
          'for ProdutoVendido resumo queries (exact match only)';
    }
    if (page < 1) {
      return errorPageMustBePositive;
    }
    if (pageSize < 1) {
      return errorPageSizeMustBePositive;
    }
    if (pageSize > maxPageSize) {
      return 'pageSize must be <= $maxPageSize';
    }
    final grupo = codGrupoProduto;
    if (grupo != null && grupo <= 0) {
      return 'codGrupoProduto must be > 0 when provided';
    }
    final marca = codMarca;
    if (marca != null && marca <= 0) {
      return 'codMarca must be > 0 when provided';
    }
    final categoria = normalizedClassificacao;
    if (categoria != null && !allowedClassificacoes.contains(categoria)) {
      return errorClassificacaoNotAllowed;
    }

    final atualInicio = _toCalendarDate(periodoAtualInicio);
    final atualFim = _toCalendarDate(periodoAtualFim);
    if (atualFim.isBefore(atualInicio)) {
      return errorPeriodoAtualFimBeforeInicio;
    }

    final anteriorInicio = _toCalendarDate(periodoAnteriorInicio);
    final anteriorFim = _toCalendarDate(periodoAnteriorFim);
    if (anteriorFim.isBefore(anteriorInicio)) {
      return errorPeriodoAnteriorFimBeforeInicio;
    }

    final atualInclusiveDays = atualFim.difference(atualInicio).inDays + 1;
    if (atualInclusiveDays > maxDateRangeDays) {
      return 'periodoAtual must be at most $maxDateRangeDays inclusive days';
    }

    final anteriorInclusiveDays =
        anteriorFim.difference(anteriorInicio).inDays + 1;
    if (anteriorInclusiveDays > maxDateRangeDays) {
      return 'periodoAnterior must be at most $maxDateRangeDays inclusive days';
    }

    if (!anteriorFim.isBefore(atualInicio)) {
      return errorPeriodoAnteriorMustBeBeforeAtual;
    }

    if (_periodsOverlap(atualInicio, atualFim, anteriorInicio, anteriorFim)) {
      return 'periodoAtual and periodoAnterior must not overlap';
    }

    if (!_hasEquivalentComparisonWindow(
      atualInicio: atualInicio,
      atualFim: atualFim,
      anteriorInicio: anteriorInicio,
      anteriorFim: anteriorFim,
      atualInclusiveDays: atualInclusiveDays,
      anteriorInclusiveDays: anteriorInclusiveDays,
    )) {
      return errorPeriodsMustCoverEquivalentWindows;
    }

    return null;
  }

  String? _normalizeOptionalText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  DateTime _toCalendarDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _periodsOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return !aEnd.isBefore(bStart) && !bEnd.isBefore(aStart);
  }

  bool _hasEquivalentComparisonWindow({
    required DateTime atualInicio,
    required DateTime atualFim,
    required DateTime anteriorInicio,
    required DateTime anteriorFim,
    required int atualInclusiveDays,
    required int anteriorInclusiveDays,
  }) {
    final atualIsCalendarMonthWindow = _isWholeCalendarMonthWindow(
      atualInicio,
      atualFim,
    );
    final anteriorIsCalendarMonthWindow = _isWholeCalendarMonthWindow(
      anteriorInicio,
      anteriorFim,
    );
    if (atualIsCalendarMonthWindow || anteriorIsCalendarMonthWindow) {
      return atualIsCalendarMonthWindow &&
          anteriorIsCalendarMonthWindow &&
          _calendarMonthSpan(atualInicio, atualFim) ==
              _calendarMonthSpan(anteriorInicio, anteriorFim);
    }

    return atualInclusiveDays == anteriorInclusiveDays;
  }

  bool _isWholeCalendarMonthWindow(DateTime start, DateTime end) {
    final lastDayOfEndMonth = DateTime(end.year, end.month + 1, 0).day;
    return start.day == 1 && end.day == lastDayOfEndMonth;
  }

  int _calendarMonthSpan(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + end.month - start.month + 1;
  }
}
