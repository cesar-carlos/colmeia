/// Filters for the product sales trend query (`ATUAL` versus `ANTERIOR`).
///
/// Both periods are inclusive and evaluated in SQL with:
/// `BETWEEN :periodoAtualInicio AND :periodoAtualFim` and
/// `BETWEEN :periodoAnteriorInicio AND :periodoAnteriorFim`.
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

  /// Bound to `pv.Origem LIKE :origem`.
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
    if (trimmedOrigem.isEmpty) {
      return 'origem must not be empty';
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
      return 'classificacao is not allowed';
    }

    final atualInicio = _toCalendarDate(periodoAtualInicio);
    final atualFim = _toCalendarDate(periodoAtualFim);
    if (atualFim.isBefore(atualInicio)) {
      return 'periodoAtualFim must be on or after periodoAtualInicio';
    }

    final anteriorInicio = _toCalendarDate(periodoAnteriorInicio);
    final anteriorFim = _toCalendarDate(periodoAnteriorFim);
    if (anteriorFim.isBefore(anteriorInicio)) {
      return 'periodoAnteriorFim must be on or after periodoAnteriorInicio';
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

    if (_periodsOverlap(atualInicio, atualFim, anteriorInicio, anteriorFim)) {
      return 'periodoAtual and periodoAnterior must not overlap';
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
}
