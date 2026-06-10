import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_retry_after_host.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/sales/application/load_sales_daily_totals_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_single_agent_auto_refresh_mixin.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_anchor_month_support.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_daily_totals_chart_copy.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_anchor_month_filters_context.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_actions_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_branch_anchor_month_filters_sheet.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_daily_totals_chart_card.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesDailyTotalsPage extends StatefulWidget {
  const SalesDailyTotalsPage({
    required this.sessionService,
    required this.loadSalesAvailableAgentsUseCase,
    required this.loadSalesDailyTotalsUseCase,
    required this.resolveSalesAgentClientTokenUseCase,
    this.relayCancelScopeBinder,
    super.key,
  });

  final SalesSessionService sessionService;
  final LoadAvailableAgentsForSales loadSalesAvailableAgentsUseCase;
  final LoadSalesDailyTotalsUseCase loadSalesDailyTotalsUseCase;
  final ResolveSalesAgentClientTokenUseCase resolveSalesAgentClientTokenUseCase;
  final AgentQueriesRelayCancelScopeBinder? relayCancelScopeBinder;

  @override
  State<SalesDailyTotalsPage> createState() => _SalesDailyTotalsPageState();
}

class _SalesDailyTotalsPageState extends State<SalesDailyTotalsPage>
    with
        AutoRefreshStateMixin<SalesDailyTotalsPage>,
        SalesSingleAgentAutoRefreshMixin<SalesDailyTotalsPage>,
        SalesCardAutoRefreshBinding<SalesDailyTotalsPage>,
        AgentQueryRetryAfterHost<SalesDailyTotalsPage> {
  late final SalesSessionService _sessionService;
  late final LoadAvailableAgentsForSales _loadAgentsUseCase;
  late final LoadSalesDailyTotalsUseCase _loadDailyTotals;
  late final ResolveSalesAgentClientTokenUseCase _resolveClientTokenUseCase;

  String? _selectedAgentId;
  List<DashboardAgentOption> _availableAgents = const <DashboardAgentOption>[];
  late DashboardYearMonth _anchorYearMonth;
  DashboardDateRange? _dailyTotalsDateRange;
  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;

  List<DailySalesTrendPoint> _dailyPoints = const <DailySalesTrendPoint>[];
  bool _loading = false;
  bool _loadFailed = false;
  AppFailure? _loadFailure;
  String? _loadFailureMessage;
  int _loadGeneration = 0;
  AgentQueriesCancelScope? _sqlCancelScope;

  @override
  void dispose() {
    _sqlCancelScope?.cancelAll();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _sessionService = widget.sessionService;
    _loadAgentsUseCase = widget.loadSalesAvailableAgentsUseCase;
    _loadDailyTotals = widget.loadSalesDailyTotalsUseCase;
    _resolveClientTokenUseCase = widget.resolveSalesAgentClientTokenUseCase;
    _selectedAgentId = _sessionService.selectedAgentId;
    _anchorYearMonth =
        _sessionService.restoreSalesChartReferenceMonth() ??
        DashboardYearMonth.fromDate(DateTime.now());
    _dailyTotalsDateRange =
        _sessionService.restoreSalesDailyTotalsUseCustomRange()
        ? _sessionService.restoreSalesDailyTotalsDateRange()
        : null;
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

  Future<void> _reload() => reloadWithAutoRefresh();

  @override
  SalesSessionService get salesSessionService => _sessionService;

  @override
  String get salesAutoRefreshCardId => SalesAutoRefreshCardIds.dailyTotals;

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
    final anchor = _anchorYearMonth;
    final generation = ++_loadGeneration;
    _sqlCancelScope?.cancelAll();
    final sqlScope = AgentQueriesCancelScope();
    _sqlCancelScope = sqlScope;
    widget.relayCancelScopeBinder?.call(sqlScope);
    markAutoRefreshCancelled();

    setState(() {
      _loading = true;
      _loadFailed = false;
      _loadFailure = null;
      _loadFailureMessage = null;
    });

    if (userId == null || agentId == null || agentId.trim().isEmpty) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _loading = false;
        _dailyPoints = const <DailySalesTrendPoint>[];
        _loadFailed = false;
        _loadFailureMessage = null;
      });
      return;
    }

    final trimmed = agentId.trim();
    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: trimmed,
    );
    if (!mounted || generation != _loadGeneration) {
      return;
    }
    if (clientToken == null) {
      final authMsg = AppLocalizations.of(
        context,
      ).agentSqlErrorAuthenticationFailed;
      setState(() {
        _loading = false;
        _dailyPoints = const <DailySalesTrendPoint>[];
        _loadFailed = true;
        _loadFailureMessage = authMsg;
      });
      markAutoRefreshCancelled();
      return;
    }

    final bundle = await _loadDailyTotals(
      userId: userId,
      agentId: trimmed,
      anchor: anchor,
      dailySaleDateRange: _dailyTotalsDateRange,
      clientToken: clientToken,
      cancelScope: sqlScope,
    );

    if (!mounted || generation != _loadGeneration) {
      return;
    }
    setState(() {
      _dailyPoints = bundle.points;
      _loadFailed = bundle.loadFailed;
      _loadFailure = bundle.loadFailure;
      _loadFailureMessage = bundle.loadFailure == null
          ? null
          : agentQueryFailureUserMessage(
              bundle.loadFailure!,
              AppLocalizations.of(context),
            );
      _loading = false;
    });
    onAgentQueryLoadFailure(bundle.loadFailure);
    if (bundle.loadFailed) {
      markAutoRefreshFailure();
      return;
    }
    markAutoRefreshSuccess();
  }

  void _onFiltersChanged(Map<String, Object?> next) {
    final nextAgentId = (next['agentId'] as String?)?.trim();
    final normalizedAgentId = nextAgentId == null || nextAgentId.isEmpty
        ? null
        : nextAgentId;
    final anchor = next['anchorYearMonth'] as DashboardYearMonth?;
    final dailyRange = next['dailyTotalsDateRange'] as DashboardDateRange?;

    setState(() {
      _selectedAgentId = normalizedAgentId;
      if (anchor != null) {
        _anchorYearMonth = anchor;
      }
      _dailyTotalsDateRange = dailyRange;
    });
    unawaited(_sessionService.setSelectedAgentId(normalizedAgentId));
    if (anchor != null) {
      unawaited(_sessionService.persistSalesChartReferenceMonth(anchor));
    }
    unawaited(
      _sessionService.persistSalesDailyTotalsDateRange(
        useCustomRange: dailyRange != null,
        range: dailyRange,
      ),
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
        return SalesBranchAnchorMonthFiltersSheet(
          l10n: AppLocalizations.of(context),
          filtersContext: SalesAnchorMonthFiltersContext.dailyTotals,
          availableAgents: _availableAgents,
          initialSelectedAgentId: _selectedAgentId,
          initialAnchorYearMonth: _anchorYearMonth,
          initialDailyTotalsUseCustomRange: _dailyTotalsDateRange != null,
          initialDailyTotalsDateRange: _dailyTotalsDateRange,
          onApply: _onFiltersChanged,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;
    final selectedBranch = _availableAgents
        .cast<DashboardAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == _selectedAgentId,
          orElse: () => null,
        );
    final selectedBranchName =
        selectedBranch?.name ?? l10n.salesBranchPickerEmpty;
    final anchorLabel = formatSalesAnchorMonthLabel(context, _anchorYearMonth);
    final dailyRange = _dailyTotalsDateRange;
    final introSubtitle = salesDailyTotalsEffectiveSubtitle(
      l10n,
      dailySaleDateRange: dailyRange,
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
            title: l10n.salesCardResumoTotalDiarioVendasTitle,
            subtitle: introSubtitle,
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
                label: l10n.salesMonthlyPnlFilterAnchorMonth,
                value: anchorLabel,
              ),
              SalesCardFilterSummaryItem(
                label: l10n.salesDailyTotalsFilterSummaryLabel,
                value: dailyRange == null
                    ? anchorLabel
                    : l10n.salesDailyTotalsFilterSummaryCustomRangeValue(
                        AppBrFormatters.shortDate(dailyRange.startInclusive),
                        AppBrFormatters.shortDate(dailyRange.endInclusive),
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
            refreshNowEnabled:
                canScheduleAutoRefresh && !isAgentQueryRetryCooldown,
            lastUpdatedAt: autoRefreshLastUpdatedAt,
            isPaused: autoRefreshIsPaused || isAgentQueryRetryCooldown,
            pauseReason: isAgentQueryRetryCooldown
                ? null
                : autoRefreshPauseReason,
            l10n: l10n,
          ),
          SizedBox(height: tokens.sectionSpacing),
          if (_selectedAgentId == null)
            AppInlineErrorPanel(
              tone: AppInlinePanelTone.informational,
              title: l10n.salesBranchRequiredTitle,
              message: l10n.salesBranchRequiredMessage,
            )
          else
            SalesDailyTotalsChartCard(
              l10n: l10n,
              points: _dailyPoints,
              loadFailed: _loadFailed,
              loadFailure: _loadFailure,
              loadFailureMessage: _loadFailureMessage,
              isLoading: _loading && _selectedAgentId != null,
              dailySaleDateRange: _dailyTotalsDateRange,
              onRequestFullscreen: (context, request) =>
                  context.pushChartFullscreenFromRequest(request),
              onRequestShare: (context, request) =>
                  context.shareChartFromRequest(request),
            ),
        ],
      ),
    );
  }
}
