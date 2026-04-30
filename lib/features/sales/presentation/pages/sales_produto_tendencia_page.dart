import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_grupo_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_marca_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_summary_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/marca_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/forms/app_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SalesProdutoTendenciaPage extends StatefulWidget {
  const SalesProdutoTendenciaPage({super.key});

  @override
  State<SalesProdutoTendenciaPage> createState() =>
      _SalesProdutoTendenciaPageState();
}

class _SalesProdutoTendenciaPageState extends State<SalesProdutoTendenciaPage> {
  static const String _cardId = 'produto_tendencia_venda';
  static const List<int> _pageSizeOptions = <int>[10, 20, 50, 100];

  late final SalesPreferences _prefs;
  late final AgentClientTokenReader _clientTokenReader;
  late final LoadAvailableAgentsForSales _loadAgentsUseCase;
  late final LoadProdutoVendidoTendenciaDeVendaUseCase _loadTrend;
  late final LoadProdutoVendidoTendenciaDeVendaSummaryUseCase _loadTrendSummary;
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

  DateTimeRange _fullMonthInclusiveRange(DateTime anchor) => DateTimeRange(
    start: DateTime(anchor.year, anchor.month),
    end: DateTime(anchor.year, anchor.month + 1, 0),
  );

  DateTimeRange _previousMonthInclusiveRange(DateTime anchor) {
    final previous = DateTime(anchor.year, anchor.month - 1);
    return DateTimeRange(
      start: DateTime(previous.year, previous.month),
      end: DateTime(previous.year, previous.month + 1, 0),
    );
  }

  @override
  void initState() {
    super.initState();
    _prefs = getIt<SalesPreferences>();
    _clientTokenReader = getIt<AgentClientTokenReader>();
    _loadAgentsUseCase = getIt<LoadAvailableAgentsForSales>();
    _loadTrend = getIt<LoadProdutoVendidoTendenciaDeVendaUseCase>();
    _loadTrendSummary =
        getIt<LoadProdutoVendidoTendenciaDeVendaSummaryUseCase>();
    _loadGrupoOptions = getIt<LoadGrupoProdutoOptionsUseCase>();
    _loadMarcaOptions = getIt<LoadMarcaProdutoOptionsUseCase>();
    _selectedAgentId = _prefs.selectedAgentId;

    final now = DateTime.now();
    final restored = _prefs.restoreCardFilters(_cardId);
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
    if (nextSelection != _prefs.selectedAgentId) {
      unawaited(_prefs.setSelectedAgentId(nextSelection));
    }
    unawaited(_reload());
  }

