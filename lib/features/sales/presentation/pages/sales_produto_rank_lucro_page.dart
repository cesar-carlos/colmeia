import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_produto_rank_lucro_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
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
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/charts/app_horizontal_progress_chart.dart';
import 'package:colmeia/shared/widgets/forms/app_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SalesProdutoRankLucroPage extends StatefulWidget {
  const SalesProdutoRankLucroPage({
    required this.sessionService,
    required this.loadSalesAvailableAgentsUseCase,
    required this.resolveSalesAgentClientTokenUseCase,
    required this.loadProdutoVendidoProdutoRankLucroUseCase,
    this.relayCancelScopeBinder,
    super.key,
  });

  final SalesSessionService sessionService;
  final LoadSalesAvailableAgentsUseCase loadSalesAvailableAgentsUseCase;
  final ResolveSalesAgentClientTokenUseCase resolveSalesAgentClientTokenUseCase;
  final LoadProdutoVendidoProdutoRankLucroUseCase
  loadProdutoVendidoProdutoRankLucroUseCase;
  final AgentQueriesRelayCancelScopeBinder? relayCancelScopeBinder;

  @override
  State<SalesProdutoRankLucroPage> createState() =>
      _SalesProdutoRankLucroPageState();
}

class _SalesProdutoRankLucroPageState extends State<SalesProdutoRankLucroPage>
    with
        AutoRefreshStateMixin<SalesProdutoRankLucroPage>,
        SalesSingleAgentAutoRefreshMixin<SalesProdutoRankLucroPage>,
        SalesCardAutoRefreshBinding<SalesProdutoRankLucroPage> {
  late final SalesSessionService _sessionService;
  late final ResolveSalesAgentClientTokenUseCase _resolveClientTokenUseCase;
  late final LoadSalesAvailableAgentsUseCase _loadAgentsUseCase;
  late final LoadProdutoVendidoProdutoRankLucroUseCase _loadRanking;

  String? _selectedAgentId;
  List<DashboardAgentOption> _availableAgents = <DashboardAgentOption>[];
  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;

  Map<String, Object?> _filters = <String, Object?>{};
  List<ProdutoVendidoProdutoRankLucroRow> _rows =
      const <ProdutoVendidoProdutoRankLucroRow>[];

  bool _loading = false;
  String? _error;

  int _sqlLoadGeneration = 0;
  AgentQueriesCancelScope? _sqlCancelScope;

  DateTimeRange _fullMonthInclusiveRange(DateTime anchor) => DateTimeRange(
    start: DateTime(anchor.year, anchor.month),
    end: DateTime(anchor.year, anchor.month + 1, 0),
  );

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

  @override
  void initState() {
    super.initState();
    _sessionService = widget.sessionService;
    _resolveClientTokenUseCase = widget.resolveSalesAgentClientTokenUseCase;
    _loadAgentsUseCase = widget.loadSalesAvailableAgentsUseCase;
    _loadRanking = widget.loadProdutoVendidoProdutoRankLucroUseCase;
    _selectedAgentId = _sessionService.selectedAgentId;
    final restored = _sessionService.restoreProdutoRankLucroFilters();
    final defaultRange = _fullMonthInclusiveRange(DateTime.now());
    final restoredPeriod = restored['periodo'];
    final period = restoredPeriod is DateTimeRange
        ? restoredPeriod
        : defaultRange;
    final restoredSort = restored['sortBy'] as String?;
    final sortBy =
        restoredSort != null &&
            SalesSessionService.produtoRankLucroSortByAllowedValues.contains(
              restoredSort,
            )
        ? restoredSort
        : 'qtdItensVendido';
    _filters = <String, Object?>{
      'periodo': period,
      'sortBy': sortBy,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadAgents());
    });
  }

  @override
  void dispose() {
    _sqlCancelScope?.cancelAll();
    super.dispose();
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
  String get salesAutoRefreshCardId => SalesAutoRefreshCardIds.produtoRankLucro;

  @override
  String? get autoRefreshSelectedAgentId => _selectedAgentId;

  @override
  List<DashboardAgentOption> get autoRefreshAvailableAgents => _availableAgents;

  @override
  bool get autoRefreshPageLoading => _loading;

  @override
  Future<void> performAutoRefreshReload() async {
    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    final agentId = _selectedAgentId;
    markAutoRefreshCancelled();

    final generation = ++_sqlLoadGeneration;
    _sqlCancelScope?.cancelAll();
    final sqlScope = AgentQueriesCancelScope();
    _sqlCancelScope = sqlScope;
    widget.relayCancelScopeBinder?.call(sqlScope);

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
        _rows = const <ProdutoVendidoProdutoRankLucroRow>[];
        _error = null;
      });
      return;
    }

    final trimmedAgentId = agentId.trim();
    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: trimmedAgentId,
    );
    if (!mounted || generation != _sqlLoadGeneration) {
      return;
    }
    if (clientToken == null) {
      setState(() {
        _loading = false;
        _rows = const <ProdutoVendidoProdutoRankLucroRow>[];
        _error = AppLocalizations.of(context).agentSqlErrorAuthenticationFailed;
      });
      markAutoRefreshCancelled();
      return;
    }

    final range =
        (_filters['periodo'] as DateTimeRange?) ??
        _fullMonthInclusiveRange(DateTime.now());
    final sortKey = _filters['sortBy'] as String? ?? 'qtdItensVendido';
    final sortBy = switch (sortKey) {
      'totalValorLucro' => ProdutoVendidoProdutoRankLucroSortBy.totalValorLucro,
      _ => ProdutoVendidoProdutoRankLucroSortBy.qtdItensVendido,
    };

    final result = await _loadRanking(
      userId: userId,
      agentId: trimmedAgentId,
      filter: ProdutoVendidoProdutoRankLucroFilter(
        dataVendaInicio: range.start,
        dataVendaFim: range.end,
        sortBy: sortBy,
      ),
      clientToken: clientToken,
      cancelScope: sqlScope,
    );

    if (!mounted || generation != _sqlLoadGeneration) {
      return;
    }

    result.fold(
      (rows) {
        setState(() {
          _rows = rows;
          _loading = false;
          _error = null;
        });
        markAutoRefreshSuccess();
      },
      (exception) {
        setState(() {
          _loading = false;
          _rows = const <ProdutoVendidoProdutoRankLucroRow>[];
          _error = _failureMessage(exception);
        });
        markAutoRefreshFailure();
      },
    );
  }

  String _failureMessage(Object exception) {
    final err = exception;
    return err is AppFailure ? err.displayMessage : exception.toString();
  }

  void _onFiltersChanged(Map<String, Object?> next) {
    final nextAgentId = (next['agentId'] as String?)?.trim();
    final normalizedAgentId = nextAgentId == null || nextAgentId.isEmpty
        ? null
        : nextAgentId;
    final nextFilters = Map<String, Object?>.from(next)..remove('agentId');
    setState(() {
      _selectedAgentId = normalizedAgentId;
      _filters = nextFilters;
    });
    unawaited(_sessionService.setSelectedAgentId(normalizedAgentId));
    unawaited(_sessionService.persistProdutoRankLucroFilters(nextFilters));
    unawaited(_reload());
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
        return _SalesProdutoRankLucroFiltersSheet(
          l10n: AppLocalizations.of(context),
          availableAgents: _availableAgents,
          initialSelectedAgentId: _selectedAgentId,
          initialPeriod: _filters['periodo'] as DateTimeRange?,
          initialSortKey: _filters['sortBy'] as String?,
          onApply: _onFiltersChanged,
        );
      },
    );
  }

  ProdutoVendidoProdutoRankLucroSortBy _sortByEnum(String? key) {
    return switch (key) {
      'totalValorLucro' => ProdutoVendidoProdutoRankLucroSortBy.totalValorLucro,
      _ => ProdutoVendidoProdutoRankLucroSortBy.qtdItensVendido,
    };
  }

  num _chartValueFor(ProdutoVendidoProdutoRankLucroRow row, String? sortKey) {
    final enumKey = _sortByEnum(sortKey);
    return switch (enumKey) {
      ProdutoVendidoProdutoRankLucroSortBy.totalValorLucro =>
        row.totalValorLucro,
      _ => row.qtdItensVendido,
    };
  }

  int _rowRankOf(ProdutoVendidoProdutoRankLucroRow row) {
    final index = _rows.indexOf(row);
    return index >= 0 ? index + 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final theme = Theme.of(context);
    final sortKey = _filters['sortBy'] as String? ?? 'qtdItensVendido';
    final metricProfit = sortKey == 'totalValorLucro';
    final range =
        (_filters['periodo'] as DateTimeRange?) ??
        _fullMonthInclusiveRange(DateTime.now());
    final periodSubtitle =
        '${AppBrFormatters.shortDateFormat.format(range.start)} – '
        '${AppBrFormatters.shortDateFormat.format(range.end)}';
    final axisFormat = metricProfit
        ? AppBrFormatters.compactCurrencyFormat
        : NumberFormat.decimalPattern('pt_BR');

    final selectedBranch = _availableAgents
        .cast<DashboardAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == _selectedAgentId,
          orElse: () => null,
        );
    final selectedBranchName =
        selectedBranch?.name ?? l10n.salesBranchPickerEmpty;
    final metricLabel = metricProfit
        ? l10n.salesProdutoRankLucroSortProfit
        : l10n.salesProdutoRankLucroSortQuantity;
    final metricSubtitle = 'Top 15 • $metricLabel';

    final maxValue = _rows.isEmpty
        ? 0.0
        : _rows
              .map((r) => _chartValueFor(r, sortKey))
              .reduce((a, b) => a > b ? a : b)
              .toDouble();

    final chartStyles = AppHorizontalProgressChartStyle(
      barColor: theme.appColors.primary,
      trackColor: theme.colorScheme.surfaceContainerHigh,
      rowSpacing: tokens.gapMd,
      barHeight: 10,
      rowPadding: EdgeInsets.symmetric(vertical: tokens.gapXs),
      valueTextStyle: theme.appTypography.body.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.appColors.primary,
      ),
    );

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
            onSectionLabelTap: () => context.goTo(AppRoute.sales),
            title: l10n.salesCardProdutoRankLucroTitle,
            subtitle: l10n.salesHubSubtitle,
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
                label: l10n.salesProdutoRankLucroFilterPeriod,
                value: periodSubtitle,
              ),
              SalesCardFilterSummaryItem(
                label: l10n.salesProdutoRankLucroFilterSortBy,
                value: metricLabel,
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
          SizedBox(height: tokens.sectionSpacing),
          if (_selectedAgentId == null)
            AppInlineErrorPanel(
              tone: AppInlinePanelTone.informational,
              title: l10n.salesBranchRequiredTitle,
              message: l10n.salesBranchRequiredMessage,
            )
          else if (_error != null && _error!.trim().isNotEmpty)
            AppInlineErrorPanel(
              message: _error!,
              onRetry: () => unawaited(_reload()),
            )
          else
            AppSectionCard(
              child:
                  AppHorizontalProgressChart<ProdutoVendidoProdutoRankLucroRow>(
                    titleWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.salesProdutoRankLucroChartTitle,
                          style: theme.appTypography.sectionHeaderH2.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: tokens.gapXs),
                        Text(
                          periodSubtitle,
                          style: theme.appTypography.caption.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: tokens.gapXs / 2),
                        Text(
                          metricSubtitle,
                          style: theme.appTypography.utilityOverline.copyWith(
                            color: theme.appColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    items: _rows,
                    labelBuilder: (r) => r.nomeProduto.trim(),
                    valueBuilder: (r) => _chartValueFor(r, sortKey).toDouble(),
                    maxValue: maxValue,
                    isLoading: _loading && _error == null,
                    rowLeadingBuilder: (context, row) =>
                        _RankBadge(rank: _rowRankOf(row)),
                    rowTooltipBuilder: (r, value, _) {
                      final name = r.nomeProduto.trim();
                      final text = metricProfit
                          ? AppBrFormatters.smartCompactCurrency(value)
                          : axisFormat.format(value);
                      return '$name • $text';
                    },
                    valueLabelBuilder: (r, value, _) => metricProfit
                        ? AppBrFormatters.smartCompactCurrency(value)
                        : axisFormat.format(value),
                    showDividers: true,
                    style: chartStyles,
                    wrapInCard: false,
                    emptyPlaceholder: Center(
                      child: Text(
                        l10n.chartComparisonEmptyDefault,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
            ),
        ],
      ),
    );
  }
}

