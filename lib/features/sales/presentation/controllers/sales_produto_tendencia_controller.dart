import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_grupo_marca_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/marca_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/state/sales_produto_tendencia_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_trend_date_preset.dart';
import 'package:flutter/material.dart';

enum SalesProdutoTendenciaReloadOutcomeKind {
  success,
  failure,
  cancelled,
  superseded,
}

@immutable
class SalesProdutoTendenciaReloadOutcome {
  const SalesProdutoTendenciaReloadOutcome._(
    this.kind, {
    this.loadFailure,
    this.dimensionOptionsFailure,
  });

  const SalesProdutoTendenciaReloadOutcome.success({
    AppFailure? dimensionOptionsFailure,
  }) : this._(
         SalesProdutoTendenciaReloadOutcomeKind.success,
         dimensionOptionsFailure: dimensionOptionsFailure,
       );

  const SalesProdutoTendenciaReloadOutcome.failure({
    AppFailure? loadFailure,
    AppFailure? dimensionOptionsFailure,
  }) : this._(
         SalesProdutoTendenciaReloadOutcomeKind.failure,
         loadFailure: loadFailure,
         dimensionOptionsFailure: dimensionOptionsFailure,
       );

  const SalesProdutoTendenciaReloadOutcome.cancelled()
    : this._(SalesProdutoTendenciaReloadOutcomeKind.cancelled);

  const SalesProdutoTendenciaReloadOutcome.superseded()
    : this._(SalesProdutoTendenciaReloadOutcomeKind.superseded);

  final SalesProdutoTendenciaReloadOutcomeKind kind;
  final AppFailure? loadFailure;
  final AppFailure? dimensionOptionsFailure;

  bool get isSuccess => kind == SalesProdutoTendenciaReloadOutcomeKind.success;

  bool get isFailure => kind == SalesProdutoTendenciaReloadOutcomeKind.failure;

  bool get isCancelled =>
      kind == SalesProdutoTendenciaReloadOutcomeKind.cancelled;

  bool get isSuperseded =>
      kind == SalesProdutoTendenciaReloadOutcomeKind.superseded;
}

class SalesProdutoTendenciaController extends ChangeNotifier {
  SalesProdutoTendenciaController({
    required SalesSessionService sessionService,
    required LoadAvailableAgentsForSales loadSalesAvailableAgentsUseCase,
    required ResolveSalesAgentClientTokenUseCase resolveSalesAgentClientTokenUseCase,
    required LoadProdutoVendidoTendenciaDeVendaScreenUseCase loadTrendScreenUseCase,
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

  static const String cardFilterId = SalesAutoRefreshCardIds.produtoTendencia;
  static const List<int> pageSizeOptions = <int>[10, 20, 50, 100];

  final SalesSessionService _sessionService;
  final LoadAvailableAgentsForSales _loadAgentsUseCase;
  final ResolveSalesAgentClientTokenUseCase _resolveClientTokenUseCase;
  final LoadProdutoVendidoTendenciaDeVendaScreenUseCase _loadTrendScreen;
  final LoadGrupoMarcaProdutoOptionsUseCase _loadGrupoMarcaOptions;
  final AgentQueriesRelayCancelScopeBinder? _relayCancelScopeBinder;

  SalesProdutoTendenciaPresentationState _state;
  String? _boundUserId;
  String? _selectedAgentId;
  int _sqlLoadGeneration = 0;
  AgentQueriesCancelScope? _sqlCancelScope;
  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;
  bool _disposed = false;

  SalesProdutoTendenciaPresentationState get state => _state;

  static SalesProdutoTendenciaPresentationState _restoreInitialState(
    SalesSessionService sessionService,
  ) {
    final now = DateTime.now();
    final restored = sessionService.restoreCardFilters(cardFilterId);
    final periodoAtual =
        _restoreDateRange(
          restored,
          startKey: 'periodo_atual_start_ms',
          endKey: 'periodo_atual_end_ms',
        ) ??
        salesTrendFullMonthInclusiveRange(now);
    final periodoAnterior =
        _restoreDateRange(
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
    final codGrupoProduto = _restorePositiveInt(restored['cod_grupo_produto']);
    final codMarca = _restorePositiveInt(restored['cod_marca']);
    final restoredPageSize = _restorePositiveInt(restored['page_size']);
    final pageSize =
        restoredPageSize != null && pageSizeOptions.contains(restoredPageSize)
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

  Future<SalesProdutoTendenciaReloadOutcome> reload() => _performReload();

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
    final nextGrupo = _restorePositiveInt(next['codGrupoProduto']);
    final nextMarca = _restorePositiveInt(next['codMarca']);
    final nextPageSize = _restorePositiveInt(next['pageSize']) ?? _state.pageSize;

    final optionsLoadedForAgentId = _state.optionsLoadedForAgentId;
    final agentChanged = optionsLoadedForAgentId != normalizedAgentId;

    _selectedAgentId = normalizedAgentId;
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
        pageSize: pageSizeOptions.contains(nextPageSize)
            ? nextPageSize
            : _state.pageSize,
        page: 1,
        grupoOptions: agentChanged
            ? const <GrupoProdutoOption>[]
            : _state.grupoOptions,
        marcaOptions: agentChanged
            ? const <MarcaProdutoOption>[]
            : _state.marcaOptions,
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
        topGainers: const <ProdutoVendidoTendenciaDeVendaRow>[],
        topLosers: const <ProdutoVendidoTendenciaDeVendaRow>[],
      ),
    );
    await reload();
  }

  Future<SalesProdutoTendenciaReloadOutcome> retryDimensionOptionsLoad() async {
    final userId = _boundUserId;
    final agentId = _state.selectedAgentId?.trim();
    if (userId == null || agentId == null || agentId.isEmpty) {
      return const SalesProdutoTendenciaReloadOutcome.cancelled();
    }
    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: agentId,
    );
    if (_disposed || clientToken == null) {
      return const SalesProdutoTendenciaReloadOutcome.cancelled();
    }
    final failure = await _loadDimensionOptions(
      userId: userId,
      agentId: agentId,
      clientToken: clientToken,
      generation: _sqlLoadGeneration,
      cancelScope: _sqlCancelScope,
    );
    if (_disposed) {
      return const SalesProdutoTendenciaReloadOutcome.superseded();
    }
    return failure == null
        ? const SalesProdutoTendenciaReloadOutcome.success()
        : SalesProdutoTendenciaReloadOutcome.failure(
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

  Future<SalesProdutoTendenciaReloadOutcome> _performReload() async {
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
        return const SalesProdutoTendenciaReloadOutcome.superseded();
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
      return const SalesProdutoTendenciaReloadOutcome.cancelled();
    }

    final trimmedAgentId = agentId.trim();
    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: trimmedAgentId,
    );
    if (_disposed || generation != _sqlLoadGeneration) {
      return const SalesProdutoTendenciaReloadOutcome.superseded();
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
      return const SalesProdutoTendenciaReloadOutcome.cancelled();
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
        return const SalesProdutoTendenciaReloadOutcome.superseded();
      }
    }

