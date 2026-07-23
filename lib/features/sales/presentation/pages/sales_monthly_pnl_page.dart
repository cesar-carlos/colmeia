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
import 'package:colmeia/features/sales/application/load_sales_monthly_pnl_screen_batch_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_single_agent_auto_refresh_mixin.dart';
import 'package:colmeia/features/sales/presentation/share/sales_chart_share_export_filter.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_anchor_month_support.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_anchor_month_filters_context.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_actions_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_branch_anchor_month_filters_sheet.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_daily_totals_chart_card.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_monthly_pnl_bar_chart_card.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_monthly_pnl_line_chart.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_monthly_pnl_line_chart_fullscreen.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesMonthlyPnlPage extends StatefulWidget {
  const SalesMonthlyPnlPage({
    required this.sessionService,
    required this.loadSalesAvailableAgentsUseCase,
    required this.loadSalesMonthlyPnlScreenBatchUseCase,
    required this.resolveSalesAgentClientTokenUseCase,
    this.relayCancelScopeBinder,
    super.key,
  });

  final SalesSessionService sessionService;
  final LoadAvailableAgentsForSales loadSalesAvailableAgentsUseCase;
  final LoadSalesMonthlyPnlScreenBatchUseCase
  loadSalesMonthlyPnlScreenBatchUseCase;
  final ResolveSalesAgentClientTokenUseCase resolveSalesAgentClientTokenUseCase;
  final AgentQueriesRelayCancelScopeBinder? relayCancelScopeBinder;

  @override
  State<SalesMonthlyPnlPage> createState() => _SalesMonthlyPnlPageState();
}

