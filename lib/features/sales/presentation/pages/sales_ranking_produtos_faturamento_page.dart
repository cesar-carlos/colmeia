import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_ranking_produtos_faturamento_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_retry_after_host.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_single_agent_auto_refresh_mixin.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_actions_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_ranking_produtos_faturamento_branch_card.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/agent_query_error_panel.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fade_in.dart';
import 'package:colmeia/shared/widgets/forms/app_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SalesRankingProdutosFaturamentoPage extends StatefulWidget {
  const SalesRankingProdutosFaturamentoPage({
    required this.sessionService,
    required this.loadSalesAvailableAgentsUseCase,
    required this.resolveSalesAgentClientTokenUseCase,
    required this.loadRankingProdutosFaturamentoUseCase,
    this.relayCancelScopeBinder,
    super.key,
  });

  final SalesSessionService sessionService;
  final LoadAvailableAgentsForSales loadSalesAvailableAgentsUseCase;
  final ResolveSalesAgentClientTokenUseCase resolveSalesAgentClientTokenUseCase;
  final LoadRankingProdutosFaturamentoUseCase
  loadRankingProdutosFaturamentoUseCase;
  final AgentQueriesRelayCancelScopeBinder? relayCancelScopeBinder;

  @override
  State<SalesRankingProdutosFaturamentoPage> createState() =>
      _SalesRankingProdutosFaturamentoPageState();
}