class _SalesProdutoRankLucroFiltersSheet extends StatefulWidget {
  const _SalesProdutoRankLucroFiltersSheet({
    required this.l10n,
    required this.availableAgents,
    required this.initialSelectedAgentId,
    required this.initialPeriod,
    required this.initialSortKey,
    required this.onApply,
  });

  final AppLocalizations l10n;
  final List<DashboardAgentOption> availableAgents;
  final String? initialSelectedAgentId;
  final DateTimeRange? initialPeriod;
  final String? initialSortKey;
  final ValueChanged<Map<String, Object?>> onApply;

  @override
  State<_SalesProdutoRankLucroFiltersSheet> createState() =>
      _SalesProdutoRankLucroFiltersSheetState();
}

class _SalesProdutoRankLucroFiltersSheetState
    extends State<_SalesProdutoRankLucroFiltersSheet> {
  String? _selectedAgentId;
  DateTimeRange? _period;
  String? _sortKey;

  DateTimeRange get _defaultPeriod {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedAgentId = widget.initialSelectedAgentId;
    _period = widget.initialPeriod;
    _sortKey = widget.initialSortKey ?? 'qtdItensVendido';
  }

  void _apply() {
    final selectedAgentId = _selectedAgentId;
    if (selectedAgentId == null || selectedAgentId.trim().isEmpty) {
      return;
    }
    widget.onApply(<String, Object?>{
      'agentId': selectedAgentId,
      'periodo': _period,
      'sortBy': _sortKey,
    });
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _period = _defaultPeriod;
      _sortKey = 'qtdItensVendido';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final selectedAgentMissingToken =
        _selectedAgentId != null &&
        widget.availableAgents.any(
          (agent) =>
              agent.agentId == _selectedAgentId &&
              agent.missingLocalClientToken,
        );

    return SalesFiltersSheetScaffold(
      title: widget.l10n.reportFiltersTitleWithContext(
        widget.l10n.salesCardProdutoRankLucroTitle,
      ),
      description: widget.l10n.reportFiltersDescription,
      primaryActionLabel: widget.l10n.reportFiltersApplyAction,
      secondaryActionLabel: widget.l10n.reportFiltersClearAction,
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
              title: widget.l10n.salesBranchFilterLabel,
              subtitle: widget.l10n.salesBranchRequiredMessage,
              requiredBadgeLabel: widget.l10n.reportFiltersRequiredCount(1),
            ),
            SizedBox(height: tokens.gapSm),
            SalesBranchPickerControl(
              l10n: widget.l10n,
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
                message: widget.l10n.salesBranchFilterMissingClientTokenBanner,
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            SalesFiltersSectionHeader(
              title: widget.l10n.reportFiltersTitle,
              subtitle: widget.l10n.reportFiltersDescription,
            ),
            SizedBox(height: tokens.gapSm),
            AppSectionCard(
              color: theme.colorScheme.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppDateRangePickerField(
                    label: widget.l10n.salesProdutoRankLucroFilterPeriod,
                    pickerTitle: widget.l10n.salesProdutoRankLucroFilterPeriod,
                    value: _period,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    density: AppTextFieldDensity.compact,
                    onChanged: (value) {
                      setState(() => _period = value);
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDropdownField<String>(
                    label: widget.l10n.salesProdutoRankLucroFilterSortBy,
                    value: _sortKey ?? 'qtdItensVendido',
                    density: AppTextFieldDensity.compact,
                    options: <AppDropdownOption<String>>[
                      AppDropdownOption<String>(
                        value: 'qtdItensVendido',
                        label: widget.l10n.salesProdutoRankLucroSortQuantity,
                      ),
                      AppDropdownOption<String>(
                        value: 'totalValorLucro',
                        label: widget.l10n.salesProdutoRankLucroSortProfit,
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _sortKey = value);
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

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;

    final (background, foreground, icon) = switch (rank) {
      1 => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        Icons.workspace_premium_rounded,
      ),
      2 => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        Icons.military_tech_rounded,
      ),
      3 => (
        colors.tertiaryFixed,
        colors.onTertiaryFixed,
        Icons.stars_rounded,
      ),
      _ => (
        theme.colorScheme.surfaceContainerHigh,
        colors.onSurfaceVariant,
        null,
      ),
    };
    final showMedal = rank >= 1 && rank <= 3;

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      ),
      child: showMedal
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 12, color: foreground),
                Text(
                  '$rank',
                  style: theme.appTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: foreground,
                    height: 1,
                  ),
                ),
              ],
            )
          : Text(
              rank > 0 ? '$rank' : '–',
              style: theme.appTypography.caption.copyWith(
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
    );
  }
}
