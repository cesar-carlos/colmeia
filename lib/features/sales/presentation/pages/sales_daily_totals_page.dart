import 'dart:async';

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/overview/domain/entities/overview_daily_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_daily_totals_use_case.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_anchor_month_support.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_anchor_month_filters_context.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_branch_anchor_month_filters_sheet.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_daily_totals_chart_card.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesDailyTotalsPage extends StatefulWidget {
  const SalesDailyTotalsPage({super.key});

  @override
  State<SalesDailyTotalsPage> createState() => _SalesDailyTotalsPageState();
}

class _SalesDailyTotalsPageState extends State<SalesDailyTotalsPage> {
  late final SalesPreferences _prefs;
  late final LoadAvailableAgentsForSales _loadAgentsUseCase;
  late final LoadSalesDailyTotalsUseCase _loadDailyTotals;
  late final AgentClientTokenReader _clientTokenReader;

  String? _selectedAgentId;
  List<OverviewAgentOption> _availableAgents = const <OverviewAgentOption>[];
  late OverviewYearMonth _anchorYearMonth;
  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;

  List<OverviewDailySalesTrendPoint> _dailyPoints =
      const <OverviewDailySalesTrendPoint>[];
  bool _loading = false;
  bool _loadFailed = false;
  String? _loadFailureMessage;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _prefs = getIt<SalesPreferences>();
    _loadAgentsUseCase = getIt<LoadAvailableAgentsForSales>();
    _loadDailyTotals = getIt<LoadSalesDailyTotalsUseCase>();
    _clientTokenReader = getIt<AgentClientTokenReader>();
    _selectedAgentId = _prefs.selectedAgentId;
    _anchorYearMonth =
        _prefs.restoreSalesChartReferenceMonth() ??
        OverviewYearMonth.fromDate(DateTime.now());
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

  Future<void> _reload() async {
    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    final agentId = _selectedAgentId;
    final anchor = _anchorYearMonth;
    final generation = ++_loadGeneration;

    setState(() {
      _loading = true;
      _loadFailed = false;
      _loadFailureMessage = null;
    });

    if (userId == null || agentId == null || agentId.trim().isEmpty) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _loading = false;
        _dailyPoints = const <OverviewDailySalesTrendPoint>[];
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
        _dailyPoints = const <OverviewDailySalesTrendPoint>[];
        _loadFailed = true;
        _loadFailureMessage = authMsg;
      });
      return;
    }

    final bundle = await _loadDailyTotals(
      userId: userId,
      agentId: trimmed,
      anchor: anchor,
      clientToken: clientToken,
    );

    if (!mounted || generation != _loadGeneration) {
      return;
    }
    setState(() {
      _dailyPoints = bundle.points;
      _loadFailed = bundle.loadFailed;
      _loadFailureMessage = bundle.loadFailureMessage;
      _loading = false;
    });
  }

  void _onFiltersChanged(Map<String, Object?> next) {
    final nextAgentId = (next['agentId'] as String?)?.trim();
    final normalizedAgentId = nextAgentId == null || nextAgentId.isEmpty
        ? null
        : nextAgentId;
    final anchor = next['anchorYearMonth'] as OverviewYearMonth?;

    setState(() {
      _selectedAgentId = normalizedAgentId;
      if (anchor != null) {
        _anchorYearMonth = anchor;
      }
    });
    unawaited(_prefs.setSelectedAgentId(normalizedAgentId));
    if (anchor != null) {
      unawaited(_prefs.persistSalesChartReferenceMonth(anchor));
    }
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
          onApply: _onFiltersChanged,
        );
      },
    );
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
            title: l10n.salesCardResumoTotalDiarioVendasTitle,
            subtitle: l10n.salesDailyTotalsChartSubtitle,
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
          else
            SalesDailyTotalsChartCard(
              l10n: l10n,
              points: _dailyPoints,
              loadFailed: _loadFailed,
              loadFailureMessage: _loadFailureMessage,
              isLoading: _loading && _selectedAgentId != null,
            ),
        ],
      ),
    );
  }
}
