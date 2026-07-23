import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_filter_limits.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_metric_mode.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/foundation.dart';

@immutable
class SalesProdutoTendenciaMediaMovelPresentationState {
  const SalesProdutoTendenciaMediaMovelPresentationState({
    required this.quantidadeDias,
    this.selectedAgentId,
    this.availableAgents = const <DashboardAgentOption>[],
    this.grupoProdutoLabel,
    this.marcaProdutoLabel,
    this.filialLabel,
    this.searchTerm = '',
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
    this.pageSize =
        ProdutoVendidoTendenciaDeVendaMediaMovelFilter.defaultPageSize,
    this.loading = false,
    this.detailsLoading = false,
    this.authenticationFailed = false,
    this.loadFailure,
    this.pageResult = const ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
      items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
      totalCount: 0,
    ),
    this.summaryRows =
        const <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[],
  });

  final String? selectedAgentId;
  final List<DashboardAgentOption> availableAgents;
  final String? grupoProdutoLabel;
  final String? marcaProdutoLabel;
  final String? filialLabel;
  final int quantidadeDias;
  final String searchTerm;
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
  final bool loading;
  final bool detailsLoading;
  final bool authenticationFailed;
  final AppFailure? loadFailure;
  final ProdutoVendidoTendenciaDeVendaMediaMovelPageResult pageResult;
  final List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow> summaryRows;

  bool get hasPlainError => authenticationFailed;

  SalesProdutoTendenciaMediaMovelPresentationState copyWith({
    String? selectedAgentId,
    List<DashboardAgentOption>? availableAgents,
    Object? grupoProdutoLabel = _sentinel,
    Object? marcaProdutoLabel = _sentinel,
    Object? filialLabel = _sentinel,
    int? quantidadeDias,
    String? searchTerm,
    Object? classificacao = _sentinel,
    Object? codGrupoProduto = _sentinel,
    Object? codMarca = _sentinel,
    Object? codFilial = _sentinel,
    SalesTrendMetricMode? metricMode,
    int? minVolumeUnits,
    double? trendThresholdPercent,
    ProdutoVendidoTendenciaDeVendaMediaMovelSortBy? sortBy,
    int? page,
    int? pageSize,
    bool? loading,
    bool? detailsLoading,
    bool? authenticationFailed,
    Object? loadFailure = _sentinel,
    ProdutoVendidoTendenciaDeVendaMediaMovelPageResult? pageResult,
    List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>? summaryRows,
  }) {
    return SalesProdutoTendenciaMediaMovelPresentationState(
      selectedAgentId: selectedAgentId ?? this.selectedAgentId,
      availableAgents: availableAgents ?? this.availableAgents,
      grupoProdutoLabel: identical(grupoProdutoLabel, _sentinel)
          ? this.grupoProdutoLabel
          : grupoProdutoLabel as String?,
      marcaProdutoLabel: identical(marcaProdutoLabel, _sentinel)
          ? this.marcaProdutoLabel
          : marcaProdutoLabel as String?,
      filialLabel: identical(filialLabel, _sentinel)
          ? this.filialLabel
          : filialLabel as String?,
      quantidadeDias: quantidadeDias ?? this.quantidadeDias,
      searchTerm: searchTerm ?? this.searchTerm,
      classificacao: identical(classificacao, _sentinel)
          ? this.classificacao
          : classificacao as String?,
      codGrupoProduto: identical(codGrupoProduto, _sentinel)
          ? this.codGrupoProduto
          : codGrupoProduto as int?,
      codMarca: identical(codMarca, _sentinel)
          ? this.codMarca
          : codMarca as int?,
      codFilial: identical(codFilial, _sentinel)
          ? this.codFilial
          : codFilial as int?,
      metricMode: metricMode ?? this.metricMode,
      minVolumeUnits: minVolumeUnits ?? this.minVolumeUnits,
      trendThresholdPercent:
          trendThresholdPercent ?? this.trendThresholdPercent,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      loading: loading ?? this.loading,
      detailsLoading: detailsLoading ?? this.detailsLoading,
      authenticationFailed: authenticationFailed ?? this.authenticationFailed,
      loadFailure: identical(loadFailure, _sentinel)
          ? this.loadFailure
          : loadFailure as AppFailure?,
      pageResult: pageResult ?? this.pageResult,
      summaryRows: summaryRows ?? this.summaryRows,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SalesProdutoTendenciaMediaMovelPresentationState &&
        other.selectedAgentId == selectedAgentId &&
        listEquals(other.availableAgents, availableAgents) &&
        other.grupoProdutoLabel == grupoProdutoLabel &&
        other.marcaProdutoLabel == marcaProdutoLabel &&
        other.filialLabel == filialLabel &&
        other.quantidadeDias == quantidadeDias &&
        other.searchTerm == searchTerm &&
        other.classificacao == classificacao &&
        other.codGrupoProduto == codGrupoProduto &&
        other.codMarca == codMarca &&
        other.codFilial == codFilial &&
        other.metricMode == metricMode &&
        other.minVolumeUnits == minVolumeUnits &&
        other.trendThresholdPercent == trendThresholdPercent &&
        other.sortBy == sortBy &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.loading == loading &&
        other.detailsLoading == detailsLoading &&
        other.authenticationFailed == authenticationFailed &&
        other.loadFailure == loadFailure &&
        other.pageResult == pageResult &&
        listEquals(other.summaryRows, summaryRows);
  }

  @override
  int get hashCode => Object.hash(
    selectedAgentId,
    Object.hashAll(availableAgents),
    grupoProdutoLabel,
    marcaProdutoLabel,
    filialLabel,
    quantidadeDias,
    searchTerm,
    classificacao,
    codGrupoProduto,
    Object.hash(
      codMarca,
      codFilial,
      metricMode,
      minVolumeUnits,
      trendThresholdPercent,
      sortBy,
      page,
      pageSize,
      loading,
      detailsLoading,
      authenticationFailed,
      loadFailure,
    ),
    pageResult,
    Object.hashAll(summaryRows),
  );
}

const Object _sentinel = Object();
