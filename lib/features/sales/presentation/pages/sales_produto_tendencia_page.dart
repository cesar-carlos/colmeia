import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_grupo_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_marca_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/marca_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_available_agents_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_single_agent_auto_refresh_mixin.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_actions_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_trend_comparison_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:colmeia/shared/widgets/forms/app_choice_chip.dart';
import 'package:colmeia/shared/widgets/forms/app_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

List<ProdutoVendidoTendenciaDeVendaRow> _trendTopGainersRows(
  List<ProdutoVendidoTendenciaDeVendaRow> rows,
) {
  final values =
      rows.where((r) => r.percentualTendencia > 0).toList(growable: false)
        ..sort((a, b) {
          final byPercent = b.percentualTendencia.compareTo(
            a.percentualTendencia,
          );
          if (byPercent != 0) {
            return byPercent;
          }
          return b.diferenca.compareTo(a.diferenca);
        });
  return values.take(5).toList(growable: false);
}

List<ProdutoVendidoTendenciaDeVendaRow> _trendTopLosersRows(
  List<ProdutoVendidoTendenciaDeVendaRow> rows,
) {
  final values =
      rows.where((r) => r.percentualTendencia < 0).toList(growable: false)
        ..sort((a, b) {
          final byPercent = a.percentualTendencia.compareTo(
            b.percentualTendencia,
          );
          if (byPercent != 0) {
            return byPercent;
          }
          return a.diferenca.compareTo(b.diferenca);
        });
  return values.take(5).toList(growable: false);
}

enum _SalesTrendDatePreset {
  currentMonth,
  previousMonth,
  last7Days,
  last30Days,
}

DateTime _salesTrendCalendarDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTimeRange _salesTrendFullMonthInclusiveRange(DateTime anchor) {
  return DateTimeRange(
    start: DateTime(anchor.year, anchor.month),
    end: DateTime(anchor.year, anchor.month + 1, 0),
  );
}

DateTimeRange _salesTrendPreviousMonthInclusiveRange(DateTime anchor) {
  final previous = DateTime(anchor.year, anchor.month - 1);
  return DateTimeRange(
    start: DateTime(previous.year, previous.month),
    end: DateTime(previous.year, previous.month + 1, 0),
  );
}

DateTimeRange _salesTrendCurrentRangeForPreset(
  _SalesTrendDatePreset preset, {
  DateTime? anchor,
}) {
  final today = _salesTrendCalendarDate(anchor ?? DateTime.now());
  return switch (preset) {
    _SalesTrendDatePreset.currentMonth => _salesTrendFullMonthInclusiveRange(
      today,
    ),
    _SalesTrendDatePreset.previousMonth =>
      _salesTrendPreviousMonthInclusiveRange(today),
    _SalesTrendDatePreset.last7Days => DateTimeRange(
      start: today.subtract(const Duration(days: 6)),
      end: today,
    ),
    _SalesTrendDatePreset.last30Days => DateTimeRange(
      start: today.subtract(const Duration(days: 29)),
      end: today,
    ),
  };
}

bool _salesTrendIsWholeCalendarMonthRange(DateTimeRange range) {
  final normalizedStart = _salesTrendCalendarDate(range.start);
  final normalizedEnd = _salesTrendCalendarDate(range.end);
  return normalizedStart.day == 1 &&
      normalizedEnd.day ==
          DateTime(
            normalizedEnd.year,
            normalizedEnd.month + 1,
            0,
          ).day;
}

int _salesTrendInclusiveDayCount(DateTimeRange range) {
  final normalizedStart = _salesTrendCalendarDate(range.start);
  final normalizedEnd = _salesTrendCalendarDate(range.end);
  return normalizedEnd.difference(normalizedStart).inDays + 1;
}

int _salesTrendCalendarMonthSpan(DateTimeRange range) {
  final normalizedStart = _salesTrendCalendarDate(range.start);
  final normalizedEnd = _salesTrendCalendarDate(range.end);
  return (normalizedEnd.year - normalizedStart.year) * 12 +
      normalizedEnd.month -
      normalizedStart.month +
      1;
}

DateTimeRange _salesTrendAutoPreviousRange(DateTimeRange currentRange) {
  final normalizedStart = _salesTrendCalendarDate(currentRange.start);
  if (_salesTrendIsWholeCalendarMonthRange(currentRange)) {
    final monthSpan = _salesTrendCalendarMonthSpan(currentRange);
    return DateTimeRange(
      start: DateTime(
        normalizedStart.year,
        normalizedStart.month - monthSpan,
      ),
      end: DateTime(normalizedStart.year, normalizedStart.month, 0),
    );
  }

  final inclusiveDays = _salesTrendInclusiveDayCount(currentRange);
  final previousEnd = normalizedStart.subtract(const Duration(days: 1));
  final previousStart = previousEnd.subtract(
    Duration(days: inclusiveDays - 1),
  );
  return DateTimeRange(start: previousStart, end: previousEnd);
}

bool _salesTrendSameRange(DateTimeRange? a, DateTimeRange? b) {
  if (a == null || b == null) {
    return a == b;
  }
  return _salesTrendCalendarDate(a.start) == _salesTrendCalendarDate(b.start) &&
      _salesTrendCalendarDate(a.end) == _salesTrendCalendarDate(b.end);
}

String _salesTrendRangeDescriptorLabel(
  AppLocalizations l10n,
  DateTimeRange range,
) {
  final durationLabel = l10n.salesProdutoTendenciaFilterDurationDays(
    _salesTrendInclusiveDayCount(range),
  );
  final rangeKind = _salesTrendIsWholeCalendarMonthRange(range)
      ? l10n.salesProdutoTendenciaFilterRangeKindFullMonth
      : l10n.salesProdutoTendenciaFilterRangeKindCustom;
  return '$durationLabel • $rangeKind';
}

class SalesProdutoTendenciaPage extends StatefulWidget {
  const SalesProdutoTendenciaPage({
    required this.sessionService,
    required this.loadSalesAvailableAgentsUseCase,
    required this.resolveSalesAgentClientTokenUseCase,
    required this.loadTrendScreenUseCase,
    required this.loadGrupoProdutoOptionsUseCase,
    required this.loadMarcaProdutoOptionsUseCase,
    super.key,
  });

  final SalesSessionService sessionService;
  final LoadSalesAvailableAgentsUseCase loadSalesAvailableAgentsUseCase;
  final ResolveSalesAgentClientTokenUseCase resolveSalesAgentClientTokenUseCase;
  final LoadProdutoVendidoTendenciaDeVendaScreenUseCase loadTrendScreenUseCase;
  final LoadGrupoProdutoOptionsUseCase loadGrupoProdutoOptionsUseCase;
  final LoadMarcaProdutoOptionsUseCase loadMarcaProdutoOptionsUseCase;

  @override
  State<SalesProdutoTendenciaPage> createState() =>
      _SalesProdutoTendenciaPageState();
}