class _SalesRankingProdutosFaturamentoPageState
    extends State<SalesRankingProdutosFaturamentoPage>
    with
        AutoRefreshStateMixin<SalesRankingProdutosFaturamentoPage>,
        SalesSingleAgentAutoRefreshMixin<SalesRankingProdutosFaturamentoPage>,
        SalesCardAutoRefreshBinding<SalesRankingProdutosFaturamentoPage>,
        AgentQueryRetryAfterHost<SalesRankingProdutosFaturamentoPage> {
  late final SalesSessionService _sessionService;
  late final ResolveSalesAgentClientTokenUseCase _resolveClientTokenUseCase;
  late final LoadAvailableAgentsForSales _loadAgentsUseCase;
  late final LoadRankingProdutosFaturamentoUseCase _loadRanking;

  String? _selectedAgentId;
  List<DashboardAgentOption> _availableAgents = <DashboardAgentOption>[];
  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;

  Map<String, Object?> _filters = <String, Object?>{};
  List<RankingProdutosFaturamentoRow> _rows =
      const <RankingProdutosFaturamentoRow>[];

  bool _loading = false;
  String? _error;
  AppFailure? _loadFailure;

  int _sqlLoadGeneration = 0;
  AgentQueriesCancelScope? _sqlCancelScope;

  DateTimeRange _fullMonthInclusiveRange(DateTime anchor) => DateTimeRange(
    start: DateTime(anchor.year, anchor.month),
    end: DateTime(anchor.year, anchor.month + 1, 0),
  );

  int get _quantidadeProdutos {
    final raw = _filters['quantidadeProdutos'];
    if (raw is int) {
      return raw.clamp(
        1,
        RankingProdutosFaturamentoFilter.maxQuantidadeProdutos,
      );
    }
    return 15;
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

  @override
  void initState() {
    super.initState();
    _sessionService = widget.sessionService;
    _resolveClientTokenUseCase = widget.resolveSalesAgentClientTokenUseCase;
    _loadAgentsUseCase = widget.loadSalesAvailableAgentsUseCase;
    _loadRanking = widget.loadRankingProdutosFaturamentoUseCase;
    _selectedAgentId = _sessionService.selectedAgentId;
    final restored = _sessionService.restoreRankingProdutosFaturamentoFilters();
    final defaultRange = _fullMonthInclusiveRange(DateTime.now());
    final restoredPeriod = restored['periodo'];
    final period = restoredPeriod is DateTimeRange
        ? restoredPeriod
        : defaultRange;
    final restoredQuantity = restored['quantidadeProdutos'];
    final quantity = restoredQuantity is int ? restoredQuantity : 15;
    _filters = <String, Object?>{
      'periodo': period,
      'quantidadeProdutos': quantity,
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
  String get salesAutoRefreshCardId =>
      SalesAutoRefreshCardIds.rankingProdutosFaturamento;

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
      _loadFailure = null;
    });

    if (userId == null || agentId == null || agentId.trim().isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _rows = const <RankingProdutosFaturamentoRow>[];
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
        _rows = const <RankingProdutosFaturamentoRow>[];
        _error = AppLocalizations.of(context).agentSqlErrorAuthenticationFailed;
      });
      markAutoRefreshCancelled();
      return;
    }

    final range =
        (_filters['periodo'] as DateTimeRange?) ??
        _fullMonthInclusiveRange(DateTime.now());

    final result = await _loadRanking(
      userId: userId,
      agentId: trimmedAgentId,
      filter: RankingProdutosFaturamentoFilter(
        dataVendaInicio: range.start,
        dataVendaFim: range.end,
        quantidadeProdutos: _quantidadeProdutos,
      ),
      clientToken: clientToken,
      cancelScope: sqlScope,
    );

    if (!mounted || generation != _sqlLoadGeneration) {
      return;
    }

    result.fold(
      (loadResult) {
        setState(() {
          _rows = loadResult.rows;
          _loading = false;
          _error = null;
          _loadFailure = null;
        });
        markAutoRefreshSuccess();
      },
      (exception) {
        final l10n = AppLocalizations.of(context);
        final failure = exception;
        setState(() {
          _loading = false;
          _rows = const <RankingProdutosFaturamentoRow>[];
          _loadFailure = failure;
          _error = _failureMessage(exception, l10n);
        });
        onAgentQueryLoadFailure(failure);
        markAutoRefreshFailure();
      },
    );
  }

  String _failureMessage(Object exception, AppLocalizations l10n) {
    return exception is AppFailure
        ? agentQueryFailureUserMessage(exception, l10n)
        : exception.toString();
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
    unawaited(
      _sessionService.persistRankingProdutosFaturamentoFilters(nextFilters),
    );
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
        return _SalesRankingProdutosFaturamentoFiltersSheet(
          l10n: AppLocalizations.of(context),
          availableAgents: _availableAgents,
          initialSelectedAgentId: _selectedAgentId,
          initialPeriod: _filters['periodo'] as DateTimeRange?,
          initialQuantidadeProdutos: _quantidadeProdutos,
          onApply: _onFiltersChanged,
        );
      },
    );
  }

  List<
    ({int codEmpresa, int codFilial, List<RankingProdutosFaturamentoRow> rows})
  >
  _branchSections() {
    final sections =
        <
          ({
            int codEmpresa,
            int codFilial,
            List<RankingProdutosFaturamentoRow> rows,
          })
        >[];
    int? currentEmpresa;
    int? currentFilial;
    List<RankingProdutosFaturamentoRow>? currentRows;

    void flush() {
      final rows = currentRows;
      final empresa = currentEmpresa;
      final filial = currentFilial;
      if (empresa != null &&
          filial != null &&
          rows != null &&
          rows.isNotEmpty) {
        sections.add((
          codEmpresa: empresa,
          codFilial: filial,
          rows: List<RankingProdutosFaturamentoRow>.from(rows),
        ));
      }
    }

    for (final row in _rows) {
      if (currentEmpresa != row.codEmpresa || currentFilial != row.codFilial) {
        flush();
        currentEmpresa = row.codEmpresa;
        currentFilial = row.codFilial;
        currentRows = <RankingProdutosFaturamentoRow>[];
      }
      currentRows!.add(row);
    }
    flush();
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;
    final theme = Theme.of(context);
    final range =
        (_filters['periodo'] as DateTimeRange?) ??
        _fullMonthInclusiveRange(DateTime.now());
    final periodSubtitle =
        '${AppBrFormatters.shortDateFormat.format(range.start)} – '
        '${AppBrFormatters.shortDateFormat.format(range.end)}';

    final selectedBranch = _availableAgents
        .cast<DashboardAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == _selectedAgentId,
          orElse: () => null,
        );
    final selectedBranchName =
        selectedBranch?.name ?? l10n.salesBranchPickerEmpty;
    final metricSubtitle =
        'Top $_quantidadeProdutos • ${l10n.salesRankingProdutosFaturamentoMetricFaturamento}';

    final sections = _branchSections();

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
            title: l10n.salesCardRankingProdutosFaturamentoTitle,
            subtitle: l10n.salesHubSubtitle,
          ),
          SizedBox(height: tokens.sectionSpacing),
          SalesCardFilterTrigger(
            onTap: () => unawaited(_openFiltersSheet()),
            buttonSemanticsLabel: l10n.reportFiltersButton,
            editActionLabel:
                l10n.salesRankingProdutosFaturamentoEditFiltersAction,
            footer: SalesAutoRefreshActionsRow(
              value: autoRefreshOption,
              onChanged: setAutoRefreshOption,
              onRefreshNow: () => unawaited(_reload()),
              enabled: canScheduleAutoRefresh,
              lastUpdatedAt: autoRefreshLastUpdatedAt,
              isPaused: autoRefreshIsPaused,
              pauseReason: autoRefreshPauseReason,
              l10n: l10n,
            ),
            summaryItems: <SalesCardFilterSummaryItem>[
              SalesCardFilterSummaryItem(
                label: l10n.salesBranchFilterLabel,
                value: selectedBranchName,
              ),
              SalesCardFilterSummaryItem(
                label: l10n.salesRankingProdutosFaturamentoFilterPeriod,
                value: periodSubtitle,
              ),
              SalesCardFilterSummaryItem(
                label: l10n.salesRankingProdutosFaturamentoFilterQuantidade,
                value: '$_quantidadeProdutos',
              ),
            ],
            enabled: !_loading,
          ),
          SizedBox(height: tokens.sectionSpacing),
          if (_selectedAgentId == null)
            AppInlineErrorPanel(
              tone: AppInlinePanelTone.informational,
              title: l10n.salesBranchRequiredTitle,
              message: l10n.salesBranchRequiredMessage,
            )
          else if (_loadFailure != null)
            AgentQueryErrorPanel.fromFailure(
              _loadFailure!,
              l10n,
              onRetry: () => unawaited(_reload()),
              retryCountdownLabel: agentQueryRetryCountdownLabel(l10n),
              supportContext: AgentQueryFailureSupportContext.environment(
                extra: <String, String>{
                  'agentId': ?_selectedAgentId,
                  'screen': 'sales_ranking_produtos_faturamento',
                },
              ),
            )
          else if (_error != null && _error!.trim().isNotEmpty)
            AppInlineErrorPanel(
              message: _error!,
              onRetry: () => unawaited(_reload()),
            )
          else if (_loading && sections.isEmpty)
            AppSkeleton(
              enabled: true,
              child: AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      l10n.salesRankingProdutosFaturamentoChartTitle,
                      style: theme.appTypography.sectionHeaderH2,
                    ),
                    SizedBox(height: tokens.gapMd),
                    Text(
                      metricSubtitle,
                      style: theme.appTypography.utilityOverline,
                    ),
                    SizedBox(height: tokens.contentSpacing),
                    SizedBox(
                      height: tokens.chartStandardHeight,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(),
                      ),
                    ),
                    SizedBox(height: tokens.contentSpacing),
                    const DecoratedBox(
                      decoration: BoxDecoration(),
                      child: SizedBox(height: 120),
                    ),
                  ],
                ),
              ),
            )
          else if (sections.isEmpty)
            AppSectionCard(
              child: Center(
                child: Text(
                  l10n.salesRankingProdutosFaturamentoEmptyMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...sections.map((section) {
              return Padding(
                padding: EdgeInsets.only(bottom: tokens.sectionSpacing),
                child: AppChartFadeIn(
                  child: SalesRankingProdutosFaturamentoBranchCard(
                    l10n: l10n,
                    codEmpresa: section.codEmpresa,
                    codFilial: section.codFilial,
                    branchDisplayName: selectedBranch?.name,
                    rows: section.rows,
                    metricSubtitle: metricSubtitle,
                    isLoading: _loading,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SalesRankingProdutosFaturamentoFiltersSheet extends StatefulWidget {
  const _SalesRankingProdutosFaturamentoFiltersSheet({
    required this.l10n,
    required this.availableAgents,
    required this.initialSelectedAgentId,
    required this.initialPeriod,
    required this.initialQuantidadeProdutos,
    required this.onApply,
  });

  final AppLocalizations l10n;
  final List<DashboardAgentOption> availableAgents;
  final String? initialSelectedAgentId;
  final DateTimeRange? initialPeriod;
  final int initialQuantidadeProdutos;
  final ValueChanged<Map<String, Object?>> onApply;

  @override
  State<_SalesRankingProdutosFaturamentoFiltersSheet> createState() =>
      _SalesRankingProdutosFaturamentoFiltersSheetState();
}

class _SalesRankingProdutosFaturamentoFiltersSheetState
    extends State<_SalesRankingProdutosFaturamentoFiltersSheet> {
  String? _selectedAgentId;
  DateTimeRange? _period;
  late final TextEditingController _quantidadeController;

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
    _quantidadeController = TextEditingController(
      text: '${widget.initialQuantidadeProdutos}',
    );
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    super.dispose();
  }

  void _apply() {
    final selectedAgentId = _selectedAgentId;
    if (selectedAgentId == null || selectedAgentId.trim().isEmpty) {
      return;
    }
    final parsedQuantity = int.tryParse(_quantidadeController.text.trim());
    if (parsedQuantity == null) {
      return;
    }
    widget.onApply(<String, Object?>{
      'agentId': selectedAgentId,
      'periodo': _period,
      'quantidadeProdutos': parsedQuantity.clamp(
        1,
        RankingProdutosFaturamentoFilter.maxQuantidadeProdutos,
      ),
    });
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _period = _defaultPeriod;
      _quantidadeController.text = '15';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final selectedAgentMissingToken =
        _selectedAgentId != null &&
        widget.availableAgents.any(
          (agent) =>
              agent.agentId == _selectedAgentId &&
              agent.missingLocalClientToken,
        );

    return SalesFiltersSheetScaffold(
      title: widget.l10n.reportFiltersTitleWithContext(
        widget.l10n.salesCardRankingProdutosFaturamentoTitle,
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
                    label:
                        widget.l10n.salesRankingProdutosFaturamentoFilterPeriod,
                    pickerTitle:
                        widget.l10n.salesRankingProdutosFaturamentoFilterPeriod,
                    value: _period,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    density: AppTextFieldDensity.compact,
                    onChanged: (value) {
                      setState(() => _period = value);
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppTextField(
                    controller: _quantidadeController,
                    label: widget
                        .l10n
                        .salesRankingProdutosFaturamentoFilterQuantidade,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    density: AppTextFieldDensity.compact,
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
