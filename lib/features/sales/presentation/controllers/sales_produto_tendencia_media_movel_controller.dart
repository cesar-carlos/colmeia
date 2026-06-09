import 'dart:async';

import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_page_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_trend_controller_base.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_trend_reload_outcome.dart';
import 'package:colmeia/features/sales/presentation/state/sales_produto_tendencia_media_movel_presentation_state.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';

export 'package:colmeia/features/sales/presentation/controllers/sales_trend_reload_outcome.dart'
    show SalesProdutoTendenciaMediaMovelReloadOutcome;

class SalesProdutoTendenciaMediaMovelController
    extends SalesTrendControllerBase {
  SalesProdutoTendenciaMediaMovelController({
    required super.sessionService,
    required super.loadSalesAvailableAgentsUseCase,
    required super.resolveSalesAgentClientTokenUseCase,
    required LoadProdutoVendidoTendenciaDeVendaMediaMovelScreenUseCase
    loadTrendScreenUseCase,
    required LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase
    loadTrendPageUseCase,
    super.relayCancelScopeBinder,
  }) : _sessionService = sessionService,
       _loadTrendScreen = loadTrendScreenUseCase,
       _loadTrendPage = loadTrendPageUseCase,
       _state = _restoreInitialState(sessionService) {
    selectedAgentId = _state.selectedAgentId;
  }

  static const String cardFilterId =
      SalesAutoRefreshCardIds.produtoTendenciaMediaMovel;

  final SalesSessionService _sessionService;
  final LoadProdutoVendidoTendenciaDeVendaMediaMovelScreenUseCase
  _loadTrendScreen;
  final LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase _loadTrendPage;

  SalesProdutoTendenciaMediaMovelPresentationState _state;

  SalesProdutoTendenciaMediaMovelPresentationState get state => _state;

  @override
  String? get trendSelectedAgentId => _state.selectedAgentId;

  static SalesProdutoTendenciaMediaMovelPresentationState _restoreInitialState(
    SalesSessionService sessionService,
  ) {
    final restored = sessionService.restoreCardFilters(cardFilterId);
    final quantidadeDias =
        SalesTrendControllerBase.restorePositiveInt(
          restored['quantidade_dias'],
        )?.clamp(
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

    final restoredSortByName = (restored['sort_by'] as String?)?.trim();
    final sortBy = ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.values
        .firstWhere(
          (value) => value.name == restoredSortByName,
          orElse: () => ProdutoVendidoTendenciaDeVendaMediaMovelSortBy
              .tendenciaPercentualDesc,
        );

    final restoredPageSize = SalesTrendControllerBase.restorePositiveInt(
      restored['page_size'],
    );
    final pageSize =
        restoredPageSize != null &&
            SalesTrendControllerBase.pageSizeOptions.contains(restoredPageSize)
        ? restoredPageSize
        : ProdutoVendidoTendenciaDeVendaMediaMovelFilter.defaultPageSize;

    return SalesProdutoTendenciaMediaMovelPresentationState(
      selectedAgentId: sessionService.selectedAgentId,
      quantidadeDias: quantidadeDias,
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
      sortBy: sortBy,
      pageSize: pageSize,
    );
  }

  Future<SalesTrendReloadOutcome> reload() => performFullReload();

  Future<void> changeAgent(String agentId) async {
    selectedAgentId = agentId;
    _setState(
      _state.copyWith(
        selectedAgentId: agentId,
        page: 1,
        grupoProdutoLabel: null,
        marcaProdutoLabel: null,
        codGrupoProduto: null,
        codMarca: null,
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
    final nextGrupo = SalesTrendControllerBase.restorePositiveInt(
      next['codGrupoProduto'],
    );
    final nextMarca = SalesTrendControllerBase.restorePositiveInt(
      next['codMarca'],
    );
    final nextGrupoLabel = (next['grupoProdutoLabel'] as String?)?.trim();
    final nextMarcaLabel = (next['marcaProdutoLabel'] as String?)?.trim();
    final nextSortByName = next['sortBy'] as String?;
    final nextSortBy = ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.values
        .firstWhere(
          (value) => value.name == nextSortByName,
          orElse: () => _state.sortBy,
        );
    final nextPageSize =
        SalesTrendControllerBase.restorePositiveInt(next['pageSize']) ??
        _state.pageSize;

    final agentChanged = _state.selectedAgentId != normalizedAgentId;

    selectedAgentId = normalizedAgentId;
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
        codMarca: nextMarca,
        grupoProdutoLabel: agentChanged || nextGrupo == null
            ? (nextGrupo == null ? null : nextGrupoLabel)
            : (nextGrupoLabel ?? _state.grupoProdutoLabel),
        marcaProdutoLabel: agentChanged || nextMarca == null
            ? (nextMarca == null ? null : nextMarcaLabel)
            : (nextMarcaLabel ?? _state.marcaProdutoLabel),
        sortBy: nextSortBy,
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
    final totalPages = _state.pageResult.totalCount == 0
        ? 0
        : (_state.pageResult.totalCount / _state.pageSize).ceil();
    if (page > totalPages) {
      return;
    }
    _setState(_state.copyWith(page: page));
    await reloadDetailsOnly();
  }

  Future<SalesTrendReloadOutcome> reloadDetailsOnly() =>
      performDetailsOnlyReload();

  ProdutoVendidoTendenciaDeVendaMediaMovelFilter shareDetailFilter() {
    return _detailFilter();
  }

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
      return const SalesTrendReloadOutcome.cancelled();
    }

    final screenResult = await _loadTrendScreen(
      userId: userId,
      agentId: trimmedAgentId,
      filter: _detailFilter(),
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
            pageResult: data.page,
            summaryRows: data.summaryRows,
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
            pageResult:
                const ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
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
            pageResult: page,
            loading: false,
            loadFailure: null,
          ),
        );
        return const SalesTrendReloadOutcome.success();
      },
      (failure) {
        _setState(
          _state.copyWith(
            pageResult: ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
              items: const <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
              totalCount: _state.pageResult.totalCount,
            ),
            loading: false,
            loadFailure: failure,
          ),
        );
        return SalesTrendReloadOutcome.failure(loadFailure: failure);
      },
    );
  }

  ProdutoVendidoTendenciaDeVendaMediaMovelFilter _detailFilter() {
    return ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
      quantidadeDias: _state.quantidadeDias,
      searchTerm: _state.searchTerm,
      classificacao: _state.classificacao,
      codGrupoProduto: _state.codGrupoProduto,
      codMarca: _state.codMarca,
      sortBy: _state.sortBy,
      page: _state.page,
      pageSize: _state.pageSize,
    );
  }

  Future<void> _persistFilters() {
    return _sessionService.persistCardFilters(cardFilterId, <String, Object?>{
      'quantidade_dias': _state.quantidadeDias,
      'search_term': _state.searchTerm,
      'classificacao': _state.classificacao,
      'cod_grupo_produto': _state.codGrupoProduto,
      'cod_marca': _state.codMarca,
      'grupo_produto_label': _state.grupoProdutoLabel,
      'marca_produto_label': _state.marcaProdutoLabel,
      'sort_by': _state.sortBy.name,
      'page_size': _state.pageSize,
    });
  }

  void _setState(SalesProdutoTendenciaMediaMovelPresentationState nextState) {
    if (isDisposed || _state == nextState) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }
}
