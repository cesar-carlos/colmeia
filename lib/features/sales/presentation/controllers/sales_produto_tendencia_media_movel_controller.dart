import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_grupo_marca_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/state/sales_produto_tendencia_media_movel_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:flutter/material.dart';

enum SalesProdutoTendenciaMediaMovelReloadOutcomeKind {
  success,
  failure,
  cancelled,
  superseded,
}

@immutable
class SalesProdutoTendenciaMediaMovelReloadOutcome {
  const SalesProdutoTendenciaMediaMovelReloadOutcome._(
    this.kind, {
    this.loadFailure,
    this.dimensionOptionsFailure,
  });

  const SalesProdutoTendenciaMediaMovelReloadOutcome.success({
    AppFailure? dimensionOptionsFailure,
  }) : this._(
         SalesProdutoTendenciaMediaMovelReloadOutcomeKind.success,
         dimensionOptionsFailure: dimensionOptionsFailure,
       );

  const SalesProdutoTendenciaMediaMovelReloadOutcome.failure({
    AppFailure? loadFailure,
    AppFailure? dimensionOptionsFailure,
  }) : this._(
         SalesProdutoTendenciaMediaMovelReloadOutcomeKind.failure,
         loadFailure: loadFailure,
         dimensionOptionsFailure: dimensionOptionsFailure,
       );

  const SalesProdutoTendenciaMediaMovelReloadOutcome.cancelled()
    : this._(SalesProdutoTendenciaMediaMovelReloadOutcomeKind.cancelled);

  const SalesProdutoTendenciaMediaMovelReloadOutcome.superseded()
    : this._(SalesProdutoTendenciaMediaMovelReloadOutcomeKind.superseded);

  final SalesProdutoTendenciaMediaMovelReloadOutcomeKind kind;
  final AppFailure? loadFailure;
  final AppFailure? dimensionOptionsFailure;

  bool get isSuccess =>
      kind == SalesProdutoTendenciaMediaMovelReloadOutcomeKind.success;

  bool get isFailure =>
      kind == SalesProdutoTendenciaMediaMovelReloadOutcomeKind.failure;

  bool get isCancelled =>
      kind == SalesProdutoTendenciaMediaMovelReloadOutcomeKind.cancelled;

  bool get isSuperseded =>
      kind == SalesProdutoTendenciaMediaMovelReloadOutcomeKind.superseded;
}

class SalesProdutoTendenciaMediaMovelController extends ChangeNotifier {
  SalesProdutoTendenciaMediaMovelController({
    required SalesSessionService sessionService,
    required LoadAvailableAgentsForSales loadSalesAvailableAgentsUseCase,
    required ResolveSalesAgentClientTokenUseCase resolveSalesAgentClientTokenUseCase,
    required LoadProdutoVendidoTendenciaDeVendaMediaMovelScreenUseCase
    loadTrendScreenUseCase,
    required LoadGrupoMarcaProdutoOptionsUseCase loadGrupoMarcaProdutoOptionsUseCase,
    AgentQueriesRelayCancelScopeBinder? relayCancelScopeBinder,
  }) : _sessionService = sessionService,
       _loadAgentsUseCase = loadSalesAvailableAgentsUseCase,
       _resolveClientTokenUseCase = resolveSalesAgentClientTokenUseCase,
       _loadTrendScreen = loadTrendScreenUseCase,
       _loadGrupoMarcaOptions = loadGrupoMarcaProdutoOptionsUseCase,
       _relayCancelScopeBinder = relayCancelScopeBinder,
       _state = _restoreInitialState(sessionService) {
    _selectedAgentId = _state.selectedAgentId;
  }

  static const String cardFilterId =
      SalesAutoRefreshCardIds.produtoTendenciaMediaMovel;
  static const List<int> pageSizeOptions = <int>[10, 20, 50, 100];

  final SalesSessionService _sessionService;
  final LoadAvailableAgentsForSales _loadAgentsUseCase;
  final ResolveSalesAgentClientTokenUseCase _resolveClientTokenUseCase;
  final LoadProdutoVendidoTendenciaDeVendaMediaMovelScreenUseCase
  _loadTrendScreen;
  final LoadGrupoMarcaProdutoOptionsUseCase _loadGrupoMarcaOptions;
  final AgentQueriesRelayCancelScopeBinder? _relayCancelScopeBinder;

  SalesProdutoTendenciaMediaMovelPresentationState _state;
  String? _boundUserId;
  String? _selectedAgentId;
  int _sqlLoadGeneration = 0;
  AgentQueriesCancelScope? _sqlCancelScope;
  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;
  bool _disposed = false;

