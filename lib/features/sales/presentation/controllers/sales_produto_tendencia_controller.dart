import 'dart:async';

import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_trend_controller_base.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_trend_reload_outcome.dart';
import 'package:colmeia/features/sales/presentation/state/sales_produto_tendencia_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_trend_date_preset.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/material.dart';

export 'package:colmeia/features/sales/presentation/controllers/sales_trend_reload_outcome.dart'
    show SalesProdutoTendenciaReloadOutcome;

class SalesProdutoTendenciaController extends SalesTrendControllerBase {
  SalesProdutoTendenciaController({
    required super.sessionService,
    required super.loadSalesAvailableAgentsUseCase,
    required super.resolveSalesAgentClientTokenUseCase,
    required LoadProdutoVendidoTendenciaDeVendaScreenUseCase
    loadTrendScreenUseCase,
    required LoadProdutoVendidoTendenciaDeVendaUseCase loadTrendPageUseCase,
    super.relayCancelScopeBinder,
  }) : _sessionService = sessionService,
       _loadTrendScreen = loadTrendScreenUseCase,
       _loadTrendPage = loadTrendPageUseCase,
       _state = _restoreInitialState(sessionService) {
    selectedAgentId = _state.selectedAgentId;
  }

  static const String cardFilterId = SalesAutoRefreshCardIds.produtoTendencia;

  final SalesSessionService _sessionService;
  final LoadProdutoVendidoTendenciaDeVendaScreenUseCase _loadTrendScreen;
  final LoadProdutoVendidoTendenciaDeVendaUseCase _loadTrendPage;

  SalesProdutoTendenciaPresentationState _state;

  SalesProdutoTendenciaPresentationState get state => _state;

  @override
  String? get trendSelectedAgentId => _state.selectedAgentId;

  static SalesProdutoTendenciaPresentationState _restoreInitialState(
    SalesSessionService sessionService,
  ) {
    final now = DateTime.now();
    final restored = sessionService.restoreCardFilters(cardFilterId);
    final periodoAtual =
        SalesTrendControllerBase.restoreDateRange(
          restored,
          startKey: 'periodo_atual_start_ms',
          endKey: 'periodo_atual_end_ms',
        ) ??
        salesTrendFullMonthInclusiveRange(now);
    final periodoAnterior =
        SalesTrendControllerBase.restoreDateRange(
          restored,
          startKey: 'periodo_anterior_start_ms',
          endKey: 'periodo_anterior_end_ms',
        ) ??
        salesTrendPreviousMonthInclusiveRange(now);
    final searchTerm = (restored['search_term'] as String?)?.trim() ?? '';
    final restoredClassificacao = (restored['classificacao'] as String?)
        ?.trim()
        .toUpperCase();
    final classificacao =
        ProdutoVendidoTendenciaDeVendaFilter.allowedClassificacoes.contains(
          restoredClassificacao,
        )
        ? restoredClassificacao
        : null;
    final codGrupoProduto = SalesTrendControllerBase.restorePositiveInt(
      restored['cod_grupo_produto'],
    );
    final codMarca = SalesTrendControllerBase.restorePositiveInt(
      restored['cod_marca'],
    );
    final restoredGrupoLabel = (restored['grupo_produto_label'] as String?)
        ?.trim();
    final restoredMarcaLabel = (restored['marca_produto_label'] as String?)
        ?.trim();
    final restoredPageSize = SalesTrendControllerBase.restorePositiveInt(
      restored['page_size'],
    );
    final pageSize =
        restoredPageSize != null &&
            SalesTrendControllerBase.pageSizeOptions.contains(restoredPageSize)
        ? restoredPageSize
        : ProdutoVendidoTendenciaDeVendaFilter.defaultPageSize;

    return SalesProdutoTendenciaPresentationState(
      selectedAgentId: sessionService.selectedAgentId,
      periodoAtual: periodoAtual,
      periodoAnterior: periodoAnterior,
      searchTerm: searchTerm,
      classificacao: classificacao,
      codGrupoProduto: codGrupoProduto,
      codMarca: codMarca,
      grupoProdutoLabel:
          codGrupoProduto != null &&
              restoredGrupoLabel != null &&
              restoredGrupoLabel.isNotEmpty
          ? restoredGrupoLabel
          : null,
      marcaProdutoLabel:
          codMarca != null &&
              restoredMarcaLabel != null &&
              restoredMarcaLabel.isNotEmpty
          ? restoredMarcaLabel
          : null,
      pageSize: pageSize,
    );
  }

  Future<SalesTrendReloadOutcome> reload() => performFullReload();

