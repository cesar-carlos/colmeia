import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_monthly_pnl_lines_use_case.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/sales_monthly_pnl_chart_keys.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_monthly_pnl_bar_chart_card.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

const int _kSalesMonthlyPnlAnchorChoices = 36;
const double _kSalesMonthlyPnlMinChartWidth = 560;
const double _kSalesMonthlyPnlMonthSlotWidth = 72;
const double _kSalesMonthlyPnlChartHorizontalPadding = 24;

List<OverviewYearMonth> salesMonthlyPnlAnchorMonthChoices() {
  final now = DateTime.now();
  final current = OverviewYearMonth.fromDate(now);
  final list = <OverviewYearMonth>[current];
  for (var i = 1; i < _kSalesMonthlyPnlAnchorChoices; i++) {
    var month = now.month - i;
    var year = now.year;
    while (month < 1) {
      month += 12;
      year -= 1;
    }
    list.add(OverviewYearMonth(year: year, month: month));
  }
  return list;
}

String _formatYearMonthLabel(BuildContext context, OverviewYearMonth ym) {
  final locale = Localizations.localeOf(context).toString();
  final date = DateTime(ym.year, ym.month);
  return DateFormat.yMMM(locale).format(date);
}

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

List<AppDropdownOption<OverviewYearMonth>> _anchorMonthDropdownOptions({
  required BuildContext context,
  required AppLocalizations l10n,
  required OverviewYearMonth selected,
}) {
  final base = salesMonthlyPnlAnchorMonthChoices();
  var options = <AppDropdownOption<OverviewYearMonth>>[
    AppDropdownOption<OverviewYearMonth>(
      value: base.first,
      label: l10n.dashboardHomeFiltersCurrentMonth,
    ),
    for (var i = 1; i < base.length; i++)
      AppDropdownOption<OverviewYearMonth>(
        value: base[i],
        label: _formatYearMonthLabel(context, base[i]),
      ),
  ];
  if (!options.any((o) => o.value == selected)) {
    options = <AppDropdownOption<OverviewYearMonth>>[
      AppDropdownOption<OverviewYearMonth>(
        value: selected,
        label: _formatYearMonthLabel(context, selected),
      ),
      ...options,
    ];
  }
  return options;
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
  late final AgentClientTokenReader _clientTokenReader;

  String? _selectedAgentId;
  List<OverviewAgentOption> _availableAgents = <OverviewAgentOption>[];
  late OverviewYearMonth _anchorYearMonth;
  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;

  List<SalesMonthlyPnlPoint> _points = const <SalesMonthlyPnlPoint>[];
  bool _loading = false;
  bool _chartLoadFailed = false;
  String? _chartLoadFailureMessage;
  int _chartLoadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _prefs = getIt<SalesPreferences>();
    _loadAgentsUseCase = getIt<LoadAvailableAgentsForSales>();
    _loadPnlLines = getIt<LoadSalesMonthlyPnlLinesUseCase>();
    _clientTokenReader = getIt<AgentClientTokenReader>();
    _selectedAgentId = _prefs.selectedAgentId;
    _anchorYearMonth =
        _prefs.restoreMonthlyPnlAnchor() ??
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
      setState(() {
        _loading = false;
        _points = const <SalesMonthlyPnlPoint>[];
        _chartLoadFailed = true;
        _chartLoadFailureMessage = AppLocalizations.of(
          context,
        ).agentSqlErrorAuthenticationFailed;
      });
      return;
    }

    final bundle = await _loadPnlLines(
      userId: userId,
      agentId: trimmed,
      anchor: anchor,
      clientToken: clientToken,
    );

    if (!mounted || generation != _chartLoadGeneration) {
      return;
    }
    setState(() {
      _points = bundle.points;
      _chartLoadFailed = bundle.loadFailed;
      _chartLoadFailureMessage = bundle.loadFailureMessage;
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
      unawaited(_prefs.persistMonthlyPnlAnchor(anchor));
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
        return _SalesMonthlyPnlFiltersSheet(
          l10n: AppLocalizations.of(context),
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
      ),
    );
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
    final anchorLabel = _formatYearMonthLabel(context, _anchorYearMonth);

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
                label: l10n.dashboardHomeFiltersAgentsLabel,
                value: selectedAgentName,
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
              title: l10n.salesAgentRequiredTitle,
              message: l10n.salesAgentRequiredMessage,
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

class _SalesMonthlyPnlFiltersSheet extends StatefulWidget {
  const _SalesMonthlyPnlFiltersSheet({
    required this.l10n,
    required this.availableAgents,
    required this.initialSelectedAgentId,
    required this.initialAnchorYearMonth,
    required this.onApply,
  });

  final AppLocalizations l10n;
  final List<OverviewAgentOption> availableAgents;
  final String? initialSelectedAgentId;
  final OverviewYearMonth initialAnchorYearMonth;
  final ValueChanged<Map<String, Object?>> onApply;

  @override
  State<_SalesMonthlyPnlFiltersSheet> createState() =>
      _SalesMonthlyPnlFiltersSheetState();
}

class _SalesMonthlyPnlFiltersSheetState
    extends State<_SalesMonthlyPnlFiltersSheet> {
  String? _selectedAgentId;
  late OverviewYearMonth _anchorYearMonth;

  @override
  void initState() {
    super.initState();
    _selectedAgentId = widget.initialSelectedAgentId;
    _anchorYearMonth = widget.initialAnchorYearMonth;
  }

  void _apply() {
    final selectedAgentId = _selectedAgentId;
    if (selectedAgentId == null || selectedAgentId.trim().isEmpty) {
      return;
    }
    widget.onApply(<String, Object?>{
      'agentId': selectedAgentId,
      'anchorYearMonth': _anchorYearMonth,
    });
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _anchorYearMonth = OverviewYearMonth.fromDate(DateTime.now());
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
    final monthOptions = _anchorMonthDropdownOptions(
      context: context,
      l10n: widget.l10n,
      selected: _anchorYearMonth,
    );

    return SalesFiltersSheetScaffold(
      title: widget.l10n.reportFiltersTitleWithContext(
        widget.l10n.salesCardMonthlyPnlTitle,
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
              title: widget.l10n.dashboardHomeFiltersAgentsLabel,
              subtitle: widget.l10n.salesAgentRequiredMessage,
              requiredBadgeLabel: widget.l10n.reportFiltersRequiredCount(1),
            ),
            SizedBox(height: tokens.gapSm),
            SalesSingleAgentPickerControl(
              l10n: widget.l10n,
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
                message:
                    widget.l10n.overviewAgentFilterMissingClientTokenBanner,
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            SalesFiltersSectionHeader(
              title: widget.l10n.salesMonthlyPnlFilterAnchorMonth,
            ),
            SizedBox(height: tokens.gapSm),
            AppSectionCard(
              color: theme.colorScheme.surfaceContainerLow,
              child: AppDropdownField<OverviewYearMonth>(
                label: widget.l10n.salesMonthlyPnlFilterAnchorMonth,
                value: _anchorYearMonth,
                density: AppTextFieldDensity.compact,
                options: monthOptions,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _anchorYearMonth = value);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
