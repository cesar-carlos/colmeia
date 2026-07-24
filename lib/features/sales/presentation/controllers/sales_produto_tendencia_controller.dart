import 'dart:async';

import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_classificacao.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_filter_limits.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_metric_mode.dart';
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
        salesTrendMonthToDateInclusiveRange(now);
    final periodoAnterior =
        SalesTrendControllerBase.restoreDateRange(
          restored,
          startKey: 'periodo_anterior_start_ms',
          endKey: 'periodo_anterior_end_ms',
        ) ??
        salesTrendAutoPreviousRange(periodoAtual);
    final searchTerm = (restored['search_term'] as String?)?.trim() ?? '';
    final classificacao = SalesTrendClassificacao.normalize(
      restored['classificacao'] as String?,
    );
    final codGrupoProduto = SalesTrendControllerBase.restorePositiveInt(
      restored['cod_grupo_produto'],
    );
    final codMarca = SalesTrendControllerBase.restorePositiveInt(
      restored['cod_marca'],
    );
    final codFilial = SalesTrendControllerBase.restorePositiveInt(
      restored['cod_filial'],
    );
    final restoredGrupoLabel = (restored['grupo_produto_label'] as String?)
        ?.trim();
    final restoredMarcaLabel = (restored['marca_produto_label'] as String?)
        ?.trim();
    final restoredFilialLabel = (restored['filial_label'] as String?)?.trim();
    final metricMode = SalesTrendFilterLimits.metricModeFromName(
      restored['metric_mode'] as String?,
    );
    final restoredMinVolume = SalesTrendControllerBase.restorePositiveInt(
      restored['min_volume_units'],
    );
    final minVolumeUnits =
        restoredMinVolume != null &&
            SalesTrendFilterLimits.validateMinVolumeUnits(restoredMinVolume) ==
                null
        ? restoredMinVolume
        : SalesTrendFilterLimits.defaultMinVolumeUnits;
    final restoredThreshold = restored['trend_threshold_percent'];
    final parsedThreshold = restoredThreshold is num
        ? restoredThreshold.toDouble()
        : null;
    final trendThresholdPercent =
        parsedThreshold != null &&
            SalesTrendFilterLimits.validateTrendThresholdPercent(
                  parsedThreshold,
                ) ==
                null
        ? parsedThreshold
        : SalesTrendFilterLimits.defaultTrendThresholdPercent;
    final topMoversSortBy = SalesTrendFilterLimits.topMoversSortFromName(
      restored['top_movers_sort_by'] as String?,
    );
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
      codFilial: codFilial,
      metricMode: metricMode,
      minVolumeUnits: minVolumeUnits,
      trendThresholdPercent: trendThresholdPercent,
      topMoversSortBy: topMoversSortBy,
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
      filialLabel:
          codFilial != null &&
              restoredFilialLabel != null &&
              restoredFilialLabel.isNotEmpty
          ? restoredFilialLabel
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
    final nextClassificacao = SalesTrendClassificacao.normalize(
      next['classificacao'] as String?,
    );
    final nextGrupo = SalesTrendControllerBase.restorePositiveInt(
      next['codGrupoProduto'],
    );
    final nextMarca = SalesTrendControllerBase.restorePositiveInt(
      next['codMarca'],
    );
    final nextFilial = SalesTrendControllerBase.restorePositiveInt(
      next['codFilial'],
    );
    final nextGrupoLabel = (next['grupoProdutoLabel'] as String?)?.trim();
    final nextMarcaLabel = (next['marcaProdutoLabel'] as String?)?.trim();
    final nextFilialLabel = (next['filialLabel'] as String?)?.trim();
    final nextMetricMode = next['metricMode'] is SalesTrendMetricMode
        ? next['metricMode']! as SalesTrendMetricMode
        : SalesTrendFilterLimits.metricModeFromName(
            next['metricMode'] as String?,
          );
    final nextMinVolume =
        SalesTrendControllerBase.restorePositiveInt(next['minVolumeUnits']) ??
        _state.minVolumeUnits;
    final nextThresholdRaw = next['trendThresholdPercent'];
    final nextThreshold = nextThresholdRaw is num
        ? nextThresholdRaw.toDouble()
        : _state.trendThresholdPercent;
    final nextTopMoversSort =
        next['topMoversSortBy'] is SalesTrendTopMoversSortBy
        ? next['topMoversSortBy']! as SalesTrendTopMoversSortBy
        : SalesTrendFilterLimits.topMoversSortFromName(
            next['topMoversSortBy'] as String?,
          );
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
        classificacao: nextClassificacao,
        codGrupoProduto: nextGrupo,
        codMarca: nextMarca,
        codFilial: nextFilial,
        metricMode: nextMetricMode,
        minVolumeUnits:
            SalesTrendFilterLimits.validateMinVolumeUnits(nextMinVolume) == null
            ? nextMinVolume
            : _state.minVolumeUnits,
        trendThresholdPercent:
            SalesTrendFilterLimits.validateTrendThresholdPercent(
                  nextThreshold,
                ) ==
                null
            ? nextThreshold
            : _state.trendThresholdPercent,
        topMoversSortBy: nextTopMoversSort,
        grupoProdutoLabel: agentChanged || nextGrupo == null
            ? (nextGrupo == null ? null : nextGrupoLabel)
            : (nextGrupoLabel ?? _state.grupoProdutoLabel),
        marcaProdutoLabel: agentChanged || nextMarca == null
            ? (nextMarca == null ? null : nextMarcaLabel)
            : (nextMarcaLabel ?? _state.marcaProdutoLabel),
        filialLabel: agentChanged || nextFilial == null
            ? (nextFilial == null ? null : nextFilialLabel)
            : (nextFilialLabel ?? _state.filialLabel),
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
    _setState(_state.copyWith(page: page));
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
        detailsLoading: false,
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
          detailsLoading: false,
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
          detailsLoading: false,
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
            detailsLoading: false,
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
            detailsLoading: false,
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
    if (_state.loading) {
      return const SalesTrendReloadOutcome.cancelled();
    }
    final userId = boundUserId;
    final agentId = _state.selectedAgentId;
    final (:generation, :scope) = beginSqlLoad();

    _setState(
      _state.copyWith(
        detailsLoading: true,
        loadFailure: null,
      ),
    );

    if (userId == null || agentId == null || agentId.trim().isEmpty) {
      if (isSuperseded(generation)) {
        return const SalesTrendReloadOutcome.superseded();
      }
      _setState(_state.copyWith(detailsLoading: false));
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
          detailsLoading: false,
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
            detailsLoading: false,
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
            detailsLoading: false,
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
      codFilial: _state.codFilial,
      metricMode: _state.metricMode,
      minVolumeUnits: _state.minVolumeUnits,
      trendThresholdPercent: _state.trendThresholdPercent,
      topMoversSortBy: _state.topMoversSortBy,
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
      'cod_filial': _state.codFilial,
      'grupo_produto_label': _state.grupoProdutoLabel,
      'marca_produto_label': _state.marcaProdutoLabel,
      'filial_label': _state.filialLabel,
      'metric_mode': _state.metricMode.name,
      'min_volume_units': _state.minVolumeUnits,
      'trend_threshold_percent': _state.trendThresholdPercent,
      'top_movers_sort_by': _state.topMoversSortBy.name,
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