class _SalesProdutoTendenciaPageState extends State<SalesProdutoTendenciaPage>
    with
        AutoRefreshStateMixin<SalesProdutoTendenciaPage>,
        SalesSingleAgentAutoRefreshMixin<SalesProdutoTendenciaPage>,
        SalesCardAutoRefreshBinding<SalesProdutoTendenciaPage> {
  static const String _cardId = 'produto_tendencia_venda';
  static const List<int> _pageSizeOptions = <int>[10, 20, 50, 100];

  late final SalesSessionService _sessionService;
  late final ResolveSalesAgentClientTokenUseCase _resolveClientTokenUseCase;
  late final LoadSalesAvailableAgentsUseCase _loadAgentsUseCase;
  late final LoadProdutoVendidoTendenciaDeVendaScreenUseCase _loadTrendScreen;
  late final LoadGrupoProdutoOptionsUseCase _loadGrupoOptions;
  late final LoadMarcaProdutoOptionsUseCase _loadMarcaOptions;

  String? _selectedAgentId;
  List<OverviewAgentOption> _availableAgents = <OverviewAgentOption>[];
  List<GrupoProdutoOption> _grupoOptions = const <GrupoProdutoOption>[];
  List<MarcaProdutoOption> _marcaOptions = const <MarcaProdutoOption>[];
  String? _optionsLoadedForAgentId;

  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;

  late DateTimeRange _periodoAtual;
  late DateTimeRange _periodoAnterior;
  String _searchTerm = '';
  String? _classificacao;
  int? _codGrupoProduto;
  int? _codMarca;
  int _page = 1;
  int _pageSize = ProdutoVendidoTendenciaDeVendaFilter.defaultPageSize;

  bool _loading = false;
  String? _error;
  List<ProdutoVendidoTendenciaDeVendaRow> _rows =
      const <ProdutoVendidoTendenciaDeVendaRow>[];
  List<ProdutoVendidoTendenciaDeVendaSummaryRow> _summaryRows =
      const <ProdutoVendidoTendenciaDeVendaSummaryRow>[];

  DateTimeRange _fullMonthInclusiveRange(DateTime anchor) =>
      _salesTrendFullMonthInclusiveRange(anchor);

  DateTimeRange _previousMonthInclusiveRange(DateTime anchor) =>
      _salesTrendPreviousMonthInclusiveRange(anchor);

  @override
  void initState() {
    super.initState();
    _sessionService = widget.sessionService;
    _resolveClientTokenUseCase = widget.resolveSalesAgentClientTokenUseCase;
    _loadAgentsUseCase = widget.loadSalesAvailableAgentsUseCase;
    _loadTrendScreen = widget.loadTrendScreenUseCase;
    _loadGrupoOptions = widget.loadGrupoProdutoOptionsUseCase;
    _loadMarcaOptions = widget.loadMarcaProdutoOptionsUseCase;
    _selectedAgentId = _sessionService.selectedAgentId;

    final now = DateTime.now();
    final restored = _sessionService.restoreCardFilters(_cardId);
    _periodoAtual =
        _restoreDateRange(
          restored,
          startKey: 'periodo_atual_start_ms',
          endKey: 'periodo_atual_end_ms',
        ) ??
        _fullMonthInclusiveRange(now);
    _periodoAnterior =
        _restoreDateRange(
          restored,
          startKey: 'periodo_anterior_start_ms',
          endKey: 'periodo_anterior_end_ms',
        ) ??
        _previousMonthInclusiveRange(now);
    _searchTerm = (restored['search_term'] as String?)?.trim() ?? '';

    final restoredClassificacao = (restored['classificacao'] as String?)
        ?.trim()
        .toUpperCase();
    _classificacao =
        ProdutoVendidoTendenciaDeVendaFilter.allowedClassificacoes.contains(
          restoredClassificacao,
        )
        ? restoredClassificacao
        : null;
    _codGrupoProduto = _restorePositiveInt(restored['cod_grupo_produto']);
    _codMarca = _restorePositiveInt(restored['cod_marca']);
    final restoredPageSize = _restorePositiveInt(restored['page_size']);
    if (restoredPageSize != null &&
        _pageSizeOptions.contains(restoredPageSize)) {
      _pageSize = restoredPageSize;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadAgents());
    });
  }

  Future<void> _loadAgents() async {
    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    if (userId == null) {
      return;
    }

    final agents = await _loadAgentsUseCase(userId);
    if (!mounted) {
      return;
    }

    final authAfter = context.read<AuthController>();
    if (authAfter.session?.userId != userId) {
      return;
    }

    final nextSelection = reconcileSelectedSalesAgentId(
      agents: agents,
      previousSelectedId: _selectedAgentId,
    );
    setState(() {
      _availableAgents = agents;
      _selectedAgentId = nextSelection;
    });
    if (nextSelection != _sessionService.selectedAgentId) {
      unawaited(_sessionService.setSelectedAgentId(nextSelection));
    }
    unawaited(_reload());
  }

  Future<void> _reload() => reloadWithAutoRefresh();

  @override
  SalesSessionService get salesSessionService => _sessionService;

  @override
  String get salesAutoRefreshCardId => SalesAutoRefreshCardIds.produtoTendencia;

  @override
  String? get autoRefreshSelectedAgentId => _selectedAgentId;

  @override
  List<OverviewAgentOption> get autoRefreshAvailableAgents => _availableAgents;

  @override
  bool get autoRefreshPageLoading => _loading;

  @override
  Future<void> performAutoRefreshReload() async {
    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    final agentId = _selectedAgentId;
    markAutoRefreshCancelled();

    setState(() {
      _loading = true;
      _error = null;
    });

    if (userId == null || agentId == null || agentId.trim().isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _rows = const <ProdutoVendidoTendenciaDeVendaRow>[];
        _summaryRows = const <ProdutoVendidoTendenciaDeVendaSummaryRow>[];
        _error = null;
      });
      return;
    }

    final trimmedAgentId = agentId.trim();
    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: trimmedAgentId,
    );
    if (!mounted) {
      return;
    }
    if (clientToken == null) {
      setState(() {
        _loading = false;
        _rows = const <ProdutoVendidoTendenciaDeVendaRow>[];
        _summaryRows = const <ProdutoVendidoTendenciaDeVendaSummaryRow>[];
        _error = AppLocalizations.of(context).agentSqlErrorAuthenticationFailed;
      });
      markAutoRefreshCancelled();
      return;
    }

    if (_optionsLoadedForAgentId != trimmedAgentId) {
      await _loadDimensionOptions(
        userId: userId,
        agentId: trimmedAgentId,
        clientToken: clientToken,
      );
      if (!mounted) {
        return;
      }
    }

    final detailFilter = ProdutoVendidoTendenciaDeVendaFilter(
      periodoAtualInicio: _periodoAtual.start,
      periodoAtualFim: _periodoAtual.end,
      periodoAnteriorInicio: _periodoAnterior.start,
      periodoAnteriorFim: _periodoAnterior.end,
      searchTerm: _searchTerm,
      classificacao: _classificacao,
      codGrupoProduto: _codGrupoProduto,
      codMarca: _codMarca,
      page: _page,
      pageSize: _pageSize,
    );
    final summaryFilter = ProdutoVendidoTendenciaDeVendaFilter(
      periodoAtualInicio: _periodoAtual.start,
      periodoAtualFim: _periodoAtual.end,
      periodoAnteriorInicio: _periodoAnterior.start,
      periodoAnteriorFim: _periodoAnterior.end,
    );

    final screenResult = await _loadTrendScreen(
      userId: userId,
      agentId: trimmedAgentId,
      pageFilter: detailFilter,
      summaryFilter: summaryFilter,
      clientToken: clientToken,
    );

    if (!mounted) {
      return;
    }

    screenResult.fold(
      (data) {
        setState(() {
          _rows = data.rows;
          _summaryRows = data.summaryRows;
          _loading = false;
          _error = null;
        });
        markAutoRefreshSuccess();
      },
      (failure) {
        setState(() {
          _rows = const <ProdutoVendidoTendenciaDeVendaRow>[];
          _summaryRows = const <ProdutoVendidoTendenciaDeVendaSummaryRow>[];
          _loading = false;
          _error = _failureMessage(failure);
        });
        markAutoRefreshFailure();
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
    _cachedClientTokenUserId = userId;
    _cachedClientTokenAgentId = agentId;
    return _cachedClientToken = resolved;
  }

  Future<void> _loadDimensionOptions({
    required String userId,
    required String agentId,
    required String clientToken,
  }) async {
    final grupoFuture = _loadGrupoOptions(
      userId: userId,
      agentId: agentId,
      pageSize: 200,
      clientToken: clientToken,
    );
    final marcaFuture = _loadMarcaOptions(
      userId: userId,
      agentId: agentId,
      pageSize: 200,
      clientToken: clientToken,
    );
    final grupoResult = await grupoFuture;
    final marcaResult = await marcaFuture;
    if (!mounted) {
      return;
    }

    final nextGrupos = grupoResult.fold(
      (options) => options,
      (_) => const <GrupoProdutoOption>[],
    );
    final nextMarcas = marcaResult.fold(
      (options) => options,
      (_) => const <MarcaProdutoOption>[],
    );

    setState(() {
      _grupoOptions = nextGrupos;
      _marcaOptions = nextMarcas;
      _optionsLoadedForAgentId = agentId;
    });
  }

  String _failureMessage(Object failure) {
    final err = failure;
    return err is AppFailure ? err.displayMessage : failure.toString();
  }

  void _showFiltersAppliedSnackBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).salesProdutoTendenciaFiltersAppliedSnackbar,
          ),
        ),
      );
    });
  }

  void _openClassificacaoFullscreen() {
    final l10n = AppLocalizations.of(context);
    final buckets = List<_TrendClassBucket>.of(
      _buildSummary(_summaryRows).buckets,
      growable: false,
    );
    unawaited(
      context.pushChartFullscreen<void>(
        extra: AppChartFullscreenRouteExtra(
          title: l10n.salesProdutoTendenciaSummaryByClassificacaoTitle,
          subtitle: l10n.salesProdutoTendenciaSummaryByClassificacaoSubtitle,
          chartSemanticsLabel:
              l10n.salesProdutoTendenciaSummaryByClassificacaoTitle,
          chartBuilder: (fullscreenContext) {
            final ft = Theme.of(
              fullscreenContext,
            ).extension<AppThemeTokens>()!;
            final fl10n = AppLocalizations.of(fullscreenContext);
            return LayoutBuilder(
              builder: (context, constraints) {
                return AppComparisonBarChart<_TrendClassBucket>(
                  items: buckets,
                  labelBuilder: (b) =>
                      _classificacaoLabel(fl10n, b.classificacao),
                  valueBuilder: (b) => b.count,
                  plotFloorAccessibilityNotice:
                      fl10n.chartComparisonPlotFloorNotice,
                  extremeSpreadAccessibilityNotice:
                      fl10n.chartComparisonExtremeValueSpreadNotice,
                  style: salesTrendHomeLikeComparisonBarChartStyle(
                    tokens: ft,
                    l10n: fl10n,
                    yAxisFormat: NumberFormat.decimalPattern(fl10n.localeName),
                    heightOverride: constraints.maxHeight,
                  ),
                  dataLabelBuilder: (bucket, _) =>
                      NumberFormat.decimalPattern(fl10n.localeName).format(
                        bucket.count,
                      ),
                  tooltipLabelBuilder: (bucket, _) =>
                      '${_classificacaoLabel(fl10n, bucket.classificacao)} • '
                      '${bucket.count} • '
                      '${NumberFormat.decimalPattern(fl10n.localeName).format(bucket.impacto.round())}',
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openGainersFullscreen() {
    final snap = List<ProdutoVendidoTendenciaDeVendaRow>.of(
      _trendTopGainersRows(_rows),
      growable: false,
    );
    _pushTopMoversChartFullscreen(
      title: AppLocalizations.of(context).salesProdutoTendenciaTopGainersTitle,
      subtitle: AppLocalizations.of(
        context,
      ).salesProdutoTendenciaTopMoversSubtitle,
      items: snap,
      useAbsolutePercentForLosers: false,
    );
  }

  void _openLosersFullscreen() {
    final snap = List<ProdutoVendidoTendenciaDeVendaRow>.of(
      _trendTopLosersRows(_rows),
      growable: false,
    );
    _pushTopMoversChartFullscreen(
      title: AppLocalizations.of(context).salesProdutoTendenciaTopLosersTitle,
      subtitle: AppLocalizations.of(
        context,
      ).salesProdutoTendenciaTopMoversSubtitle,
      items: snap,
      useAbsolutePercentForLosers: true,
    );
  }

  void _pushTopMoversChartFullscreen({
    required String title,
    required String subtitle,
    required List<ProdutoVendidoTendenciaDeVendaRow> items,
    required bool useAbsolutePercentForLosers,
  }) {
    unawaited(
      context.pushChartFullscreen<void>(
        extra: AppChartFullscreenRouteExtra(
          title: title,
          subtitle: subtitle,
          chartSemanticsLabel: title,
          chartBuilder: (fullscreenContext) {
            final ft = Theme.of(
              fullscreenContext,
            ).extension<AppThemeTokens>()!;
            final fl10n = AppLocalizations.of(fullscreenContext);
            final axisFormat = NumberFormat.decimalPattern(fl10n.localeName);
            return LayoutBuilder(
              builder: (context, constraints) {
                return AppComparisonBarChart<ProdutoVendidoTendenciaDeVendaRow>(
                  items: items,
                  labelBuilder: (row) => row.nomeProduto,
                  valueBuilder: (row) => useAbsolutePercentForLosers
                      ? row.percentualTendencia.abs()
                      : row.percentualTendencia,
                  plotFloorAccessibilityNotice:
                      fl10n.chartComparisonPlotFloorNotice,
                  extremeSpreadAccessibilityNotice:
                      fl10n.chartComparisonExtremeValueSpreadNotice,
                  style: salesTrendHomeLikeComparisonBarChartStyle(
                    tokens: ft,
                    l10n: fl10n,
                    yAxisFormat: axisFormat,
                    minPlottedValueShareOfMax: 0.03,
                    heightOverride: constraints.maxHeight,
                  ),
                  dataLabelBuilder: (row, _) =>
                      '${row.percentualTendencia.toStringAsFixed(1)}%',
                  tooltipLabelBuilder: (row, _) =>
                      '${row.nomeProduto} • '
                      '${row.percentualTendencia.toStringAsFixed(2)}% • '
                      '${NumberFormat.decimalPattern(fl10n.localeName).format(row.diferenca.round())}',
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _onFiltersChanged(Map<String, Object?> next) {
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
    final nextPageSize = _restorePositiveInt(next['pageSize']) ?? _pageSize;

    setState(() {
      _selectedAgentId = normalizedAgentId;
      if (nextAtual != null) {
        _periodoAtual = nextAtual;
      }
      if (nextAnterior != null) {
        _periodoAnterior = nextAnterior;
      }
      _searchTerm = nextSearch;
      _classificacao =
          ProdutoVendidoTendenciaDeVendaFilter.allowedClassificacoes.contains(
            nextClassificacao,
          )
          ? nextClassificacao
          : null;
      _codGrupoProduto = nextGrupo;
      _codMarca = nextMarca;
      _pageSize = _pageSizeOptions.contains(nextPageSize)
          ? nextPageSize
          : _pageSize;
      _page = 1;
      if (_optionsLoadedForAgentId != normalizedAgentId) {
        _grupoOptions = const <GrupoProdutoOption>[];
        _marcaOptions = const <MarcaProdutoOption>[];
      }
      _optionsLoadedForAgentId = normalizedAgentId == _optionsLoadedForAgentId
          ? _optionsLoadedForAgentId
          : null;
    });
    unawaited(_sessionService.setSelectedAgentId(normalizedAgentId));
    unawaited(_persistFilters());
    unawaited(_reload());
    _showFiltersAppliedSnackBar();
  }

  Future<void> _persistFilters() {
    return _sessionService.persistCardFilters(_cardId, <String, Object?>{
      'periodo_atual_start_ms': _periodoAtual.start.millisecondsSinceEpoch,
      'periodo_atual_end_ms': _periodoAtual.end.millisecondsSinceEpoch,
      'periodo_anterior_start_ms':
          _periodoAnterior.start.millisecondsSinceEpoch,
      'periodo_anterior_end_ms': _periodoAnterior.end.millisecondsSinceEpoch,
      'search_term': _searchTerm,
      'classificacao': _classificacao,
      'cod_grupo_produto': _codGrupoProduto,
      'cod_marca': _codMarca,
      'page_size': _pageSize,
    });
  }

  DateTimeRange? _restoreDateRange(
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

  int? _restorePositiveInt(Object? raw) {
    if (raw is! int || raw <= 0) {
      return null;
    }
    return raw;
  }

  Future<void> _openFiltersSheet() async {
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) {
        return _SalesProdutoTendenciaFiltersSheet(
          l10n: AppLocalizations.of(context),
          availableAgents: _availableAgents,
          initialSelectedAgentId: _selectedAgentId,
          initialPeriodoAtual: _periodoAtual,
          initialPeriodoAnterior: _periodoAnterior,
          initialSearchTerm: _searchTerm,
          initialClassificacao: _classificacao,
          initialCodGrupoProduto: _codGrupoProduto,
          initialCodMarca: _codMarca,
          initialPageSize: _pageSize,
          grupoOptions: _grupoOptions,
          marcaOptions: _marcaOptions,
          onApply: _onFiltersChanged,
        );
      },
    );
  }

  void _onPageSizeChanged(int size) {
    if (size == _pageSize) {
      return;
    }
    setState(() {
      _pageSize = size;
      _page = 1;
    });
    unawaited(_persistFilters());
    unawaited(_reload());
  }

  void _onPageSelected(int page) {
    if (page == _page || page < 1) {
      return;
    }
    final hasNextPage = _rows.length >= _pageSize;
    if (page > _page && !hasNextPage) {
      return;
    }
    setState(() => _page = page);
    unawaited(_reload());
  }

  String _dateRangeLabel(DateTimeRange range) {
    return '${AppBrFormatters.shortDateFormat.format(range.start)} – '
        '${AppBrFormatters.shortDateFormat.format(range.end)}';
  }

  String _classificacaoLabel(AppLocalizations l10n, String? value) {
    final raw = value?.trim().toUpperCase();
    return switch (raw) {
      'PAROU DE VENDER' => l10n.salesProdutoTendenciaClassificacaoStopped,
      'NOVO PRODUTO' => l10n.salesProdutoTendenciaClassificacaoNew,
      'CRESCENDO' => l10n.salesProdutoTendenciaClassificacaoGrowing,
      'CAINDO' => l10n.salesProdutoTendenciaClassificacaoFalling,
      'ESTAVEL' => l10n.salesProdutoTendenciaClassificacaoStable,
      _ => l10n.salesProdutoTendenciaFilterAllOption,
    };
  }

  String _periodDescriptorLabel(AppLocalizations l10n, DateTimeRange range) {
    return _salesTrendRangeDescriptorLabel(l10n, range);
  }

  List<String> _activeFilterChipLabels(AppLocalizations l10n) {
    final labels = <String>[];
    final trimmedSearch = _searchTerm.trim();
    if (trimmedSearch.isNotEmpty) {
      labels.add('${l10n.salesProdutoTendenciaFilterSearch}: $trimmedSearch');
    }
    if (_classificacao != null) {
      labels.add(
        '${l10n.salesProdutoTendenciaFilterClassification}: '
        '${_classificacaoLabel(l10n, _classificacao)}',
      );
    }
    if (_codGrupoProduto != null) {
      final grupoLabel =
          _grupoOptions
              .cast<GrupoProdutoOption?>()
              .firstWhere(
                (option) => option?.codGrupoProduto == _codGrupoProduto,
                orElse: () => null,
              )
              ?.nomeGrupoProduto ??
          '#$_codGrupoProduto';
      labels.add('${l10n.salesProdutoTendenciaFilterGroup}: $grupoLabel');
    }
    if (_codMarca != null) {
      final marcaLabel =
          _marcaOptions
              .cast<MarcaProdutoOption?>()
              .firstWhere(
                (option) => option?.codMarca == _codMarca,
                orElse: () => null,
              )
              ?.nomeMarca ??
          '#$_codMarca';
      labels.add('${l10n.salesProdutoTendenciaFilterBrand}: $marcaLabel');
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final selectedBranch = _availableAgents
        .cast<OverviewAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == _selectedAgentId,
          orElse: () => null,
        );
    final selectedBranchName =
        selectedBranch?.name ?? l10n.salesBranchPickerEmpty;
    final activeFilterChipLabels = _activeFilterChipLabels(l10n);
    final activeDetailFilterCount = activeFilterChipLabels.length;

    return RefreshIndicator(
      onRefresh: () async {
        await _reload();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: context.pageScrollPadding(
          tokens,
          horizontalAdjustment:
              AppPageSpacingPresets.dashboardHorizontalAdjustment,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppShellPageIntro(
              sectionLabel: l10n.shellNavSalesLabel,
              onSectionLabelTap: () => context.goTo(AppRoute.sales),
              title: l10n.salesCardProdutoTendenciaTitle,
              subtitle: l10n.salesProdutoTendenciaPageSubtitle,
            ),
            SizedBox(height: tokens.sectionSpacing),
            SalesCardFilterTrigger(
              onTap: () => unawaited(_openFiltersSheet()),
              buttonSemanticsLabel: l10n.reportFiltersButton,
              summaryItems: <SalesCardFilterSummaryItem>[
                SalesCardFilterSummaryItem(
                  label: l10n.salesBranchFilterLabel,
                  value: selectedBranchName,
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.salesProdutoTendenciaFilterCurrentPeriod,
                  value: _dateRangeLabel(_periodoAtual),
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.salesProdutoTendenciaFilterPreviousPeriod,
                  value: _dateRangeLabel(_periodoAnterior),
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.reportFiltersTitle,
                  value: l10n.salesProdutoTendenciaActiveFiltersSummary(
                    activeDetailFilterCount,
                  ),
                ),
              ],
              enabled: !_loading,
            ),
            SizedBox(height: tokens.gapMd),
            SalesAutoRefreshActionsRow(
              value: autoRefreshOption,
              onChanged: setAutoRefreshOption,
              onRefreshNow: () => unawaited(_reload()),
              enabled: canScheduleAutoRefresh,
              lastUpdatedAt: autoRefreshLastUpdatedAt,
              isPaused: autoRefreshIsPaused,
              pauseReason: autoRefreshPauseReason,
              l10n: l10n,
            ),
            if (activeFilterChipLabels.isNotEmpty) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              Wrap(
                spacing: tokens.gapSm,
                runSpacing: tokens.gapSm,
                children: activeFilterChipLabels
                    .map((label) => AppTagChip(label: label))
                    .toList(growable: false),
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            if (_selectedAgentId == null) ...<Widget>[
              AppInlineErrorPanel(
                tone: AppInlinePanelTone.informational,
                title: l10n.salesBranchRequiredTitle,
                message: l10n.salesBranchRequiredMessage,
              ),
            ] else if (_error != null && _error!.trim().isNotEmpty) ...<Widget>[
              AppInlineErrorPanel(
                message: _error!,
                onRetry: () => unawaited(_reload()),
              ),
            ] else ...<Widget>[
              _TrendSummarySection(
                l10n: l10n,
                summaryRows: _summaryRows,
                loading: _loading,
                periodoAtual: _periodoAtual,
                periodoAnterior: _periodoAnterior,
                periodoAtualDescriptor: _periodDescriptorLabel(
                  l10n,
                  _periodoAtual,
                ),
                periodoAnteriorDescriptor: _periodDescriptorLabel(
                  l10n,
                  _periodoAnterior,
                ),
                classLabelBuilder: (value) => _classificacaoLabel(l10n, value),
                onOpenClassificacaoFullscreen: _openClassificacaoFullscreen,
              ),
              SizedBox(height: tokens.sectionSpacing),
              _TrendTopMoversSection(
                l10n: l10n,
                rows: _rows,
                loading: _loading,
                onOpenGainersFullscreen: _openGainersFullscreen,
                onOpenLosersFullscreen: _openLosersFullscreen,
              ),
              SizedBox(height: tokens.sectionSpacing),
              _TrendDetailsSection(
                l10n: l10n,
                rows: _rows,
                loading: _loading,
                currentPage: _page,
                pageSize: _pageSize,
                onPageSelected: _onPageSelected,
                onPageSizeChanged: _onPageSizeChanged,
                classLabelBuilder: (value) => _classificacaoLabel(l10n, value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrendSummarySection extends StatelessWidget {
  const _TrendSummarySection({
    required this.l10n,
    required this.summaryRows,
    required this.loading,
    required this.periodoAtual,
    required this.periodoAnterior,
    required this.periodoAtualDescriptor,
    required this.periodoAnteriorDescriptor,
    required this.classLabelBuilder,
    required this.onOpenClassificacaoFullscreen,
  });

  final AppLocalizations l10n;
  final List<ProdutoVendidoTendenciaDeVendaSummaryRow> summaryRows;
  final bool loading;
  final DateTimeRange periodoAtual;
  final DateTimeRange periodoAnterior;
  final String periodoAtualDescriptor;
  final String periodoAnteriorDescriptor;
  final String Function(String value) classLabelBuilder;
  final VoidCallback onOpenClassificacaoFullscreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final summary = _buildSummary(summaryRows);
    final chartBlockHeight = AppComparisonBarChart.loadingBlockHeight(tokens);

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.salesProdutoTendenciaSummaryTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.gapXs),
          Text(
            l10n.salesProdutoTendenciaSummarySubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.gapMd),
          Wrap(
            spacing: tokens.gapSm,
            runSpacing: tokens.gapSm,
            children: <Widget>[
              AppTagChip(
                icon: Icons.timeline_rounded,
                label:
                    '${l10n.salesProdutoTendenciaComparisonCurrentChip}: '
                    '${AppBrFormatters.shortDate(periodoAtual.start)} - '
                    '${AppBrFormatters.shortDate(periodoAtual.end)} • '
                    '$periodoAtualDescriptor',
              ),
              AppTagChip(
                icon: Icons.history_rounded,
                label:
                    '${l10n.salesProdutoTendenciaComparisonPreviousChip}: '
                    '${AppBrFormatters.shortDate(periodoAnterior.start)} - '
                    '${AppBrFormatters.shortDate(periodoAnterior.end)} • '
                    '$periodoAnteriorDescriptor',
              ),
            ],
          ),
          SizedBox(height: tokens.contentSpacing),
          if (loading && summaryRows.isEmpty)
            AppSkeleton(
              enabled: true,
              loadingSemanticsLabel:
                  l10n.salesProdutoTendenciaLoadingTrendSemantics,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _trendSummaryKpiStrip(
                    context,
                    summary: _buildSummary(
                      const <ProdutoVendidoTendenciaDeVendaSummaryRow>[],
                    ),
                    tokens: tokens,
                    colors: colors,
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  SizedBox(
                    height: chartBlockHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.salesProdutoTendenciaSummaryByClassificacaoTitle,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (summaryRows.isEmpty)
            Text(
              l10n.salesProdutoTendenciaNoData,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else ...<Widget>[
            _trendSummaryKpiStrip(
              context,
              summary: summary,
              tokens: tokens,
              colors: colors,
            ),
            SizedBox(height: tokens.contentSpacing),
            AppComparisonBarChart<_TrendClassBucket>(
              title: l10n.salesProdutoTendenciaSummaryByClassificacaoTitle,
              subtitle:
                  l10n.salesProdutoTendenciaSummaryByClassificacaoSubtitle,
              items: summary.buckets,
              labelBuilder: (bucket) => classLabelBuilder(bucket.classificacao),
              valueBuilder: (bucket) => bucket.count,
              onOpenFullscreen: onOpenClassificacaoFullscreen,
              openFullscreenTooltip: l10n.chartOpenFullscreenTooltip,
              openFullscreenSemanticLabel: l10n.chartOpenFullscreenTooltip,
              plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
              extremeSpreadAccessibilityNotice:
                  l10n.chartComparisonExtremeValueSpreadNotice,
              style: salesTrendHomeLikeComparisonBarChartStyle(
                tokens: tokens,
                l10n: l10n,
                yAxisFormat: NumberFormat.decimalPattern(l10n.localeName),
              ),
              dataLabelBuilder: (bucket, value) =>
                  NumberFormat.decimalPattern(l10n.localeName).format(
                    bucket.count,
                  ),
              tooltipLabelBuilder: (bucket, value) =>
                  '${classLabelBuilder(bucket.classificacao)} • '
                  '${bucket.count} • '
                  '${NumberFormat.decimalPattern(l10n.localeName).format(bucket.impacto.round())}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _trendSummaryKpiStrip(
    BuildContext context, {
    required _TrendSummary summary,
    required AppThemeTokens tokens,
    required AppColors colors,
  }) {
    final locale = l10n.localeName;
    final nf = NumberFormat.decimalPattern(locale);
    final items = <_TrendSummaryKpiItem>[
      _TrendSummaryKpiItem(
        icon: Icons.trending_up_rounded,
        label: l10n.salesProdutoTendenciaKpiGrowing,
        value: nf.format(summary.countGrowing),
        color: colors.tertiary,
      ),
      _TrendSummaryKpiItem(
        icon: Icons.trending_down_rounded,
        label: l10n.salesProdutoTendenciaKpiFalling,
        value: nf.format(summary.countFalling),
        color: colors.error,
      ),
      _TrendSummaryKpiItem(
        icon: Icons.new_releases_outlined,
        label: l10n.salesProdutoTendenciaKpiNewProducts,
        value: nf.format(summary.countNew),
        color: colors.primary,
      ),
      _TrendSummaryKpiItem(
        icon: Icons.pause_circle_outline_rounded,
        label: l10n.salesProdutoTendenciaKpiStopped,
        value: nf.format(summary.countStopped),
        color: colors.onSurfaceVariant,
      ),
      _TrendSummaryKpiItem(
        icon: Icons.balance_rounded,
        label: l10n.salesProdutoTendenciaKpiNetImpact,
        value: nf.format(summary.netImpact),
        color: summary.netImpact >= 0 ? colors.tertiary : colors.error,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const minCardWidth = 176.0;
        final spacing = tokens.gapMd;
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth.isFinite && maxWidth > 0
            ? ((maxWidth + spacing) / (minCardWidth + spacing)).floor().clamp(
                1,
                items.length,
              )
            : items.length;
        final cardWidth = maxWidth.isFinite && maxWidth > 0
            ? (maxWidth - (spacing * (columns - 1))) / columns
            : minCardWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: cardWidth,
                  child: _kpiCard(
                    context,
                    icon: item.icon,
                    label: item.label,
                    value: item.value,
                    color: item.color,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _kpiCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return AppMetricStatCard(
      leading: Icon(icon, color: color),
      label: label,
      value: value,
    );
  }
}

class _TrendSummaryKpiItem {
  const _TrendSummaryKpiItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _TrendTopMoversSection extends StatelessWidget {
  const _TrendTopMoversSection({
    required this.l10n,
    required this.rows,
    required this.loading,
    required this.onOpenGainersFullscreen,
    required this.onOpenLosersFullscreen,
  });

  final AppLocalizations l10n;
  final List<ProdutoVendidoTendenciaDeVendaRow> rows;
  final bool loading;
  final VoidCallback onOpenGainersFullscreen;
  final VoidCallback onOpenLosersFullscreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final topGainers = _trendTopGainersRows(rows);
    final topLosers = _trendTopLosersRows(rows);
    final chartBlockHeight = AppComparisonBarChart.loadingBlockHeight(tokens);

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.salesProdutoTendenciaTopMoversTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.gapXs),
          Text(
            l10n.salesProdutoTendenciaTopMoversSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.contentSpacing),
          if (loading && rows.isEmpty)
            AppSkeleton(
              enabled: true,
              loadingSemanticsLabel:
                  l10n.salesProdutoTendenciaLoadingTrendSemantics,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final titleStyle = theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  );
                  final wideSkeleton = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              l10n.salesProdutoTendenciaTopGainersTitle,
                              style: titleStyle,
                            ),
                            SizedBox(height: tokens.gapSm),
                            SizedBox(
                              height: chartBlockHeight,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  l10n.salesProdutoTendenciaTopGainersTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: tokens.gapMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              l10n.salesProdutoTendenciaTopLosersTitle,
                              style: titleStyle,
                            ),
                            SizedBox(height: tokens.gapSm),
                            SizedBox(
                              height: chartBlockHeight,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  l10n.salesProdutoTendenciaTopLosersTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                  final narrowSkeleton = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        l10n.salesProdutoTendenciaTopGainersTitle,
                        style: titleStyle,
                      ),
                      SizedBox(height: tokens.gapSm),
                      SizedBox(
                        height: chartBlockHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.salesProdutoTendenciaTopGainersTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(height: tokens.gapMd),
                      Text(
                        l10n.salesProdutoTendenciaTopLosersTitle,
                        style: titleStyle,
                      ),
                      SizedBox(height: tokens.gapSm),
                      SizedBox(
                        height: chartBlockHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.salesProdutoTendenciaTopLosersTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  );
                  return constraints.maxWidth >= 900
                      ? wideSkeleton
                      : narrowSkeleton;
                },
              ),
            )
          else if (rows.isEmpty)
            Text(
              l10n.salesProdutoTendenciaNoData,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final chartAxisFormat = NumberFormat.decimalPattern(
                  l10n.localeName,
                );
                final gainersChart =
                    AppComparisonBarChart<ProdutoVendidoTendenciaDeVendaRow>(
                      title: l10n.salesProdutoTendenciaTopGainersTitle,
                      items: topGainers,
                      labelBuilder: (row) => row.nomeProduto,
                      valueBuilder: (row) => row.percentualTendencia,
                      onOpenFullscreen: onOpenGainersFullscreen,
                      openFullscreenTooltip: l10n.chartOpenFullscreenTooltip,
                      openFullscreenSemanticLabel:
                          l10n.chartOpenFullscreenTooltip,
                      plotFloorAccessibilityNotice:
                          l10n.chartComparisonPlotFloorNotice,
                      extremeSpreadAccessibilityNotice:
                          l10n.chartComparisonExtremeValueSpreadNotice,
                      style: salesTrendHomeLikeComparisonBarChartStyle(
                        tokens: tokens,
                        l10n: l10n,
                        yAxisFormat: chartAxisFormat,
                        minPlottedValueShareOfMax: 0.03,
                      ),
                      dataLabelBuilder: (row, _) =>
                          '${row.percentualTendencia.toStringAsFixed(1)}%',
                      tooltipLabelBuilder: (row, value) =>
                          '${row.nomeProduto} • '
                          '${row.percentualTendencia.toStringAsFixed(2)}% • '
                          '${NumberFormat.decimalPattern(l10n.localeName).format(row.diferenca.round())}',
                    );
                final losersChart =
                    AppComparisonBarChart<ProdutoVendidoTendenciaDeVendaRow>(
                      title: l10n.salesProdutoTendenciaTopLosersTitle,
                      items: topLosers,
                      labelBuilder: (row) => row.nomeProduto,
                      valueBuilder: (row) => row.percentualTendencia.abs(),
                      onOpenFullscreen: onOpenLosersFullscreen,
                      openFullscreenTooltip: l10n.chartOpenFullscreenTooltip,
                      openFullscreenSemanticLabel:
                          l10n.chartOpenFullscreenTooltip,
                      plotFloorAccessibilityNotice:
                          l10n.chartComparisonPlotFloorNotice,
                      extremeSpreadAccessibilityNotice:
                          l10n.chartComparisonExtremeValueSpreadNotice,
                      style: salesTrendHomeLikeComparisonBarChartStyle(
                        tokens: tokens,
                        l10n: l10n,
                        yAxisFormat: chartAxisFormat,
                        minPlottedValueShareOfMax: 0.03,
                      ),
                      dataLabelBuilder: (row, _) =>
                          '${row.percentualTendencia.toStringAsFixed(1)}%',
                      tooltipLabelBuilder: (row, value) =>
                          '${row.nomeProduto} • '
                          '${row.percentualTendencia.toStringAsFixed(2)}% • '
                          '${NumberFormat.decimalPattern(l10n.localeName).format(row.diferenca.round())}',
                    );
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: gainersChart),
                      SizedBox(width: tokens.gapMd),
                      Expanded(child: losersChart),
                    ],
                  );
                }
                return Column(
                  children: <Widget>[
                    gainersChart,
                    SizedBox(height: tokens.gapMd),
                    losersChart,
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TrendDetailsSection extends StatelessWidget {
  const _TrendDetailsSection({
    required this.l10n,
    required this.rows,
    required this.loading,
    required this.currentPage,
    required this.pageSize,
    required this.onPageSelected,
    required this.onPageSizeChanged,
    required this.classLabelBuilder,
  });

  final AppLocalizations l10n;
  final List<ProdutoVendidoTendenciaDeVendaRow> rows;
  final bool loading;
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageSelected;
  final ValueChanged<int> onPageSizeChanged;
  final String Function(String value) classLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final rowNumber = NumberFormat.decimalPattern(l10n.localeName);
    final hasNextPage = rows.length >= pageSize;
    final totalPages = hasNextPage ? currentPage + 1 : math.max(1, currentPage);
    final rangeStart = rows.isEmpty ? 0 : ((currentPage - 1) * pageSize) + 1;
    final rangeEnd = rows.isEmpty ? 0 : rangeStart + rows.length - 1;
    final totalItems = hasNextPage
        ? (currentPage * pageSize) + 1
        : ((currentPage - 1) * pageSize) + rows.length;

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.salesProdutoTendenciaDetailsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.gapXs),
          Text(
            l10n.salesProdutoTendenciaDetailsSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (rows.isNotEmpty) ...<Widget>[
            SizedBox(height: tokens.gapXs),
            Text(
              l10n.salesProdutoTendenciaDetailsHorizontalScrollCaption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: tokens.contentSpacing),
          if (loading && rows.isEmpty)
            AppSkeleton(
              enabled: true,
              loadingSemanticsLabel:
                  l10n.salesProdutoTendenciaLoadingTrendSemantics,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (var i = 0; i < 5; i++) ...<Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.gapSm,
                        vertical: tokens.gapSm,
                      ),
                      child: const Text(
                        '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (i < 4)
                      Divider(
                        height: tokens.gapMd * 2,
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.35,
                        ),
                      ),
                  ],
                ],
              ),
            )
          else if (rows.isEmpty)
            Text(
              l10n.salesProdutoTendenciaNoData,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else ...<Widget>[
            LayoutBuilder(
              builder: (context, constraints) {
                final minTable = _TrendDetailsTableLayout.minScrollContentWidth(
                  tokens,
                );
                final outer = constraints.maxWidth;
                final contentWidth = outer.isFinite && outer > 0
                    ? math.max(outer, minTable)
                    : minTable;
                return ChartHorizontalScrollShell(
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _TrendDetailsTableHeader(l10n: l10n),
                          Divider(
                            height: tokens.gapMd * 2,
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: rows.length,
                            separatorBuilder: (_, _) => Divider(
                              height: tokens.gapMd * 2,
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.35),
                            ),
                            itemBuilder: (context, index) {
                              final row = rows[index];
                              return _TrendDetailsRow(
                                row: row,
                                l10n: l10n,
                                classLabel: classLabelBuilder(
                                  row.classificacao,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  semanticsHint:
                      l10n.salesProdutoTendenciaDetailsHorizontalScrollCaption,
                );
              },
            ),
            SizedBox(height: tokens.contentSpacing),
            AppTablePaginationFooter(
              currentPage: currentPage,
              totalPages: totalPages,
              pageSize: pageSize,
              rangeStart: rangeStart,
              rangeEnd: rangeEnd,
              totalItems: totalItems,
              entityLabel: l10n.salesProdutoTendenciaDetailsEntityLabel,
              pageSizeOptions: const <int>[10, 20, 50, 100],
              itemsPerPageLabel: l10n.salesProdutoTendenciaFilterPageSize,
              onPageSizeChanged: onPageSizeChanged,
              onPrevious: currentPage > 1
                  ? () => onPageSelected(currentPage - 1)
                  : null,
              onNext: hasNextPage
                  ? () => onPageSelected(currentPage + 1)
                  : null,
              onPageSelected: onPageSelected,
            ),
            SizedBox(height: tokens.gapSm),
            Text(
              l10n.salesProdutoTendenciaDetailsNotice(
                rowNumber.format(pageSize),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Minimum column widths for the trend details grid so labels stay on one line
/// when the viewport is narrow; the table scrolls horizontally as a unit.
abstract final class _TrendDetailsTableLayout {
  static double _product(AppThemeTokens t) => math.max(220, t.gapMd * 18);
  static double _classificacao(AppThemeTokens t) => math.max(120, t.gapMd * 10);
  static double _grupo(AppThemeTokens t) => math.max(132, t.gapMd * 11);
  static double _delta(AppThemeTokens t) => math.max(104, t.gapMd * 9);
  static double _percentual(AppThemeTokens t) => math.max(104, t.gapMd * 9);

  static double minWidth(AppThemeTokens t) =>
      _product(t) + _classificacao(t) + _grupo(t) + _delta(t) + _percentual(t);

  /// Row [Padding] uses [AppThemeTokens.gapSm] on each horizontal side.
  static double minScrollContentWidth(AppThemeTokens t) =>
      minWidth(t) + 2 * t.gapSm;
}

class _TrendDetailsTableHeader extends StatelessWidget {
  const _TrendDetailsTableHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.gapSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: _TrendDetailsTableLayout._product(tokens),
            child: Text(l10n.salesProdutoTendenciaColProduct, style: style),
          ),
          SizedBox(
            width: _TrendDetailsTableLayout._classificacao(tokens),
            child: Text(
              l10n.salesProdutoTendenciaColClassificacao,
              style: style,
            ),
          ),
          SizedBox(
            width: _TrendDetailsTableLayout._grupo(tokens),
            child: Text(l10n.salesProdutoTendenciaColGrupo, style: style),
          ),
          SizedBox(
            width: _TrendDetailsTableLayout._delta(tokens),
            child: Text(
              l10n.salesProdutoTendenciaColDiferenca,
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
          SizedBox(
            width: _TrendDetailsTableLayout._percentual(tokens),
            child: Text(
              l10n.salesProdutoTendenciaColPercentual,
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendDetailsRow extends StatelessWidget {
  const _TrendDetailsRow({
    required this.row,
    required this.l10n,
    required this.classLabel,
  });

  final ProdutoVendidoTendenciaDeVendaRow row;
  final AppLocalizations l10n;
  final String classLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final numberFmt = NumberFormat.decimalPattern(l10n.localeName);
    final percentText = '${row.percentualTendencia.toStringAsFixed(1)}%';
    const tabularFigures = <FontFeature>[FontFeature.tabularFigures()];

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.gapSm),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: _TrendDetailsTableLayout._product(tokens),
              child: Text(
                row.nomeProduto,
                softWrap: true,
                maxLines: 4,
              ),
            ),
            SizedBox(
              width: _TrendDetailsTableLayout._classificacao(tokens),
              child: Text(
                classLabel,
                softWrap: true,
                maxLines: 3,
                style: theme.textTheme.bodySmall,
              ),
            ),
            SizedBox(
              width: _TrendDetailsTableLayout._grupo(tokens),
              child: Text(
                row.nomeGrupoProduto?.trim().isNotEmpty == true
                    ? row.nomeGrupoProduto!
                    : l10n.salesProdutoTendenciaFilterAllOption,
                softWrap: true,
                maxLines: 4,
              ),
            ),
            SizedBox(
              width: _TrendDetailsTableLayout._delta(tokens),
              child: Text(
                numberFmt.format(row.diferenca.round()),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFeatures: tabularFigures,
                ),
              ),
            ),
            SizedBox(
              width: _TrendDetailsTableLayout._percentual(tokens),
              child: Text(
                percentText,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFeatures: tabularFigures,
                  color: row.percentualTendencia >= 0
                      ? theme.appColors.tertiary
                      : theme.appColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesProdutoTendenciaFiltersSheet extends StatefulWidget {
  const _SalesProdutoTendenciaFiltersSheet({
    required this.l10n,
    required this.availableAgents,
    required this.initialSelectedAgentId,
    required this.initialPeriodoAtual,
    required this.initialPeriodoAnterior,
    required this.initialSearchTerm,
    required this.initialClassificacao,
    required this.initialCodGrupoProduto,
    required this.initialCodMarca,
    required this.initialPageSize,
    required this.grupoOptions,
    required this.marcaOptions,
    required this.onApply,
  });

  final AppLocalizations l10n;
  final List<OverviewAgentOption> availableAgents;
  final String? initialSelectedAgentId;
  final DateTimeRange initialPeriodoAtual;
  final DateTimeRange initialPeriodoAnterior;
  final String initialSearchTerm;
  final String? initialClassificacao;
  final int? initialCodGrupoProduto;
  final int? initialCodMarca;
  final int initialPageSize;
  final List<GrupoProdutoOption> grupoOptions;
  final List<MarcaProdutoOption> marcaOptions;
  final ValueChanged<Map<String, Object?>> onApply;

  @override
  State<_SalesProdutoTendenciaFiltersSheet> createState() =>
      _SalesProdutoTendenciaFiltersSheetState();
}

class _SalesProdutoTendenciaFiltersSheetState
    extends State<_SalesProdutoTendenciaFiltersSheet> {
  String? _selectedAgentId;
  DateTimeRange? _periodoAtual;
  DateTimeRange? _periodoAnterior;
  late final TextEditingController _searchController;
  String? _classificacao;
  int? _codGrupoProduto;
  int? _codMarca;
  late int _pageSize;

  _SalesTrendDatePreset? get _selectedPreset {
    for (final preset in _SalesTrendDatePreset.values) {
      final current = _salesTrendCurrentRangeForPreset(preset);
      final previous = _salesTrendAutoPreviousRange(current);
      if (_salesTrendSameRange(_periodoAtual, current) &&
          _salesTrendSameRange(_periodoAnterior, previous)) {
        return preset;
      }
    }
    return null;
  }

  String? get _periodValidationMessage {
    final periodoAtual = _periodoAtual;
    final periodoAnterior = _periodoAnterior;
    if (periodoAtual == null || periodoAnterior == null) {
      return null;
    }

    final error = ProdutoVendidoTendenciaDeVendaFilter(
      periodoAtualInicio: periodoAtual.start,
      periodoAtualFim: periodoAtual.end,
      periodoAnteriorInicio: periodoAnterior.start,
      periodoAnteriorFim: periodoAnterior.end,
      searchTerm: _searchController.text,
      classificacao: _classificacao,
      codGrupoProduto: _codGrupoProduto,
      codMarca: _codMarca,
      pageSize: _pageSize,
    ).validationError();

    return _localizedPeriodValidationMessage(error);
  }

  bool get _canApply {
    final selectedAgentId = _selectedAgentId;
    return selectedAgentId != null &&
        selectedAgentId.trim().isNotEmpty &&
        _periodoAtual != null &&
        _periodoAnterior != null &&
        _periodValidationMessage == null;
  }

  String? _rangeHelperText(DateTimeRange? range) {
    if (range == null) {
      return null;
    }
    return _salesTrendRangeDescriptorLabel(widget.l10n, range);
  }

  @override
  void initState() {
    super.initState();
    _selectedAgentId = widget.initialSelectedAgentId;
    _periodoAtual = widget.initialPeriodoAtual;
    _periodoAnterior = widget.initialPeriodoAnterior;
    _searchController = TextEditingController(text: widget.initialSearchTerm);
    _classificacao = widget.initialClassificacao;
    _codGrupoProduto = widget.initialCodGrupoProduto;
    _codMarca = widget.initialCodMarca;
    _pageSize = widget.initialPageSize;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _localizedPeriodValidationMessage(String? error) {
    if (error == null) {
      return null;
    }

    final l10n = widget.l10n;
    return switch (error) {
      ProdutoVendidoTendenciaDeVendaFilter
          .errorPeriodoAnteriorMustBeBeforeAtual =>
        l10n.salesProdutoTendenciaFilterPeriodsOrderError,
      ProdutoVendidoTendenciaDeVendaFilter
          .errorPeriodsMustCoverEquivalentWindows =>
        l10n.salesProdutoTendenciaFilterPeriodsEquivalentWindowError,
      _ => null,
    };
  }

  void _apply() {
    if (!_canApply) {
      return;
    }
    final selectedAgentId = _selectedAgentId!;
    widget.onApply(<String, Object?>{
      'agentId': selectedAgentId,
      'periodoAtual': _periodoAtual,
      'periodoAnterior': _periodoAnterior,
      'searchTerm': _searchController.text,
      'classificacao': _classificacao,
      'codGrupoProduto': _codGrupoProduto,
      'codMarca': _codMarca,
      'pageSize': _pageSize,
    });
    Navigator.of(context).pop();
  }

  void _applyPreset(_SalesTrendDatePreset preset) {
    final current = _salesTrendCurrentRangeForPreset(preset);
    setState(() {
      _periodoAtual = current;
      _periodoAnterior = _salesTrendAutoPreviousRange(current);
    });
  }

  void _autoAdjustPreviousPeriod() {
    final periodoAtual = _periodoAtual;
    if (periodoAtual == null) {
      return;
    }
    setState(() {
      _periodoAnterior = _salesTrendAutoPreviousRange(periodoAtual);
    });
  }

  void _clear() {
    final now = DateTime.now();
    setState(() {
      _periodoAtual = _salesTrendFullMonthInclusiveRange(now);
      _periodoAnterior = _salesTrendPreviousMonthInclusiveRange(now);
      _searchController.text = '';
      _classificacao = null;
      _codGrupoProduto = null;
      _codMarca = null;
      _pageSize = ProdutoVendidoTendenciaDeVendaFilter.defaultPageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final l10n = widget.l10n;
    final periodValidationMessage = _periodValidationMessage;
    final selectedPreset = _selectedPreset;
    final selectedAgentMissingToken =
        _selectedAgentId != null &&
        widget.availableAgents.any(
          (agent) =>
              agent.agentId == _selectedAgentId &&
              agent.missingLocalClientToken,
        );

    return SalesFiltersSheetScaffold(
      title: l10n.reportFiltersTitleWithContext(
        l10n.salesCardProdutoTendenciaTitle,
      ),
      description: l10n.reportFiltersDescription,
      primaryActionLabel: l10n.reportFiltersApplyAction,
      secondaryActionLabel: l10n.reportFiltersClearAction,
      onPrimaryAction: _apply,
      onSecondaryAction: _clear,
      canPrimaryAction: _canApply,
      bodyBuilder: (scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            tokens.contentSpacing,
            0,
            tokens.contentSpacing,
            tokens.contentSpacing,
          ),
          children: <Widget>[
            SalesFiltersSectionHeader(
              title: l10n.salesBranchFilterLabel,
              subtitle: l10n.salesBranchRequiredMessage,
              requiredBadgeLabel: l10n.reportFiltersRequiredCount(1),
            ),
            SizedBox(height: tokens.gapSm),
            SalesBranchPickerControl(
              l10n: l10n,
              availableBranches: widget.availableAgents,
              selectedBranchId: _selectedAgentId,
              showTrailingFilterButton: false,
              onSelectionChanged: (agentId) {
                setState(() => _selectedAgentId = agentId);
              },
            ),
            if (selectedAgentMissingToken) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              AppInlineErrorPanel(
                tone: AppInlinePanelTone.informational,
                message: l10n.salesBranchFilterMissingClientTokenBanner,
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            SalesFiltersSectionHeader(
              title: l10n.reportFiltersTitle,
              subtitle: l10n.reportFiltersDescription,
            ),
            SizedBox(height: tokens.gapSm),
            AppSectionCard(
              color: theme.colorScheme.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    l10n.salesProdutoTendenciaFilterQuickPeriodsTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.gapXs),
                  Text(
                    l10n.salesProdutoTendenciaFilterQuickPeriodsSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: tokens.gapMd),
                  Wrap(
                    spacing: tokens.gapSm,
                    runSpacing: tokens.gapSm,
                    children: <Widget>[
                      AppChoiceChip(
                        label:
                            l10n.salesProdutoTendenciaFilterPresetCurrentMonth,
                        selected:
                            selectedPreset ==
                            _SalesTrendDatePreset.currentMonth,
                        icon: Icons.calendar_view_month_rounded,
                        onSelected: () => _applyPreset(
                          _SalesTrendDatePreset.currentMonth,
                        ),
                      ),
                      AppChoiceChip(
                        label:
                            l10n.salesProdutoTendenciaFilterPresetPreviousMonth,
                        selected:
                            selectedPreset ==
                            _SalesTrendDatePreset.previousMonth,
                        icon: Icons.history_rounded,
                        onSelected: () => _applyPreset(
                          _SalesTrendDatePreset.previousMonth,
                        ),
                      ),
                      AppChoiceChip(
                        label: l10n.salesProdutoTendenciaFilterPresetLast7Days,
                        selected:
                            selectedPreset == _SalesTrendDatePreset.last7Days,
                        icon: Icons.date_range_rounded,
                        onSelected: () =>
                            _applyPreset(_SalesTrendDatePreset.last7Days),
                      ),
                      AppChoiceChip(
                        label: l10n.salesProdutoTendenciaFilterPresetLast30Days,
                        selected:
                            selectedPreset == _SalesTrendDatePreset.last30Days,
                        icon: Icons.insights_rounded,
                        onSelected: () =>
                            _applyPreset(_SalesTrendDatePreset.last30Days),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.gapSm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _periodoAtual == null
                          ? null
                          : _autoAdjustPreviousPeriod,
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                      label: Text(
                        l10n.salesProdutoTendenciaFilterAutoAdjustPreviousAction,
                      ),
                    ),
                  ),
                  AppInlineErrorPanel(
                    variant: AppInlineErrorPanelVariant.plain,
                    tone: AppInlinePanelTone.informational,
                    title: l10n.salesProdutoTendenciaFilterRuleHelperTitle,
                    message: l10n.salesProdutoTendenciaFilterRuleHelper,
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDateRangePickerField(
                    label: l10n.salesProdutoTendenciaFilterCurrentPeriod,
                    pickerTitle: l10n.salesProdutoTendenciaFilterCurrentPeriod,
                    value: _periodoAtual,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    density: AppTextFieldDensity.compact,
                    helperText: _rangeHelperText(_periodoAtual),
                    errorText: periodValidationMessage,
                    onChanged: (value) {
                      setState(() {
                        _periodoAtual = value;
                        _periodoAnterior = value == null
                            ? null
                            : _salesTrendAutoPreviousRange(value);
                      });
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDateRangePickerField(
                    label: l10n.salesProdutoTendenciaFilterPreviousPeriod,
                    pickerTitle: l10n.salesProdutoTendenciaFilterPreviousPeriod,
                    value: _periodoAnterior,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    density: AppTextFieldDensity.compact,
                    helperText: _rangeHelperText(_periodoAnterior),
                    errorText: periodValidationMessage,
                    onChanged: (value) {
                      setState(() => _periodoAnterior = value);
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppTextField(
                    controller: _searchController,
                    label: l10n.salesProdutoTendenciaFilterSearch,
                    hintText: l10n.salesProdutoTendenciaFilterSearchHint,
                    density: AppTextFieldDensity.compact,
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDropdownField<String?>(
                    label: l10n.salesProdutoTendenciaFilterClassification,
                    value: _classificacao,
                    density: AppTextFieldDensity.compact,
                    options: <AppDropdownOption<String?>>[
                      AppDropdownOption<String?>(
                        value: null,
                        label: l10n.salesProdutoTendenciaFilterAllOption,
                      ),
                      AppDropdownOption<String?>(
                        value: 'CRESCENDO',
                        label: l10n.salesProdutoTendenciaClassificacaoGrowing,
                      ),
                      AppDropdownOption<String?>(
                        value: 'CAINDO',
                        label: l10n.salesProdutoTendenciaClassificacaoFalling,
                      ),
                      AppDropdownOption<String?>(
                        value: 'NOVO PRODUTO',
                        label: l10n.salesProdutoTendenciaClassificacaoNew,
                      ),
                      AppDropdownOption<String?>(
                        value: 'PAROU DE VENDER',
                        label: l10n.salesProdutoTendenciaClassificacaoStopped,
                      ),
                      AppDropdownOption<String?>(
                        value: 'ESTAVEL',
                        label: l10n.salesProdutoTendenciaClassificacaoStable,
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _classificacao = value);
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDropdownField<int?>(
                    label: l10n.salesProdutoTendenciaFilterGroup,
                    value: _codGrupoProduto,
                    density: AppTextFieldDensity.compact,
                    options: <AppDropdownOption<int?>>[
                      AppDropdownOption<int?>(
                        value: null,
                        label: l10n.salesProdutoTendenciaFilterAllOption,
                      ),
                      ...widget.grupoOptions.map(
                        (option) => AppDropdownOption<int?>(
                          value: option.codGrupoProduto,
                          label: option.nomeGrupoProduto,
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _codGrupoProduto = value);
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDropdownField<int?>(
                    label: l10n.salesProdutoTendenciaFilterBrand,
                    value: _codMarca,
                    density: AppTextFieldDensity.compact,
                    options: <AppDropdownOption<int?>>[
                      AppDropdownOption<int?>(
                        value: null,
                        label: l10n.salesProdutoTendenciaFilterAllOption,
                      ),
                      ...widget.marcaOptions.map(
                        (option) => AppDropdownOption<int?>(
                          value: option.codMarca,
                          label: option.nomeMarca,
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _codMarca = value);
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDropdownField<int>(
                    label: l10n.salesProdutoTendenciaFilterPageSize,
                    value: _pageSize,
                    density: AppTextFieldDensity.compact,
                    options: const <AppDropdownOption<int>>[
                      AppDropdownOption<int>(value: 10, label: '10'),
                      AppDropdownOption<int>(value: 20, label: '20'),
                      AppDropdownOption<int>(value: 50, label: '50'),
                      AppDropdownOption<int>(value: 100, label: '100'),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _pageSize = value);
                    },
                  ),
                  if (periodValidationMessage != null) ...<Widget>[
                    SizedBox(height: tokens.contentSpacing),
                    AppInlineErrorPanel(
                      variant: AppInlineErrorPanelVariant.plain,
                      title: l10n.salesProdutoTendenciaFilterApplyDisabledTitle,
                      message: periodValidationMessage,
                      belowMessage: Text(
                        l10n.salesProdutoTendenciaFilterApplyDisabledHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      actions: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _periodoAtual == null
                              ? null
                              : _autoAdjustPreviousPeriod,
                          icon: const Icon(
                            Icons.auto_fix_high_rounded,
                            size: 18,
                          ),
                          label: Text(
                            l10n.salesProdutoTendenciaFilterAutoAdjustPreviousAction,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

_TrendSummary _buildSummary(
  List<ProdutoVendidoTendenciaDeVendaSummaryRow> summaryRows,
) {
  final counts = <String, int>{};
  final impacts = <String, double>{};
  var netImpact = 0.0;

  for (final row in summaryRows) {
    final classificacao = row.classificacao.trim().toUpperCase();
    counts[classificacao] =
        (counts[classificacao] ?? 0) + row.quantidadeProdutos;
    impacts[classificacao] = (impacts[classificacao] ?? 0) + row.impactoLiquido;
    netImpact += row.impactoLiquido;
  }

  final buckets =
      counts.entries
          .map(
            (entry) => _TrendClassBucket(
              classificacao: entry.key,
              count: entry.value,
              impacto: impacts[entry.key] ?? 0,
            ),
          )
          .toList(growable: false)
        ..sort((a, b) => b.count.compareTo(a.count));

  return _TrendSummary(
    countGrowing: counts['CRESCENDO'] ?? 0,
    countFalling: counts['CAINDO'] ?? 0,
    countNew: counts['NOVO PRODUTO'] ?? 0,
    countStopped: counts['PAROU DE VENDER'] ?? 0,
    netImpact: netImpact,
    buckets: buckets,
  );
}

class _TrendSummary {
  const _TrendSummary({
    required this.countGrowing,
    required this.countFalling,
    required this.countNew,
    required this.countStopped,
    required this.netImpact,
    required this.buckets,
  });

  final int countGrowing;
  final int countFalling;
  final int countNew;
  final int countStopped;
  final double netImpact;
  final List<_TrendClassBucket> buckets;
}

class _TrendClassBucket {
  const _TrendClassBucket({
    required this.classificacao,
    required this.count,
    required this.impacto,
  });

  final String classificacao;
  final int count;
  final double impacto;
}