  SalesProdutoTendenciaMediaMovelPresentationState get state => _state;

  AgentQueriesCancelScope? get sqlCancelScope => _sqlCancelScope;

  static SalesProdutoTendenciaMediaMovelPresentationState _restoreInitialState(
    SalesSessionService sessionService,
  ) {
    final restored = sessionService.restoreCardFilters(cardFilterId);
    final quantidadeDias =
        _restorePositiveInt(restored['quantidade_dias'])?.clamp(
          1,
          ProdutoVendidoTendenciaDeVendaMediaMovelFilter.maxQuantidadeDias,
        ) ??
        7;
    final searchTerm = (restored['search_term'] as String?)?.trim() ?? '';
    final restoredClassificacao = (restored['classificacao'] as String?)
        ?.trim()
        .toUpperCase();
    final classificacao =
        ProdutoVendidoTendenciaDeVendaMediaMovelFilter.allowedClassificacoes
            .contains(restoredClassificacao)
        ? restoredClassificacao
        : null;
    final codGrupoProduto = _restorePositiveInt(restored['cod_grupo_produto']);

    final restoredSortByName = (restored['sort_by'] as String?)?.trim();
    final sortBy = ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.values
        .firstWhere(
          (value) => value.name == restoredSortByName,
          orElse: () => ProdutoVendidoTendenciaDeVendaMediaMovelSortBy
              .tendenciaPercentualDesc,
        );

    final restoredPageSize = _restorePositiveInt(restored['page_size']);
    final pageSize =
        restoredPageSize != null && pageSizeOptions.contains(restoredPageSize)
        ? restoredPageSize
        : ProdutoVendidoTendenciaDeVendaMediaMovelFilter.defaultPageSize;

    return SalesProdutoTendenciaMediaMovelPresentationState(
      selectedAgentId: sessionService.selectedAgentId,
      quantidadeDias: quantidadeDias,
      searchTerm: searchTerm,
      classificacao: classificacao,
      codGrupoProduto: codGrupoProduto,
      sortBy: sortBy,
      pageSize: pageSize,
    );
  }

  Future<void> bindUser(String? userId) async {
    if (_boundUserId == userId) {
      return;
    }
    _boundUserId = userId;
    if (userId == null) {
      return;
    }
    await _loadAgents(userId);
  }

  Future<SalesProdutoTendenciaMediaMovelReloadOutcome> reload() =>
      _performReload();

  Future<void> changeAgent(String agentId) async {
    _selectedAgentId = agentId;
    _setState(
      _state.copyWith(
        selectedAgentId: agentId,
        page: 1,
      ),
    );
    await _sessionService.setSelectedAgentId(agentId);
    await reload();
  }

  Future<void> applyFilters(Map<String, Object?> next) async {
    final nextAgentId = (next['agentId'] as String?)?.trim();
    final normalizedAgentId = nextAgentId == null || nextAgentId.isEmpty
        ? null
        : nextAgentId;
    final nextQuantidadeDias =
        (next['quantidadeDias'] as int?) ?? _state.quantidadeDias;
    final nextSearch = (next['searchTerm'] as String?)?.trim() ?? '';
    final nextClassificacao = (next['classificacao'] as String?)
        ?.trim()
        .toUpperCase();
    final nextGrupo = _restorePositiveInt(next['codGrupoProduto']);
    final nextSortByName = next['sortBy'] as String?;
    final nextSortBy = ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.values
        .firstWhere(
          (value) => value.name == nextSortByName,
          orElse: () => _state.sortBy,
        );
    final nextPageSize =
        _restorePositiveInt(next['pageSize']) ?? _state.pageSize;

    final optionsLoadedForAgentId = _state.optionsLoadedForAgentId;
    final agentChanged = optionsLoadedForAgentId != normalizedAgentId;

    _selectedAgentId = normalizedAgentId;
    _setState(
      _state.copyWith(
        selectedAgentId: normalizedAgentId,
        quantidadeDias: nextQuantidadeDias,
        searchTerm: nextSearch,
        classificacao:
            ProdutoVendidoTendenciaDeVendaMediaMovelFilter.allowedClassificacoes
                .contains(nextClassificacao)
            ? nextClassificacao
            : null,
        codGrupoProduto: nextGrupo,
        sortBy: nextSortBy,
        pageSize: pageSizeOptions.contains(nextPageSize)
            ? nextPageSize
            : _state.pageSize,
        page: 1,
        grupoOptions: agentChanged
            ? const <GrupoProdutoOption>[]
            : _state.grupoOptions,
        dimensionOptionsLoadFailure: agentChanged
            ? null
            : _state.dimensionOptionsLoadFailure,
        optionsLoadedForAgentId: agentChanged ? null : optionsLoadedForAgentId,
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
    await reload();
  }

  Future<void> selectPage(int page) async {
    if (page == _state.page || page < 1) {
      return;
    }
    final totalPages = _state.pageResult.totalCount == 0
        ? 0
        : (_state.pageResult.totalCount / _state.pageSize).ceil();
    if (page > totalPages) {
      return;
    }
    _setState(
      _state.copyWith(
        page: page,
        pageResult: ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
          items: const <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
          totalCount: _state.pageResult.totalCount,
        ),
      ),
    );
    await reload();
  }

  ProdutoVendidoTendenciaDeVendaMediaMovelFilter shareDetailFilter() {
    return ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
      quantidadeDias: _state.quantidadeDias,
      searchTerm: _state.searchTerm,
      classificacao: _state.classificacao,
      codGrupoProduto: _state.codGrupoProduto,
      sortBy: _state.sortBy,
      pageSize: _state.pageSize,
    );
  }