  Future<void> applyFilters(Map<String, Object?> next) async {
    final nextAgentId = (next['agentId'] as String?)?.trim();
    final normalizedAgentId = nextAgentId == null || nextAgentId.isEmpty
        ? null
        : nextAgentId;
    final nextAtual = next['periodoAtual'] as DateTimeRange?;
    final nextAnterior = next['periodoAnterior'] as DateTimeRange?;
    final nextSearch = (next['searchTerm'] as String?)?.trim() ?? '';
    final nextClassificacao = (next['classificacao'] as String?)
        ?.trim()
        .toUpperCase();
    final nextGrupo = SalesTrendControllerBase.restorePositiveInt(
      next['codGrupoProduto'],
    );
    final nextMarca = SalesTrendControllerBase.restorePositiveInt(
      next['codMarca'],
    );
    final nextGrupoLabel = (next['grupoProdutoLabel'] as String?)?.trim();
    final nextMarcaLabel = (next['marcaProdutoLabel'] as String?)?.trim();
    final nextPageSize =
        SalesTrendControllerBase.restorePositiveInt(next['pageSize']) ??
        _state.pageSize;

    final agentChanged = _state.selectedAgentId != normalizedAgentId;

    selectedAgentId = normalizedAgentId;
    _setState(
      _state.copyWith(
        selectedAgentId: normalizedAgentId,
        periodoAtual: nextAtual ?? _state.periodoAtual,
        periodoAnterior: nextAnterior ?? _state.periodoAnterior,
        searchTerm: nextSearch,
        classificacao:
            ProdutoVendidoTendenciaDeVendaFilter.allowedClassificacoes.contains(
              nextClassificacao,
            )
            ? nextClassificacao
            : null,
        codGrupoProduto: nextGrupo,
        codMarca: nextMarca,
        grupoProdutoLabel: agentChanged || nextGrupo == null
            ? (nextGrupo == null ? null : nextGrupoLabel)
            : (nextGrupoLabel ?? _state.grupoProdutoLabel),
        marcaProdutoLabel: agentChanged || nextMarca == null
            ? (nextMarca == null ? null : nextMarcaLabel)
            : (nextMarcaLabel ?? _state.marcaProdutoLabel),
        pageSize:
            SalesTrendControllerBase.pageSizeOptions.contains(nextPageSize)
            ? nextPageSize
            : _state.pageSize,
        page: 1,
      ),
    );
    unawaited(_sessionService.setSelectedAgentId(normalizedAgentId));
    unawaited(_persistFilters());
    await reload();
  }

  Future<void> changePageSize(int size) async {
    if (size == _state.pageSize) {
      return;
    }
    _setState(_state.copyWith(pageSize: size, page: 1));
    unawaited(_persistFilters());
    await reloadDetailsOnly();
  }

  Future<void> selectPage(int page) async {
    if (page == _state.page || page < 1) {
      return;
    }
    final totalPages = _state.totalCount == 0
        ? 0
        : (_state.totalCount / _state.pageSize).ceil();
    if (page > totalPages) {
      return;
    }
    _setState(
      _state.copyWith(
        page: page,
        rows: const <ProdutoVendidoTendenciaDeVendaRow>[],
      ),
    );
    await reloadDetailsOnly();
  }

  Future<SalesTrendReloadOutcome> reloadDetailsOnly() =>
      performDetailsOnlyReload();

  @override
  void applyAvailableAgents({
    required List<DashboardAgentOption> agents,
    required String? selectedAgentId,
  }) {
    _setState(
      _state.copyWith(
        availableAgents: agents,
        selectedAgentId: selectedAgentId,
      ),
    );
  }

  @override
  Future<SalesTrendReloadOutcome> performFullReload() async {
    final userId = boundUserId;
    final agentId = _state.selectedAgentId;
    final (:generation, :scope) = beginSqlLoad();

    _setState(
      _state.copyWith(
        loading: true,
        authenticationFailed: false,
        loadFailure: null,
      ),
    );

    if (userId == null || agentId == null || agentId.trim().isEmpty) {
      if (isSuperseded(generation)) {
        return const SalesTrendReloadOutcome.superseded();
      }
      _setState(
        _state.copyWith(
          loading: false,
          rows: const <ProdutoVendidoTendenciaDeVendaRow>[],
          totalCount: 0,
          summaryRows: const <ProdutoVendidoTendenciaDeVendaSummaryRow>[],
          topGainers: const <ProdutoVendidoTendenciaDeVendaRow>[],
          topLosers: const <ProdutoVendidoTendenciaDeVendaRow>[],
          authenticationFailed: false,
          loadFailure: null,
        ),
      );
      return const SalesTrendReloadOutcome.cancelled();
    }

    final trimmedAgentId = agentId.trim();
    final clientToken = await resolveClientToken(
      userId: userId,
      agentId: trimmedAgentId,
    );
    if (isSuperseded(generation)) {
      return const SalesTrendReloadOutcome.superseded();
    }
    if (clientToken == null) {
      _setState(
        _state.copyWith(
          loading: false,
          rows: const <ProdutoVendidoTendenciaDeVendaRow>[],
          totalCount: 0,
          summaryRows: const <ProdutoVendidoTendenciaDeVendaSummaryRow>[],
          topGainers: const <ProdutoVendidoTendenciaDeVendaRow>[],
          topLosers: const <ProdutoVendidoTendenciaDeVendaRow>[],
          authenticationFailed: true,
          loadFailure: null,
        ),
      );
      return const SalesTrendReloadOutcome.cancelled();
    }

    final detailFilter = _detailFilter();
    final screenResult = await _loadTrendScreen(
      userId: userId,
      agentId: trimmedAgentId,
      pageFilter: detailFilter,
      summaryFilter: detailFilter,
      clientToken: clientToken,
      cancelScope: scope,
    );

    if (isSuperseded(generation)) {
      return const SalesTrendReloadOutcome.superseded();
    }

    return screenResult.fold(
      (data) {
        _setState(
          _state.copyWith(
            rows: data.rows,
            totalCount: data.totalCount,
            summaryRows: data.summaryRows,
            topGainers: data.topGainers,
            topLosers: data.topLosers,
            loading: false,
            authenticationFailed: false,
            loadFailure: null,
          ),
        );
        return const SalesTrendReloadOutcome.success();
      },
      (failure) {
        _setState(
          _state.copyWith(
            rows: const <ProdutoVendidoTendenciaDeVendaRow>[],
            totalCount: 0,
            summaryRows: const <ProdutoVendidoTendenciaDeVendaSummaryRow>[],
            topGainers: const <ProdutoVendidoTendenciaDeVendaRow>[],
            topLosers: const <ProdutoVendidoTendenciaDeVendaRow>[],
            loading: false,
            authenticationFailed: false,
            loadFailure: failure,
          ),
        );
        return SalesTrendReloadOutcome.failure(loadFailure: failure);
      },
    );
  }

