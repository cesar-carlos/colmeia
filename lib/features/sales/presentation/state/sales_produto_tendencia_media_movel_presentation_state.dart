import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/foundation.dart';

@immutable
class SalesProdutoTendenciaMediaMovelPresentationState {
  const SalesProdutoTendenciaMediaMovelPresentationState({
    required this.quantidadeDias,
    this.selectedAgentId,
    this.availableAgents = const <DashboardAgentOption>[],
    this.grupoOptions = const <GrupoProdutoOption>[],
    this.optionsLoadedForAgentId,
    this.dimensionOptionsLoadFailure,
    this.searchTerm = '',
    this.classificacao,
    this.codGrupoProduto,
    this.sortBy =
        ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.tendenciaPercentualDesc,
    this.page = 1,
    this.pageSize =
        ProdutoVendidoTendenciaDeVendaMediaMovelFilter.defaultPageSize,
    this.loading = false,
    this.authenticationFailed = false,
    this.loadFailure,
    this.pageResult =
        const ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
          items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
          totalCount: 0,
        ),
    this.summaryRows =
        const <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[],
  });

  final String? selectedAgentId;
  final List<DashboardAgentOption> availableAgents;
  final List<GrupoProdutoOption> grupoOptions;
  final String? optionsLoadedForAgentId;
  final AppFailure? dimensionOptionsLoadFailure;
  final int quantidadeDias;
  final String searchTerm;
  final String? classificacao;
  final int? codGrupoProduto;
  final ProdutoVendidoTendenciaDeVendaMediaMovelSortBy sortBy;
  final int page;
  final int pageSize;
  final bool loading;
  final bool authenticationFailed;
  final AppFailure? loadFailure;
  final ProdutoVendidoTendenciaDeVendaMediaMovelPageResult pageResult;
  final List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow> summaryRows;

  bool get hasPlainError => authenticationFailed;

  SalesProdutoTendenciaMediaMovelPresentationState copyWith({
    String? selectedAgentId,
    List<DashboardAgentOption>? availableAgents,
    List<GrupoProdutoOption>? grupoOptions,
    Object? optionsLoadedForAgentId = _sentinel,
    Object? dimensionOptionsLoadFailure = _sentinel,
    int? quantidadeDias,
    String? searchTerm,
    Object? classificacao = _sentinel,
    Object? codGrupoProduto = _sentinel,
    ProdutoVendidoTendenciaDeVendaMediaMovelSortBy? sortBy,
    int? page,
    int? pageSize,
    bool? loading,
    bool? authenticationFailed,
    Object? loadFailure = _sentinel,
    ProdutoVendidoTendenciaDeVendaMediaMovelPageResult? pageResult,
    List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>? summaryRows,
  }) {
    return SalesProdutoTendenciaMediaMovelPresentationState(
      selectedAgentId: selectedAgentId ?? this.selectedAgentId,
      availableAgents: availableAgents ?? this.availableAgents,
      grupoOptions: grupoOptions ?? this.grupoOptions,
      optionsLoadedForAgentId: identical(optionsLoadedForAgentId, _sentinel)
          ? this.optionsLoadedForAgentId
          : optionsLoadedForAgentId as String?,
      dimensionOptionsLoadFailure: identical(
        dimensionOptionsLoadFailure,
        _sentinel,
      )
          ? this.dimensionOptionsLoadFailure
          : dimensionOptionsLoadFailure as AppFailure?,
      quantidadeDias: quantidadeDias ?? this.quantidadeDias,
      searchTerm: searchTerm ?? this.searchTerm,
      classificacao: identical(classificacao, _sentinel)
          ? this.classificacao
          : classificacao as String?,
      codGrupoProduto: identical(codGrupoProduto, _sentinel)
          ? this.codGrupoProduto
          : codGrupoProduto as int?,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      loading: loading ?? this.loading,
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
        listEquals(other.grupoOptions, grupoOptions) &&
        other.optionsLoadedForAgentId == optionsLoadedForAgentId &&
        other.dimensionOptionsLoadFailure == dimensionOptionsLoadFailure &&
        other.quantidadeDias == quantidadeDias &&
        other.searchTerm == searchTerm &&
        other.classificacao == classificacao &&
        other.codGrupoProduto == codGrupoProduto &&
        other.sortBy == sortBy &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.loading == loading &&
        other.authenticationFailed == authenticationFailed &&
        other.loadFailure == loadFailure &&
        other.pageResult == pageResult &&
        listEquals(other.summaryRows, summaryRows);
  }

  @override
  int get hashCode => Object.hash(
    selectedAgentId,
    Object.hashAll(availableAgents),
    Object.hashAll(grupoOptions),
    optionsLoadedForAgentId,
    dimensionOptionsLoadFailure,
    quantidadeDias,
    searchTerm,
    classificacao,
    codGrupoProduto,
    sortBy,
    page,
    pageSize,
    loading,
    authenticationFailed,
    loadFailure,
    pageResult,
    Object.hashAll(summaryRows),
  );
}

const Object _sentinel = Object();