  Future<void> _reload() async {
    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    final agentId = _selectedAgentId;

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

    final detailFuture = _loadTrend(
      userId: userId,
      agentId: trimmedAgentId,
      filter: detailFilter,
      clientToken: clientToken,
    );
    final summaryFuture = _loadTrendSummary(
      userId: userId,
      agentId: trimmedAgentId,
      filter: summaryFilter,
      clientToken: clientToken,
    );
    final result = await detailFuture;
    final summaryResult = await summaryFuture;

    if (!mounted) {
      return;
    }

    result.fold(
      (rows) {
        final resolvedSummary = summaryResult.fold(
          (summaryRows) => summaryRows,
          (_) => _buildSummaryRowsFallback(rows),
        );
        setState(() {
          _rows = rows;
          _summaryRows = resolvedSummary;
          _loading = false;
          _error = null;
        });
      },
      (failure) {
        setState(() {
          _rows = const <ProdutoVendidoTendenciaDeVendaRow>[];
          _summaryRows = const <ProdutoVendidoTendenciaDeVendaSummaryRow>[];
          _loading = false;
          _error = _failureMessage(failure);
        });
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
    final tokenByAgent = await _clientTokenReader.readMany(
      userId: userId,
      agentIds: <String>[agentId],
    );
    final resolved = tokenByAgent[agentId]?.trim();
    _cachedClientTokenUserId = userId;
    _cachedClientTokenAgentId = agentId;
    return _cachedClientToken = resolved == null || resolved.isEmpty
        ? null
        : resolved;
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
    unawaited(_prefs.setSelectedAgentId(normalizedAgentId));
    unawaited(_persistFilters());
    unawaited(_reload());
  }

  Future<void> _persistFilters() {
    return _prefs.persistCardFilters(_cardId, <String, Object?>{
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

  List<ProdutoVendidoTendenciaDeVendaSummaryRow> _buildSummaryRowsFallback(
    List<ProdutoVendidoTendenciaDeVendaRow> rows,
  ) {
    final counts = <String, int>{};
    final impactByClassificacao = <String, double>{};
    for (final row in rows) {
      final key = row.classificacao.trim().toUpperCase();
      counts[key] = (counts[key] ?? 0) + 1;
      impactByClassificacao[key] =
          (impactByClassificacao[key] ?? 0) + row.diferenca;
    }
    return counts.entries
        .map(
          (entry) => ProdutoVendidoTendenciaDeVendaSummaryRow(
            classificacao: entry.key,
            quantidadeProdutos: entry.value,
            impactoLiquido: impactByClassificacao[entry.key] ?? 0,
          ),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final selectedAgent = _availableAgents
        .cast<OverviewAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == _selectedAgentId,
          orElse: () => null,
        );
    final selectedAgentName = selectedAgent?.name ?? l10n.salesAgentPickerEmpty;

    final activeDetailFilterValues = <Object?>[
      _classificacao,
      _codGrupoProduto,
      _codMarca,
    ];
    if (_searchTerm.trim().isNotEmpty) {
      activeDetailFilterValues.add(_searchTerm);
    }
    final activeDetailFilterCount = activeDetailFilterValues
        .whereType<Object>()
        .length;

    return SingleChildScrollView(
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
            title: l10n.salesCardProdutoTendenciaTitle,
            subtitle: l10n.salesProdutoTendenciaPageSubtitle,
          ),
          SizedBox(height: tokens.sectionSpacing),
          SalesCardFilterTrigger(
            onTap: () => unawaited(_openFiltersSheet()),
            buttonSemanticsLabel: l10n.reportFiltersButton,
            summaryItems: <SalesCardFilterSummaryItem>[
              SalesCardFilterSummaryItem(
                label: l10n.dashboardHomeFiltersAgentsLabel,
                value: selectedAgentName,
              ),
              SalesCardFilterSummaryItem(
                label: l10n.salesProdutoTendenciaFilterCurrentPeriod,
                value: _dateRangeLabel(_periodoAtual),
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
          SizedBox(height: tokens.sectionSpacing),
          if (_selectedAgentId == null) ...<Widget>[
            AppInlineErrorPanel(
              tone: AppInlinePanelTone.informational,
              title: l10n.salesAgentRequiredTitle,
              message: l10n.salesAgentRequiredMessage,
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
              classLabelBuilder: (value) => _classificacaoLabel(l10n, value),
            ),
            SizedBox(height: tokens.sectionSpacing),
            _TrendTopMoversSection(
              l10n: l10n,
              rows: _rows,
              loading: _loading,
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
    );
  }
}

class _TrendSummarySection extends StatelessWidget {
  const _TrendSummarySection({
    required this.l10n,
    required this.summaryRows,
    required this.loading,
    required this.classLabelBuilder,
  });

  final AppLocalizations l10n;
  final List<ProdutoVendidoTendenciaDeVendaSummaryRow> summaryRows;
  final bool loading;
  final String Function(String value) classLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final summary = _buildSummary(summaryRows);

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
          SizedBox(height: tokens.contentSpacing),
          if (loading && summaryRows.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (summaryRows.isEmpty)
            Text(
              l10n.salesProdutoTendenciaNoData,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else ...<Widget>[
            Wrap(
              spacing: tokens.gapMd,
              runSpacing: tokens.gapMd,
              children: <Widget>[
                _kpiCard(
                  context,
                  icon: Icons.trending_up_rounded,
                  label: l10n.salesProdutoTendenciaKpiGrowing,
                  value: NumberFormat.decimalPattern(
                    'pt_BR',
                  ).format(summary.countGrowing),
                  color: colors.tertiary,
                ),
                _kpiCard(
                  context,
                  icon: Icons.trending_down_rounded,
                  label: l10n.salesProdutoTendenciaKpiFalling,
                  value: NumberFormat.decimalPattern(
                    'pt_BR',
                  ).format(summary.countFalling),
                  color: colors.error,
                ),
                _kpiCard(
                  context,
                  icon: Icons.new_releases_outlined,
                  label: l10n.salesProdutoTendenciaKpiNewProducts,
                  value: NumberFormat.decimalPattern(
                    'pt_BR',
                  ).format(summary.countNew),
                  color: colors.primary,
                ),
                _kpiCard(
                  context,
                  icon: Icons.pause_circle_outline_rounded,
                  label: l10n.salesProdutoTendenciaKpiStopped,
                  value: NumberFormat.decimalPattern(
                    'pt_BR',
                  ).format(summary.countStopped),
                  color: colors.onSurfaceVariant,
                ),
                _kpiCard(
                  context,
                  icon: Icons.balance_rounded,
                  label: l10n.salesProdutoTendenciaKpiNetImpact,
                  value: NumberFormat.decimalPattern(
                    'pt_BR',
                  ).format(summary.netImpact),
                  color: summary.netImpact >= 0
                      ? colors.tertiary
                      : colors.error,
                ),
              ],
            ),
            SizedBox(height: tokens.contentSpacing),
            AppComparisonBarChart<_TrendClassBucket>(
              title: l10n.salesProdutoTendenciaSummaryByClassificacaoTitle,
              subtitle:
                  l10n.salesProdutoTendenciaSummaryByClassificacaoSubtitle,
              items: summary.buckets,
              labelBuilder: (bucket) => classLabelBuilder(bucket.classificacao),
              valueBuilder: (bucket) => bucket.count,
              style: const AppComparisonBarChartStyle(
                height: 220,
                showDataLabels: true,
                xLabelRotation: 25,
                autoRotateXLabels: false,
              ),
              dataLabelBuilder: (bucket, value) =>
                  NumberFormat.decimalPattern('pt_BR').format(bucket.count),
              tooltipLabelBuilder: (bucket, value) =>
                  '${classLabelBuilder(bucket.classificacao)} • '
                  '${bucket.count} • '
                  '${NumberFormat.decimalPattern('pt_BR').format(bucket.impacto.round())}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _kpiCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return SizedBox(
      width: math.max(160, tokens.chartCompactHeight),
      child: AppMetricStatCard(
        leading: Icon(icon, color: color),
        label: label,
        value: value,
      ),
    );
  }
}

class _TrendTopMoversSection extends StatelessWidget {
  const _TrendTopMoversSection({
    required this.l10n,
    required this.rows,
    required this.loading,
  });

  final AppLocalizations l10n;
  final List<ProdutoVendidoTendenciaDeVendaRow> rows;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final topGainers = _topGainers(rows);
    final topLosers = _topLosers(rows);

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
            const Center(child: CircularProgressIndicator())
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
                final gainersChart =
                    AppComparisonBarChart<ProdutoVendidoTendenciaDeVendaRow>(
                      title: l10n.salesProdutoTendenciaTopGainersTitle,
                      items: topGainers,
                      labelBuilder: (row) => row.nomeProduto,
                      valueBuilder: (row) => row.percentualTendencia,
                      style: const AppComparisonBarChartStyle(
                        height: 260,
                        showDataLabels: true,
                      ),
                      dataLabelBuilder: (row, value) =>
                          '${row.percentualTendencia.toStringAsFixed(1)}%',
                      tooltipLabelBuilder: (row, value) =>
                          '${row.nomeProduto} • '
                          '${row.percentualTendencia.toStringAsFixed(2)}% • '
                          '${NumberFormat.decimalPattern('pt_BR').format(row.diferenca.round())}',
                      preset: AppChartPreset.compact,
                    );
                final losersChart =
                    AppComparisonBarChart<ProdutoVendidoTendenciaDeVendaRow>(
                      title: l10n.salesProdutoTendenciaTopLosersTitle,
                      items: topLosers,
                      labelBuilder: (row) => row.nomeProduto,
                      valueBuilder: (row) => row.percentualTendencia.abs(),
                      style: const AppComparisonBarChartStyle(
                        height: 260,
                        showDataLabels: true,
                      ),
                      dataLabelBuilder: (row, value) =>
                          '${row.percentualTendencia.toStringAsFixed(1)}%',
                      tooltipLabelBuilder: (row, value) =>
                          '${row.nomeProduto} • '
                          '${row.percentualTendencia.toStringAsFixed(2)}% • '
                          '${NumberFormat.decimalPattern('pt_BR').format(row.diferenca.round())}',
                      preset: AppChartPreset.compact,
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

  List<ProdutoVendidoTendenciaDeVendaRow> _topGainers(
    List<ProdutoVendidoTendenciaDeVendaRow> rows,
  ) {
    final values =
        rows.where((row) => row.percentualTendencia > 0).toList(growable: false)
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

  List<ProdutoVendidoTendenciaDeVendaRow> _topLosers(
    List<ProdutoVendidoTendenciaDeVendaRow> rows,
  ) {
    final values =
        rows.where((row) => row.percentualTendencia < 0).toList(growable: false)
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
    final rowNumber = NumberFormat.decimalPattern('pt_BR');
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
          SizedBox(height: tokens.contentSpacing),
          if (loading && rows.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (rows.isEmpty)
            Text(
              l10n.salesProdutoTendenciaNoData,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else ...<Widget>[
            _TrendDetailsTableHeader(l10n: l10n),
            Divider(
              height: tokens.gapMd * 2,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, _) => Divider(
                height: tokens.gapMd * 2,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
              itemBuilder: (context, index) {
                final row = rows[index];
                return _TrendDetailsRow(
                  row: row,
                  l10n: l10n,
                  classLabel: classLabelBuilder(row.classificacao),
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
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(l10n.salesProdutoTendenciaColProduct, style: style),
          ),
          Expanded(
            flex: 2,
            child: Text(
              l10n.salesProdutoTendenciaColClassificacao,
              style: style,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(l10n.salesProdutoTendenciaColGrupo, style: style),
          ),
          Expanded(
            flex: 2,
            child: Text(l10n.salesProdutoTendenciaColMarca, style: style),
          ),
          Expanded(
            child: Text(
              l10n.salesProdutoTendenciaColDiferenca,
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
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
    final numberFmt = NumberFormat.decimalPattern('pt_BR');
    final percentText = '${row.percentualTendencia.toStringAsFixed(1)}%';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.gapSm),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(
              row.nomeProduto,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              classLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.nomeGrupoProduto?.trim().isNotEmpty == true
                  ? row.nomeGrupoProduto!
                  : l10n.salesProdutoTendenciaFilterAllOption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.nomeMarca?.trim().isNotEmpty == true
                  ? row.nomeMarca!
                  : l10n.salesProdutoTendenciaFilterAllOption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              numberFmt.format(row.diferenca.round()),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            child: Text(
              percentText,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                color: row.percentualTendencia >= 0
                    ? theme.appColors.tertiary
                    : theme.appColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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

  void _apply() {
    final selectedAgentId = _selectedAgentId;
    if (selectedAgentId == null || selectedAgentId.trim().isEmpty) {
      return;
    }
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

  void _clear() {
    final now = DateTime.now();
    setState(() {
      _periodoAtual = DateTimeRange(
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month + 1, 0),
      );
      final previous = DateTime(now.year, now.month - 1);
      _periodoAnterior = DateTimeRange(
        start: DateTime(previous.year, previous.month),
        end: DateTime(previous.year, previous.month + 1, 0),
      );
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
      canPrimaryAction: _selectedAgentId != null,
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
              title: l10n.dashboardHomeFiltersAgentsLabel,
              subtitle: l10n.salesAgentRequiredMessage,
              requiredBadgeLabel: l10n.reportFiltersRequiredCount(1),
            ),
            SizedBox(height: tokens.gapSm),
            SalesSingleAgentPickerControl(
              l10n: l10n,
              availableAgents: widget.availableAgents,
              selectedAgentId: _selectedAgentId,
              showTrailingFilterButton: false,
              onSelectionChanged: (agentId) {
                setState(() => _selectedAgentId = agentId);
              },
            ),
            if (selectedAgentMissingToken) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              AppInlineErrorPanel(
                tone: AppInlinePanelTone.informational,
                message: l10n.overviewAgentFilterMissingClientTokenBanner,
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
                  AppDateRangePickerField(
                    label: l10n.salesProdutoTendenciaFilterCurrentPeriod,
                    pickerTitle: l10n.salesProdutoTendenciaFilterCurrentPeriod,
                    value: _periodoAtual,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    density: AppTextFieldDensity.compact,
                    onChanged: (value) {
                      setState(() => _periodoAtual = value);
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