  @override
  Future<SalesTrendReloadOutcome> performDetailsOnlyReload() async {
    final userId = boundUserId;
    final agentId = _state.selectedAgentId;
    final (:generation, :scope) = beginSqlLoad();

    _setState(
      _state.copyWith(
        loading: true,
        loadFailure: null,
      ),
    );

    if (userId == null || agentId == null || agentId.trim().isEmpty) {
      if (isSuperseded(generation)) {
        return const SalesTrendReloadOutcome.superseded();
      }
      _setState(_state.copyWith(loading: false));
      return const SalesTrendReloadOutcome.cancelled();
    }

    final trimmedAgentId = agentId.trim();
    final clientToken = await resolveClientToken(
      userId: userId,
      agentId: trimmedAgentId,
    );
    if (isSuperseded(generation)) {
      return const SalesTrendReloadOutcome.superseded();
    }
    if (clientToken == null) {
      _setState(
        _state.copyWith(
          loading: false,
          authenticationFailed: true,
        ),
      );
      return const SalesTrendReloadOutcome.cancelled();
    }

    final pageResult = await _loadTrendPage(
      userId: userId,
      agentId: trimmedAgentId,
      filter: _detailFilter(),
      clientToken: clientToken,
      cancelScope: scope,
    );

    if (isSuperseded(generation)) {
      return const SalesTrendReloadOutcome.superseded();
    }

    return pageResult.fold(
      (page) {
        _setState(
          _state.copyWith(
            rows: page.items,
            totalCount: page.totalCount,
            loading: false,
            loadFailure: null,
          ),
        );
        return const SalesTrendReloadOutcome.success();
      },
      (failure) {
        _setState(
          _state.copyWith(
            rows: const <ProdutoVendidoTendenciaDeVendaRow>[],
            loading: false,
            loadFailure: failure,
          ),
        );
        return SalesTrendReloadOutcome.failure(loadFailure: failure);
      },
    );
  }

  ProdutoVendidoTendenciaDeVendaFilter _detailFilter() {
    return ProdutoVendidoTendenciaDeVendaFilter(
      periodoAtualInicio: _state.periodoAtual.start,
      periodoAtualFim: _state.periodoAtual.end,
      periodoAnteriorInicio: _state.periodoAnterior.start,
      periodoAnteriorFim: _state.periodoAnterior.end,
      searchTerm: _state.searchTerm,
      classificacao: _state.classificacao,
      codGrupoProduto: _state.codGrupoProduto,
      codMarca: _state.codMarca,
      page: _state.page,
      pageSize: _state.pageSize,
    );
  }

  Future<void> _persistFilters() {
    return _sessionService.persistCardFilters(cardFilterId, <String, Object?>{
      'periodo_atual_start_ms':
          _state.periodoAtual.start.millisecondsSinceEpoch,
      'periodo_atual_end_ms': _state.periodoAtual.end.millisecondsSinceEpoch,
      'periodo_anterior_start_ms':
          _state.periodoAnterior.start.millisecondsSinceEpoch,
      'periodo_anterior_end_ms':
          _state.periodoAnterior.end.millisecondsSinceEpoch,
      'search_term': _state.searchTerm,
      'classificacao': _state.classificacao,
      'cod_grupo_produto': _state.codGrupoProduto,
      'cod_marca': _state.codMarca,
      'grupo_produto_label': _state.grupoProdutoLabel,
      'marca_produto_label': _state.marcaProdutoLabel,
      'page_size': _state.pageSize,
    });
  }

  void _setState(SalesProdutoTendenciaPresentationState nextState) {
    if (isDisposed || _state == nextState) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }
}
