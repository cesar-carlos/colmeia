enum ProdutoVendidoTendenciaDeVendaMediaMovelSortBy {
  tendenciaPercentualDesc,
  diferencaDesc,
  nomeProdutoAsc,
}

/// Filters and pagination for the moving-average product sales trend query.
class ProdutoVendidoTendenciaDeVendaMediaMovelFilter {
  const ProdutoVendidoTendenciaDeVendaMediaMovelFilter({
    required this.quantidadeDias,
    this.origem = 'FrenteLoja',
    this.searchTerm,
    this.classificacao,
    this.codGrupoProduto,
    this.codMarca,
    this.sortBy =
        ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.tendenciaPercentualDesc,
    this.page = 1,
    this.pageSize = defaultPageSize,
  });

  static const int defaultPageSize = 20;
  static const int maxPageSize = 500;
  static const int maxQuantidadeDias = 366;
  static const String errorOrigemMustNotBeEmpty = 'origem must not be empty';
  static const String errorQuantidadeDiasMustBePositive =
      'quantidadeDias must be >= 1';
  static const String errorClassificacaoNotAllowed =
      'classificacao is not allowed';
  static const String errorPageMustBePositive = 'page must be >= 1';
  static const String errorPageSizeMustBePositive = 'pageSize must be >= 1';
  static const Set<String> allowedClassificacoes = <String>{
    'NOVO',
    'PAROU',
    'CRESCENDO',
    'CAINDO',
    'ESTAVEL',
  };

  final int quantidadeDias;
  final String origem;
  final String? searchTerm;
  final String? classificacao;
  final int? codGrupoProduto;
  final int? codMarca;
  final ProdutoVendidoTendenciaDeVendaMediaMovelSortBy sortBy;
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
    if (quantidadeDias < 1) {
      return errorQuantidadeDiasMustBePositive;
    }
    if (quantidadeDias > maxQuantidadeDias) {
      return 'quantidadeDias must be <= $maxQuantidadeDias';
    }
    if (trimmedOrigem.isEmpty) {
      return errorOrigemMustNotBeEmpty;
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
    return null;
  }

  String? _normalizeOptionalText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
