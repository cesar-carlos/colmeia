import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_classificacao.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_filter_limits.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_metric_mode.dart';

enum ProdutoVendidoTendenciaDeVendaMediaMovelSortBy {
  tendenciaPercentualDesc,
  diferencaDesc,
  nomeProdutoAsc,
}

/// Filters and pagination for the calendar moving-average product sales trend.
///
/// [quantidadeDias] is the length of each calendar window (current vs previous)
/// ending today. Days without sales count as zero in the daily mean.
class ProdutoVendidoTendenciaDeVendaMediaMovelFilter {
  const ProdutoVendidoTendenciaDeVendaMediaMovelFilter({
    required this.quantidadeDias,
    this.origem = 'FrenteLoja',
    this.searchTerm,
    this.classificacao,
    this.codGrupoProduto,
    this.codMarca,
    this.codFilial,
    this.metricMode = SalesTrendMetricMode.quantity,
    this.minVolumeUnits = SalesTrendFilterLimits.defaultMinVolumeUnits,
    this.trendThresholdPercent =
        SalesTrendFilterLimits.defaultTrendThresholdPercent,
    this.sortBy =
        ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.tendenciaPercentualDesc,
    this.page = 1,
    this.pageSize = defaultPageSize,
  });

  static const int defaultPageSize = 20;
  static const int maxPageSize = 500;
  static const int maxQuantidadeDias = 366;

  static const int defaultMinVolumeUnits =
      SalesTrendFilterLimits.defaultMinVolumeUnits;

  static const String errorOrigemMustNotBeEmpty = 'origem must not be empty';
  static const String errorQuantidadeDiasMustBePositive =
      'quantidadeDias must be >= 1';
  static const String errorClassificacaoNotAllowed =
      'classificacao is not allowed';
  static const String errorPageMustBePositive = 'page must be >= 1';
  static const String errorPageSizeMustBePositive = 'pageSize must be >= 1';
  static const Set<String> allowedClassificacoes =
      SalesTrendClassificacao.allowed;

  final int quantidadeDias;
  final String origem;
  final String? searchTerm;
  final String? classificacao;
  final int? codGrupoProduto;
  final int? codMarca;
  final int? codFilial;
  final SalesTrendMetricMode metricMode;
  final int minVolumeUnits;
  final double trendThresholdPercent;
  final ProdutoVendidoTendenciaDeVendaMediaMovelSortBy sortBy;
  final int page;
  final int pageSize;

  String get trimmedOrigem => origem.trim();
  String? get normalizedSearchTerm => _normalizeOptionalText(searchTerm);
  String? get normalizedClassificacao =>
      SalesTrendClassificacao.normalize(classificacao);
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
    final filialError = SalesTrendFilterLimits.validateCodFilial(codFilial);
    if (filialError != null) {
      return filialError;
    }
    final volumeError = SalesTrendFilterLimits.validateMinVolumeUnits(
      minVolumeUnits,
    );
    if (volumeError != null) {
      return volumeError;
    }
    final thresholdError = SalesTrendFilterLimits.validateTrendThresholdPercent(
      trendThresholdPercent,
    );
    if (thresholdError != null) {
      return thresholdError;
    }
    if (classificacao != null &&
        classificacao!.trim().isNotEmpty &&
        normalizedClassificacao == null) {
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