class _SalesMonthlyPnlPageState extends State<SalesMonthlyPnlPage>
    with
        AutoRefreshStateMixin<SalesMonthlyPnlPage>,
        SalesSingleAgentAutoRefreshMixin<SalesMonthlyPnlPage>,
        SalesCardAutoRefreshBinding<SalesMonthlyPnlPage>,
        AgentQueryRetryAfterHost<SalesMonthlyPnlPage> {
  late final SalesSessionService _sessionService;
  late final LoadAvailableAgentsForSales _loadAgentsUseCase;
  late final LoadSalesMonthlyPnlScreenBatchUseCase _loadScreenBatch;
  late final ResolveSalesAgentClientTokenUseCase _resolveClientTokenUseCase;

  String? _selectedAgentId;
  List<DashboardAgentOption> _availableAgents = <DashboardAgentOption>[];
  late DashboardYearMonth _anchorYearMonth;
  DashboardDateRange? _dailyTotalsDateRange;
  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;

  List<SalesMonthlyPnlPoint> _points = const <SalesMonthlyPnlPoint>[];
  List<DailySalesTrendPoint> _dailyPoints = const <DailySalesTrendPoint>[];
  bool _loading = false;
  bool _chartLoadFailed = false;
  AppFailure? _chartLoadFailure;
  String? _chartLoadFailureMessage;
  bool _dailyChartLoadFailed = false;
  AppFailure? _dailyChartLoadFailure;
  String? _dailyChartLoadFailureMessage;
  int _chartLoadGeneration = 0;
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
    _loadScreenBatch = widget.loadSalesMonthlyPnlScreenBatchUseCase;
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

  Future<void> _reload({bool force = false}) =>
      reloadWithAutoRefresh(force: force);

  @override
  SalesSessionService get salesSessionService => _sessionService;

  @override
  String get salesAutoRefreshCardId => SalesAutoRefreshCardIds.monthlyPnl;

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
    final generation = ++_chartLoadGeneration;
    _sqlCancelScope?.cancelAll();
    final sqlScope = AgentQueriesCancelScope();
    _sqlCancelScope = sqlScope;
    widget.relayCancelScopeBinder?.call(sqlScope);
    markAutoRefreshCancelled();

    setState(() {
      _loading = true;
      _chartLoadFailed = false;
      _chartLoadFailure = null;
      _chartLoadFailureMessage = null;
      _dailyChartLoadFailed = false;
      _dailyChartLoadFailure = null;
      _dailyChartLoadFailureMessage = null;
    });

    if (userId == null || agentId == null || agentId.trim().isEmpty) {
      if (!mounted || generation != _chartLoadGeneration) {
        return;
      }
      setState(() {
        _loading = false;
        _points = const <SalesMonthlyPnlPoint>[];
        _chartLoadFailed = false;
        _chartLoadFailureMessage = null;
        _dailyPoints = const <DailySalesTrendPoint>[];
        _dailyChartLoadFailed = false;
        _dailyChartLoadFailure = null;
        _dailyChartLoadFailureMessage = null;
      });
      return;
    }

    final trimmed = agentId.trim();
    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: trimmed,
    );
    if (!mounted || generation != _chartLoadGeneration) {
      return;
    }
    if (clientToken == null) {
      final authMsg = AppLocalizations.of(
        context,
      ).agentSqlErrorAuthenticationFailed;
      setState(() {
        _loading = false;
        _points = const <SalesMonthlyPnlPoint>[];
        _chartLoadFailed = true;
        _chartLoadFailureMessage = authMsg;
        _dailyPoints = const <DailySalesTrendPoint>[];
        _dailyChartLoadFailed = true;
        _dailyChartLoadFailureMessage = authMsg;
      });
      markAutoRefreshCancelled();
      return;
    }

    final bundle = await _loadScreenBatch(
      userId: userId,
      agentId: trimmed,
      anchor: anchor,
      dailySaleDateRange: _dailyTotalsDateRange,
      clientToken: clientToken,
      cancelScope: sqlScope,
    );

    if (!mounted || generation != _chartLoadGeneration) {
      return;
    }
    setState(() {
      _points = bundle.monthlyPoints;
      _chartLoadFailed = bundle.monthlyLoadFailed;
      _chartLoadFailure = bundle.monthlyLoadFailure;
      _chartLoadFailureMessage = bundle.monthlyLoadFailure == null
          ? null
          : agentQueryFailureUserMessage(
              bundle.monthlyLoadFailure!,
              AppLocalizations.of(context),
            );
      _dailyPoints = bundle.dailyPoints;
      _dailyChartLoadFailed = bundle.dailyLoadFailed;
      _dailyChartLoadFailure = bundle.dailyLoadFailure;
      _dailyChartLoadFailureMessage = bundle.dailyLoadFailure == null
          ? null
          : agentQueryFailureUserMessage(
              bundle.dailyLoadFailure!,
              AppLocalizations.of(context),
            );
      _loading = false;
    });
    onAgentQueryLoadFailure(
      bundle.monthlyLoadFailure ?? bundle.dailyLoadFailure,
    );
    if (bundle.monthlyLoadFailed || bundle.dailyLoadFailed) {
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
    unawaited(_reload(force: true));
  }

  String _dailyTotalsPeriodSummaryLine(AppLocalizations l10n) {
    final range = _dailyTotalsDateRange;
    if (range == null) {
      return formatSalesAnchorMonthLabel(context, _anchorYearMonth);
    }
    return l10n.salesDailyTotalsFilterSummaryCustomRangeValue(
      AppBrFormatters.shortDate(range.startInclusive),
      AppBrFormatters.shortDate(range.endInclusive),
    );
  }

  String _selectedBranchName(AppLocalizations l10n) {
    final selectedBranch = _availableAgents
        .cast<DashboardAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == _selectedAgentId,
          orElse: () => null,
        );
    return selectedBranch?.name ?? l10n.salesBranchPickerEmpty;
  }

  ChartShareExportHeaderContext _monthlyPnlExportHeaderContext(
    AppLocalizations l10n,
  ) {
    final rangeParameter = salesDailyTotalsRangeExportHeaderParameter(
      l10n: l10n,
      dailyTotalsDateRange: _dailyTotalsDateRange,
    );
    return buildSalesSingleAgentChartShareExportHeaderContext(
      l10n: l10n,
      agentName: _selectedBranchName(l10n),
      parameters: <ChartShareExportHeaderParameter>[
        salesAnchorMonthExportHeaderParameter(
          l10n: l10n,
          anchorMonthLabel: formatSalesAnchorMonthLabel(
            context,
            _anchorYearMonth,
          ),
        ),
        ?rangeParameter,
      ],
    );
  }

  String _monthlyPnlFullscreenFilterSummary(AppLocalizations l10n) {
    final formatted = formatChartShareExportHeaderContext(
      _monthlyPnlExportHeaderContext(l10n),
    );
    if (formatted != null) {
      return formatted;
    }
    return l10n.salesMonthlyPnlFullscreenFilterSummary(
      l10n.salesBranchFilterLabel,
      _selectedBranchName(l10n),
      l10n.salesMonthlyPnlFilterAnchorMonth,
      formatSalesAnchorMonthLabel(context, _anchorYearMonth),
    );
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
          filtersContext: SalesAnchorMonthFiltersContext.monthlyPnl,
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

  void _openChartFullscreen() {
    unawaited(
      pushSalesMonthlyPnlLineChartFullscreen(
        context: context,
        points: List<SalesMonthlyPnlPoint>.of(_points, growable: false),
        isLoading: _loading && _selectedAgentId != null,
        loadFailed: _chartLoadFailed,
        loadFailureMessage: _chartLoadFailureMessage,
        filterSummary: _monthlyPnlFullscreenFilterSummary(
          AppLocalizations.of(context),
        ),
        exportHeaderContext: _monthlyPnlExportHeaderContext(
          AppLocalizations.of(context),
        ),
      ),
    );
  }

  void _openBarChartFullscreen() {
    unawaited(
      pushSalesMonthlyPnlBarChartFullscreen(
        context: context,
        points: List<SalesMonthlyPnlPoint>.of(_points, growable: false),
        initialSession: _sessionService.restoreMonthlyPnlBarChartPreferences(),
        isLoading: _loading && _selectedAgentId != null,
        loadFailed: _chartLoadFailed,
        loadFailureMessage: _chartLoadFailureMessage,
        filterSummary: _monthlyPnlFullscreenFilterSummary(
          AppLocalizations.of(context),
        ),
        exportHeaderContext: _monthlyPnlExportHeaderContext(
          AppLocalizations.of(context),
        ),
      ),
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
            title: l10n.salesCardMonthlyPnlTitle,
            subtitle: l10n.salesMonthlyPnlPageSubtitle,
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
                value: _dailyTotalsPeriodSummaryLine(l10n),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                RepaintBoundary(
                  child: SalesMonthlyPnlLineChart(
                    l10n: l10n,
                    points: _points,
                    loadFailed: _chartLoadFailed,
                    loadFailure: _chartLoadFailure,
                    loadFailureMessage: _chartLoadFailureMessage,
                    isLoading: _loading && _selectedAgentId != null,
                    exportHeaderContext: _monthlyPnlExportHeaderContext(l10n),
                    onOpenFullscreen: _openChartFullscreen,
                    onRequestShare: (context, request) =>
                        context.shareChartFromRequest(request),
                  ),
                ),
                SizedBox(height: tokens.sectionSpacing),
                RepaintBoundary(
                  child: SalesMonthlyPnlBarChartCard(
                    l10n: l10n,
                    points: _points,
                    loadFailed: _chartLoadFailed,
                    loadFailure: _chartLoadFailure,
                    loadFailureMessage: _chartLoadFailureMessage,
                    isLoading: _loading && _selectedAgentId != null,
                    exportHeaderContext: _monthlyPnlExportHeaderContext(l10n),
                    initialSession: _sessionService
                        .restoreMonthlyPnlBarChartPreferences(),
                    persistSession:
                        _sessionService.persistMonthlyPnlBarChartPreferences,
                    onOpenFullscreen: _openBarChartFullscreen,
                    onRequestShare: (context, request) =>
                        context.shareChartFromRequest(request),
                  ),
                ),
                SizedBox(height: tokens.sectionSpacing),
                SalesDailyTotalsChartCard(
                  l10n: l10n,
                  points: _dailyPoints,
                  loadFailed: _dailyChartLoadFailed,
                  loadFailure: _dailyChartLoadFailure,
                  loadFailureMessage: _dailyChartLoadFailureMessage,
                  isLoading: _loading && _selectedAgentId != null,
                  dailySaleDateRange: _dailyTotalsDateRange,
                  exportHeaderContext: _monthlyPnlExportHeaderContext(l10n),
                  onRequestFullscreen: (context, request) =>
                      context.pushChartFullscreenFromRequest(request),
                  onRequestShare: (context, request) =>
                      context.shareChartFromRequest(request),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