    final detailFilter = ProdutoVendidoTendenciaDeVendaFilter(
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
    final screenResult = await _loadTrendScreen(
      userId: userId,
      agentId: trimmedAgentId,
      pageFilter: detailFilter,
      summaryFilter: detailFilter,
      clientToken: clientToken,
      cancelScope: sqlScope,
    );

    if (_disposed || generation != _sqlLoadGeneration) {
      return const SalesProdutoTendenciaReloadOutcome.superseded();
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
        return SalesProdutoTendenciaReloadOutcome.success(
          dimensionOptionsFailure: dimensionOptionsFailure,
        );
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
        return SalesProdutoTendenciaReloadOutcome.failure(
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
        optionsFailure ??= failure;
        return const <GrupoProdutoOption>[];
      },
    );
    final nextMarcas = batchResult.fold(
      (batch) => batch.marcaOptions,
      (failure) {
        optionsFailure ??= failure;
        return const <MarcaProdutoOption>[];
      },
    );

    _setState(
      _state.copyWith(
        grupoOptions: nextGrupos,
        marcaOptions: nextMarcas,
        optionsLoadedForAgentId: agentId,
        dimensionOptionsLoadFailure: optionsFailure,
      ),
    );
    return optionsFailure;
  }

  Future<void> _persistFilters() {
    return _sessionService.persistCardFilters(cardFilterId, <String, Object?>{
      'periodo_atual_start_ms': _state.periodoAtual.start.millisecondsSinceEpoch,
      'periodo_atual_end_ms': _state.periodoAtual.end.millisecondsSinceEpoch,
      'periodo_anterior_start_ms':
          _state.periodoAnterior.start.millisecondsSinceEpoch,
      'periodo_anterior_end_ms':
          _state.periodoAnterior.end.millisecondsSinceEpoch,
      'search_term': _state.searchTerm,
      'classificacao': _state.classificacao,
      'cod_grupo_produto': _state.codGrupoProduto,
      'cod_marca': _state.codMarca,
      'page_size': _state.pageSize,
    });
  }

  void _setState(SalesProdutoTendenciaPresentationState nextState) {
    if (_disposed || _state == nextState) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }

  static DateTimeRange? _restoreDateRange(
    Map<String, Object?> source, {
    required String startKey,
    required String endKey,
  }) {
    final start = source[startKey];
    final end = source[endKey];
    if (start is! int || end is! int) {
      return null;
    }
    final range = DateTimeRange(
      start: DateTime.fromMillisecondsSinceEpoch(start),
      end: DateTime.fromMillisecondsSinceEpoch(end),
    );
    return range.end.isBefore(range.start) ? null : range;
  }

  static int? _restorePositiveInt(Object? raw) {
    if (raw is! int || raw <= 0) {
      return null;
    }
    return raw;
  }
}
