import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/overview/domain/entities/overview_daily_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_daily_totals_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_monthly_pnl_lines_use_case.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/sales_monthly_pnl_chart_keys.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_anchor_month_support.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_anchor_month_filters_context.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_branch_anchor_month_filters_sheet.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_daily_totals_chart_card.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_monthly_pnl_bar_chart_card.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

const double _kSalesMonthlyPnlMinChartWidth = 560;
const double _kSalesMonthlyPnlMonthSlotWidth = 72;
const double _kSalesMonthlyPnlChartHorizontalPadding = 24;

String _formatChartMonthShortLabel(
  SalesMonthlyPnlPoint point,
  String localeTag,
) {
  return DateFormat(
    'MMM/yy',
    localeTag,
  ).format(DateTime(point.year, point.month));
}

String _formatChartMonthLongLabel(
  SalesMonthlyPnlPoint point,
  String localeTag,
) {
  return DateFormat.yMMM(localeTag).format(DateTime(point.year, point.month));
}

String _tooltipSeriesLabel(
  AppLocalizations l10n,
  int seriesIndex,
) {
  return switch (seriesIndex) {
    1 => l10n.salesMonthlyPnlSeriesProfitLabel,
    2 => l10n.salesMonthlyPnlSeriesCostLabel,
    _ => l10n.salesMonthlyPnlSeriesSalesLabel,
  };
}

double _tooltipSeriesValue(
  SalesMonthlyPnlPoint point,
  int seriesIndex,
) {
  return switch (seriesIndex) {
    1 => point.lucro,
    2 => point.custoMercadoria,
    _ => point.venda,
  };
}

double _resolveSalesMonthlyPnlChartWidth({
  required double availableWidth,
  required int pointCount,
}) {
  final contentWidth =
      (pointCount * _kSalesMonthlyPnlMonthSlotWidth) +
      _kSalesMonthlyPnlChartHorizontalPadding;
  return math.max(
    availableWidth,
    math.max(_kSalesMonthlyPnlMinChartWidth, contentWidth),
  );
}

class SalesMonthlyPnlPage extends StatefulWidget {
  const SalesMonthlyPnlPage({super.key});

  @override
  State<SalesMonthlyPnlPage> createState() => _SalesMonthlyPnlPageState();
}

class _SalesMonthlyPnlPageState extends State<SalesMonthlyPnlPage> {
  late final SalesPreferences _prefs;
  late final LoadAvailableAgentsForSales _loadAgentsUseCase;
  late final LoadSalesMonthlyPnlLinesUseCase _loadPnlLines;
  late final LoadSalesDailyTotalsUseCase _loadDailyTotals;
  late final AgentClientTokenReader _clientTokenReader;

  String? _selectedAgentId;
  List<OverviewAgentOption> _availableAgents = <OverviewAgentOption>[];
  late OverviewYearMonth _anchorYearMonth;
  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;

  List<SalesMonthlyPnlPoint> _points = const <SalesMonthlyPnlPoint>[];
  List<OverviewDailySalesTrendPoint> _dailyPoints =
      const <OverviewDailySalesTrendPoint>[];
  bool _loading = false;
  bool _chartLoadFailed = false;
  String? _chartLoadFailureMessage;
  bool _dailyChartLoadFailed = false;
  String? _dailyChartLoadFailureMessage;
  int _chartLoadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _prefs = getIt<SalesPreferences>();
    _loadAgentsUseCase = getIt<LoadAvailableAgentsForSales>();
    _loadPnlLines = getIt<LoadSalesMonthlyPnlLinesUseCase>();
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
    final generation = ++_chartLoadGeneration;