  Future<String?> resolveClientToken({
    required String userId,
    required String agentId,
  }) => _resolveClientToken(userId: userId, agentId: agentId);

  Future<SalesProdutoTendenciaMediaMovelReloadOutcome>
  retryDimensionOptionsLoad() async {
    final userId = _boundUserId;
    final agentId = _state.selectedAgentId?.trim();
    if (userId == null || agentId == null || agentId.isEmpty) {
      return const SalesProdutoTendenciaMediaMovelReloadOutcome.cancelled();
    }
    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: agentId,
    );
    if (_disposed || clientToken == null) {
      return const SalesProdutoTendenciaMediaMovelReloadOutcome.cancelled();
    }
    final failure = await _loadDimensionOptions(
      userId: userId,
      agentId: agentId,
      clientToken: clientToken,
      generation: _sqlLoadGeneration,
      cancelScope: _sqlCancelScope,
    );
    if (_disposed) {
      return const SalesProdutoTendenciaMediaMovelReloadOutcome.superseded();
    }
    return failure == null
        ? const SalesProdutoTendenciaMediaMovelReloadOutcome.success()
        : SalesProdutoTendenciaMediaMovelReloadOutcome.failure(
            dimensionOptionsFailure: failure,
          );
  }

  @override
  void dispose() {
    _disposed = true;
    _sqlCancelScope?.cancelAll();
    super.dispose();
  }

  Future<void> _loadAgents(String userId) async {
    final agents = await _loadAgentsUseCase(userId);
    if (_isStaleBoundUser(userId)) {
      return;
    }

    final nextSelection = reconcileSelectedSalesAgentId(
      agents: agents,
      previousSelectedId: _selectedAgentId,
    );
    _selectedAgentId = nextSelection;
    _setState(
      _state.copyWith(
        availableAgents: agents,
        selectedAgentId: nextSelection,
      ),
    );
    if (nextSelection != _sessionService.selectedAgentId) {
      unawaited(_sessionService.setSelectedAgentId(nextSelection));
    }
    if (_isStaleBoundUser(userId)) {
      return;
    }
    await reload();
  }

  bool _isStaleBoundUser(String userId) {
    return _disposed || _boundUserId != userId;
  }

  Future<SalesProdutoTendenciaMediaMovelReloadOutcome> _performReload() async {
    final userId = _boundUserId;
    final agentId = _state.selectedAgentId;
    final generation = ++_sqlLoadGeneration;
    _sqlCancelScope?.cancelAll();
    final sqlScope = AgentQueriesCancelScope();
    _sqlCancelScope = sqlScope;
    _relayCancelScopeBinder?.call(sqlScope);

    _setState(
      _state.copyWith(
        loading: true,
        authenticationFailed: false,
        loadFailure: null,
      ),
    );

    if (userId == null || agentId == null || agentId.trim().isEmpty) {
      if (_disposed || generation != _sqlLoadGeneration) {
        return const SalesProdutoTendenciaMediaMovelReloadOutcome.superseded();
      }
      _setState(
        _state.copyWith(
          loading: false,
          pageResult: const ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
            items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
            totalCount: 0,
          ),
          summaryRows:
              const <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[],
          authenticationFailed: false,
          loadFailure: null,
        ),
      );
      return const SalesProdutoTendenciaMediaMovelReloadOutcome.cancelled();
    }

    final trimmedAgentId = agentId.trim();
    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: trimmedAgentId,
    );
    if (_disposed || generation != _sqlLoadGeneration) {
      return const SalesProdutoTendenciaMediaMovelReloadOutcome.superseded();
    }
    if (clientToken == null) {
      _setState(
        _state.copyWith(
          loading: false,
          pageResult: const ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
            items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
            totalCount: 0,
          ),
          summaryRows:
              const <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[],
          authenticationFailed: true,
          loadFailure: null,
        ),
      );
      return const SalesProdutoTendenciaMediaMovelReloadOutcome.cancelled();
    }

    AppFailure? dimensionOptionsFailure;
    if (_state.optionsLoadedForAgentId != trimmedAgentId) {
      dimensionOptionsFailure = await _loadDimensionOptions(
        userId: userId,
        agentId: trimmedAgentId,
        clientToken: clientToken,
        generation: generation,
        cancelScope: sqlScope,
      );
      if (_disposed || generation != _sqlLoadGeneration) {
        return const SalesProdutoTendenciaMediaMovelReloadOutcome.superseded();
      }
    }

    final filter = ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
      quantidadeDias: _state.quantidadeDias,
      searchTerm: _state.searchTerm,
      classificacao: _state.classificacao,
      codGrupoProduto: _state.codGrupoProduto,
      sortBy: _state.sortBy,
      page: _state.page,
      pageSize: _state.pageSize,
    );

    final screenResult = await _loadTrendScreen(
      userId: userId,
      agentId: trimmedAgentId,
      filter: filter,
      clientToken: clientToken,
      cancelScope: sqlScope,
    );

    if (_disposed || generation != _sqlLoadGeneration) {
      return const SalesProdutoTendenciaMediaMovelReloadOutcome.superseded();
    }

    return screenResult.fold(
      (data) {
        _setState(
          _state.copyWith(
            pageResult: data.page,
            summaryRows: data.summaryRows,
            loading: false,
            authenticationFailed: false,
            loadFailure: null,
          ),
        );
        return SalesProdutoTendenciaMediaMovelReloadOutcome.success(
          dimensionOptionsFailure: dimensionOptionsFailure,
        );
      },
      (failure) {
        _setState(
          _state.copyWith(
            pageResult: const ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
              items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
              totalCount: 0,
            ),
            summaryRows:
                const <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[],
            loading: false,
            authenticationFailed: false,
            loadFailure: failure,
          ),
        );
        return SalesProdutoTendenciaMediaMovelReloadOutcome.failure(
          loadFailure: failure,
          dimensionOptionsFailure: dimensionOptionsFailure,
        );
      },
    );
  }

  Future<String?> _resolveClientToken({
    required String userId,
    required String agentId,
  }) async {
    if (_cachedClientTokenUserId == userId &&
        _cachedClientTokenAgentId == agentId) {
      return _cachedClientToken;
    }
    final resolved = await _resolveClientTokenUseCase(
      userId: userId,
      agentId: agentId,
    );
    if (resolved != null) {
      _cachedClientTokenUserId = userId;
      _cachedClientTokenAgentId = agentId;
      _cachedClientToken = resolved;
    }
    return resolved;
  }

  Future<AppFailure?> _loadDimensionOptions({
    required String userId,
    required String agentId,
    required String clientToken,
    required int generation,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final batchResult = await _loadGrupoMarcaOptions(
      userId: userId,
      agentId: agentId,
      pageSize: 200,
      clientToken: clientToken,
      cancelScope: cancelScope,
    );
    if (_disposed || generation != _sqlLoadGeneration) {
      return null;
    }

    AppFailure? optionsFailure;
    final nextGrupos = batchResult.fold(
      (batch) => batch.grupoOptions,
      (failure) {
        optionsFailure = failure;
        return const <GrupoProdutoOption>[];
      },
    );

    _setState(
      _state.copyWith(
        grupoOptions: nextGrupos,
        optionsLoadedForAgentId: agentId,
        dimensionOptionsLoadFailure: optionsFailure,
      ),
    );
    return optionsFailure;
  }

  Future<void> _persistFilters() {
    return _sessionService.persistCardFilters(cardFilterId, <String, Object?>{
      'quantidade_dias': _state.quantidadeDias,
      'search_term': _state.searchTerm,
      'classificacao': _state.classificacao,
      'cod_grupo_produto': _state.codGrupoProduto,
      'sort_by': _state.sortBy.name,
      'page_size': _state.pageSize,
    });
  }

  void _setState(SalesProdutoTendenciaMediaMovelPresentationState nextState) {
    if (_disposed || _state == nextState) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }

  static int? _restorePositiveInt(Object? raw) {
    final value = raw is int ? raw : int.tryParse('$raw');
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }
}
