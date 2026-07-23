import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class SalesProdutoTendenciaPresentationState {
  const SalesProdutoTendenciaPresentationState({
    required this.periodoAtual,
    required this.periodoAnterior,
    this.selectedAgentId,
    this.availableAgents = const <DashboardAgentOption>[],
    this.grupoProdutoLabel,
    this.marcaProdutoLabel,
    this.searchTerm = '',
    this.classificacao,
    this.codGrupoProduto,
    this.codMarca,
    this.page = 1,
    this.pageSize = ProdutoVendidoTendenciaDeVendaFilter.defaultPageSize,
    this.loading = false,
    this.detailsLoading = false,
    this.authenticationFailed = false,
    this.loadFailure,
    this.rows = const <ProdutoVendidoTendenciaDeVendaRow>[],
    this.totalCount = 0,
    this.summaryRows = const <ProdutoVendidoTendenciaDeVendaSummaryRow>[],
    this.topGainers = const <ProdutoVendidoTendenciaDeVendaRow>[],
    this.topLosers = const <ProdutoVendidoTendenciaDeVendaRow>[],
  });

  final String? selectedAgentId;
  final List<DashboardAgentOption> availableAgents;
  final String? grupoProdutoLabel;
  final String? marcaProdutoLabel;
  final DateTimeRange periodoAtual;
  final DateTimeRange periodoAnterior;
  final String searchTerm;
  final String? classificacao;
  final int? codGrupoProduto;
  final int? codMarca;
  final int page;
  final int pageSize;
  final bool loading;
  final bool detailsLoading;
  final bool authenticationFailed;
  final AppFailure? loadFailure;
  final List<ProdutoVendidoTendenciaDeVendaRow> rows;
  final int totalCount;
  final List<ProdutoVendidoTendenciaDeVendaSummaryRow> summaryRows;
  final List<ProdutoVendidoTendenciaDeVendaRow> topGainers;
  final List<ProdutoVendidoTendenciaDeVendaRow> topLosers;

  bool get hasPlainError => authenticationFailed;

  SalesProdutoTendenciaPresentationState copyWith({
    String? selectedAgentId,
    List<DashboardAgentOption>? availableAgents,
    Object? grupoProdutoLabel = _sentinel,
    Object? marcaProdutoLabel = _sentinel,
    DateTimeRange? periodoAtual,
    DateTimeRange? periodoAnterior,
    String? searchTerm,
    Object? classificacao = _sentinel,
    Object? codGrupoProduto = _sentinel,
    Object? codMarca = _sentinel,
    int? page,
    int? pageSize,
    bool? loading,
    bool? detailsLoading,
    bool? authenticationFailed,
    Object? loadFailure = _sentinel,
    List<ProdutoVendidoTendenciaDeVendaRow>? rows,
    int? totalCount,
    List<ProdutoVendidoTendenciaDeVendaSummaryRow>? summaryRows,
    List<ProdutoVendidoTendenciaDeVendaRow>? topGainers,
    List<ProdutoVendidoTendenciaDeVendaRow>? topLosers,
  }) {
    return SalesProdutoTendenciaPresentationState(
      selectedAgentId: selectedAgentId ?? this.selectedAgentId,
      availableAgents: availableAgents ?? this.availableAgents,
      grupoProdutoLabel: identical(grupoProdutoLabel, _sentinel)
          ? this.grupoProdutoLabel
          : grupoProdutoLabel as String?,
      marcaProdutoLabel: identical(marcaProdutoLabel, _sentinel)
          ? this.marcaProdutoLabel
          : marcaProdutoLabel as String?,
      periodoAtual: periodoAtual ?? this.periodoAtual,
      periodoAnterior: periodoAnterior ?? this.periodoAnterior,
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
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      loading: loading ?? this.loading,
      detailsLoading: detailsLoading ?? this.detailsLoading,
      authenticationFailed: authenticationFailed ?? this.authenticationFailed,
      loadFailure: identical(loadFailure, _sentinel)
          ? this.loadFailure
          : loadFailure as AppFailure?,
      rows: rows ?? this.rows,
      totalCount: totalCount ?? this.totalCount,
      summaryRows: summaryRows ?? this.summaryRows,
      topGainers: topGainers ?? this.topGainers,
      topLosers: topLosers ?? this.topLosers,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SalesProdutoTendenciaPresentationState &&
        other.selectedAgentId == selectedAgentId &&
        listEquals(other.availableAgents, availableAgents) &&
        other.grupoProdutoLabel == grupoProdutoLabel &&
        other.marcaProdutoLabel == marcaProdutoLabel &&
        other.periodoAtual == periodoAtual &&
        other.periodoAnterior == periodoAnterior &&
        other.searchTerm == searchTerm &&
        other.classificacao == classificacao &&
        other.codGrupoProduto == codGrupoProduto &&
        other.codMarca == codMarca &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.loading == loading &&
        other.detailsLoading == detailsLoading &&
        other.authenticationFailed == authenticationFailed &&
        other.loadFailure == loadFailure &&
        listEquals(other.rows, rows) &&
        other.totalCount == totalCount &&
        listEquals(other.summaryRows, summaryRows) &&
        listEquals(other.topGainers, topGainers) &&
        listEquals(other.topLosers, topLosers);
  }

  @override
  int get hashCode => Object.hash(
    selectedAgentId,
    Object.hashAll(availableAgents),
    grupoProdutoLabel,
    marcaProdutoLabel,
    periodoAtual,
    periodoAnterior,
    searchTerm,
    classificacao,
    codGrupoProduto,
    codMarca,
    page,
    pageSize,
    loading,
    detailsLoading,
    authenticationFailed,
    loadFailure,
    Object.hash(
      Object.hashAll(rows),
      totalCount,
      Object.hashAll(summaryRows),
      Object.hashAll(topGainers),
      Object.hashAll(topLosers),
    ),
  );
}

const Object _sentinel = Object();