    setState(() {
      _loading = true;
      _chartLoadFailed = false;
      _chartLoadFailureMessage = null;
      _dailyChartLoadFailed = false;
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
        _dailyPoints = const <OverviewDailySalesTrendPoint>[];
        _dailyChartLoadFailed = false;
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
        _dailyPoints = const <OverviewDailySalesTrendPoint>[];
        _dailyChartLoadFailed = true;
        _dailyChartLoadFailureMessage = authMsg;
      });
      return;
    }

    final futures = await Future.wait(<Future<Object>>[
      _loadPnlLines(
        userId: userId,
        agentId: trimmed,
        anchor: anchor,
        clientToken: clientToken,
      ),
      _loadDailyTotals(
        userId: userId,
        agentId: trimmed,
        anchor: anchor,
        clientToken: clientToken,
      ),
    ]);

    if (!mounted || generation != _chartLoadGeneration) {
      return;
    }
    final bundle = futures[0] as SalesMonthlyPnlLinesLoadResult;
    final dailyBundle = futures[1] as SalesDailyTotalsLoadResult;
    setState(() {
      _points = bundle.points;
      _chartLoadFailed = bundle.loadFailed;
      _chartLoadFailureMessage = bundle.loadFailureMessage;
      _dailyPoints = dailyBundle.points;
      _dailyChartLoadFailed = dailyBundle.loadFailed;
      _dailyChartLoadFailureMessage = dailyBundle.loadFailureMessage;
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

  String _monthlyPnlFullscreenFilterSummary(AppLocalizations l10n) {
    final selectedBranch = _availableAgents
        .cast<OverviewAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == _selectedAgentId,
          orElse: () => null,
        );
    final branchName = selectedBranch?.name ?? l10n.salesBranchPickerEmpty;
    final anchorValue = formatSalesAnchorMonthLabel(context, _anchorYearMonth);
    return l10n.salesMonthlyPnlFullscreenFilterSummary(
      l10n.salesBranchFilterLabel,
      branchName,
      l10n.salesMonthlyPnlFilterAnchorMonth,
      anchorValue,
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
          onApply: _onFiltersChanged,
        );
      },
    );
  }

  void _openChartFullscreen() {
    final pointsSnapshot = List<SalesMonthlyPnlPoint>.of(
      _points,
      growable: false,
    );
    final isLoadingSnapshot = _loading && _selectedAgentId != null;
    final loadFailedSnapshot = _chartLoadFailed;
    final loadFailureMessageSnapshot = _chartLoadFailureMessage;
    final pageL10n = AppLocalizations.of(context);
    unawaited(
      context.pushChartFullscreen<void>(
        extra: AppChartFullscreenRouteExtra(
          title: pageL10n.salesMonthlyPnlChartTitle,
          subtitle: pageL10n.salesMonthlyPnlChartSubtitle,
          filterSummary: _monthlyPnlFullscreenFilterSummary(pageL10n),
          chartSemanticsLabel: pageL10n.salesMonthlyPnlChartSemantics,
          chartBuilder: (fullscreenContext) {
            final l10n = AppLocalizations.of(fullscreenContext);
            return LayoutBuilder(
              builder: (context, constraints) {
                return _SalesMonthlyPnlLineChart(
                  l10n: l10n,
                  points: pointsSnapshot,
                  loadFailed: loadFailedSnapshot,
                  loadFailureMessage: loadFailureMessageSnapshot,
                  isLoading: isLoadingSnapshot,
                  useChartShell: false,
                  chartHeightOverride: constraints.maxHeight,
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openBarChartFullscreen() {
    unawaited(
      pushSalesMonthlyPnlBarChartFullscreen(
        context: context,
        points: List<SalesMonthlyPnlPoint>.of(_points, growable: false),
        initialSession: _prefs.restoreMonthlyPnlBarChartPreferences(),
        isLoading: _loading && _selectedAgentId != null,
        loadFailed: _chartLoadFailed,
        loadFailureMessage: _chartLoadFailureMessage,
        filterSummary: _monthlyPnlFullscreenFilterSummary(
          AppLocalizations.of(context),
        ),
      ),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                RepaintBoundary(
                  child: _SalesMonthlyPnlLineChart(
                    l10n: l10n,
                    points: _points,
                    loadFailed: _chartLoadFailed,
                    loadFailureMessage: _chartLoadFailureMessage,
                    isLoading: _loading && _selectedAgentId != null,
                    onOpenFullscreen: _openChartFullscreen,
                  ),
                ),
                SizedBox(height: tokens.sectionSpacing),
                RepaintBoundary(
                  child: SalesMonthlyPnlBarChartCard(
                    l10n: l10n,
                    points: _points,
                    loadFailed: _chartLoadFailed,
                    loadFailureMessage: _chartLoadFailureMessage,
                    isLoading: _loading && _selectedAgentId != null,
                    preferences: _prefs,
                    onOpenFullscreen: _openBarChartFullscreen,
                  ),
                ),
                SizedBox(height: tokens.sectionSpacing),
                SalesDailyTotalsChartCard(
                  l10n: l10n,
                  points: _dailyPoints,
                  loadFailed: _dailyChartLoadFailed,
                  loadFailureMessage: _dailyChartLoadFailureMessage,
                  isLoading: _loading && _selectedAgentId != null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SalesMonthlyPnlLineChart extends StatelessWidget {
  const _SalesMonthlyPnlLineChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    required this.isLoading,
    this.loadFailureMessage,
    this.onOpenFullscreen,
    this.useChartShell = true,
    this.chartHeightOverride,
  });

  final AppLocalizations l10n;
  final List<SalesMonthlyPnlPoint> points;
  final bool loadFailed;
  final bool isLoading;
  final String? loadFailureMessage;
  final VoidCallback? onOpenFullscreen;
  final bool useChartShell;
  final double? chartHeightOverride;

  @override
  Widget build(BuildContext context) {
    final l10n = this.l10n;
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final localeTag = l10n.localeName;
    final chartTheme = AppChartTheme.fromContext(
      context,
      preset: AppChartPreset.standard,
    );
    final yAxisFormat = AppBrFormatters.compactCurrencyFormatForLocale(
      localeTag,
    );
    final emptyMessage = loadFailed
        ? (loadFailureMessage ?? l10n.salesMonthlyPnlLoadFailed)
        : l10n.salesMonthlyPnlEmpty;
    final semanticsLabel = l10n.salesMonthlyPnlChartSemantics;
    final resolvedHeight = chartHeightOverride ?? chartTheme.height;
    final gridLineColor = colors.outlineVariant.withValues(alpha: 0.35);
    final animationDuration = resolveChartAnimationDurationMs(
      context: context,
      styleDuration: const Duration(milliseconds: 350),
      defaultMs: AppChartEngineAnimationDefaults.cartesianSeriesMs,
    );

    final chartBody = isLoading
        ? buildChartLoadingState(
            context: context,
            height: resolvedHeight,
            indicatorColor: chartTheme.primaryColor,
            label: l10n.overviewComparisonChartLoading,
            variant: ChartLoadingPlaceholderVariant.timeSeries,
          )
        : points.isEmpty
        ? buildChartEmptyState(
            context: context,
            height: resolvedHeight,
            message: emptyMessage,
            placeholder: Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.contentSpacing),
              child: Center(
                child: Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final minChartWidth = _resolveSalesMonthlyPnlChartWidth(
                availableWidth: constraints.maxWidth,
                pointCount: points.length,
              );
              return SizedBox(
                height: resolvedHeight,
                child: ChartHorizontalScrollShell(
                  SizedBox(
                    width: minChartWidth,
                    height: resolvedHeight,
                    child: SfCartesianChart(
                      margin: EdgeInsets.zero,
                      plotAreaBorderWidth: 0,
                      onTooltipRender: buildSanitizingTooltipRenderer(),
                      tooltipBehavior: buildChartTooltipBehavior(
                        context,
                        enable: true,
                        builder: (data, point, series, pointIndex, seriesIndex) {
                          if (pointIndex < 0 || pointIndex >= points.length) {
                            return const SizedBox.shrink();
                          }
                          final item = points[pointIndex];
                          final label = _tooltipSeriesLabel(l10n, seriesIndex);
                          final value = _tooltipSeriesValue(item, seriesIndex);
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _formatChartMonthLongLabel(item, localeTag),
                                  style: TextStyle(
                                    color: theme.colorScheme.onInverseSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$label: ${AppBrFormatters.smartCompactCurrencyForLocale(value, localeTag)}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onInverseSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      legend: const Legend(
                        isVisible: true,
                        position: LegendPosition.bottom,
                        overflowMode: LegendItemOverflowMode.wrap,
                      ),
                      primaryXAxis: const CategoryAxis(
                        majorGridLines: MajorGridLines(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        numberFormat: yAxisFormat,
                        axisLine: const AxisLine(width: 0),
                        majorGridLines: MajorGridLines(
                          color: gridLineColor,
                          width: 1,
                        ),
                      ),
                      zoomPanBehavior: ZoomPanBehavior(
                        enablePinching: chartTheme.enableSelectionZooming,
                        enablePanning: chartTheme.enableSelectionZooming,
                        enableSelectionZooming:
                            chartTheme.enableSelectionZooming,
                      ),
                      series: <CartesianSeries<SalesMonthlyPnlPoint, String>>[
                        LineSeries<SalesMonthlyPnlPoint, String>(
                          dataSource: points,
                          xValueMapper: (point, _) =>
                              _formatChartMonthShortLabel(point, localeTag),
                          yValueMapper: (point, _) => point.venda,
                          name: l10n.salesMonthlyPnlSeriesSalesLabel,
                          color: chartTheme.primaryColor,
                          width: 3,
                          animationDuration: animationDuration,
                          markerSettings: MarkerSettings(
                            isVisible: true,
                            height: 6,
                            width: 6,
                            color: chartTheme.primaryColor,
                            borderColor: theme.colorScheme.surface,
                          ),
                        ),
                        LineSeries<SalesMonthlyPnlPoint, String>(
                          dataSource: points,
                          xValueMapper: (point, _) =>
                              _formatChartMonthShortLabel(point, localeTag),
                          yValueMapper: (point, _) => point.lucro,
                          name: l10n.salesMonthlyPnlSeriesProfitLabel,
                          color: chartTheme.paletteColor(1),
                          width: 3,
                          animationDuration: animationDuration,
                          markerSettings: MarkerSettings(
                            isVisible: true,
                            height: 6,
                            width: 6,
                            color: chartTheme.paletteColor(1),
                            borderColor: theme.colorScheme.surface,
                          ),
                        ),
                        LineSeries<SalesMonthlyPnlPoint, String>(
                          dataSource: points,
                          xValueMapper: (point, _) =>
                              _formatChartMonthShortLabel(point, localeTag),
                          yValueMapper: (point, _) => point.custoMercadoria,
                          name: l10n.salesMonthlyPnlSeriesCostLabel,
                          color: chartTheme.paletteColor(2),
                          width: 3,
                          animationDuration: animationDuration,
                          markerSettings: MarkerSettings(
                            isVisible: true,
                            height: 6,
                            width: 6,
                            color: chartTheme.paletteColor(2),
                            borderColor: theme.colorScheme.surface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  semanticsHint: l10n.overviewComparisonBarHorizontalScrollHint,
                  key: SalesMonthlyPnlChartKeys.lineHorizontalScrollShell,
                ),
              );
            },
          );

    final chartSurface = useChartShell
        ? AppChartShell(
            title: l10n.salesMonthlyPnlChartTitle,
            subtitle: l10n.salesMonthlyPnlChartSubtitle,
            onOpenFullscreen: onOpenFullscreen,
            child: chartBody,
          )
        : chartBody;

    return Semantics(
      label: semanticsLabel,
      child: chartSurface,
    );
  }
}
