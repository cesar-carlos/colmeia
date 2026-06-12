import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_percent_metric.dart';
import 'package:colmeia/features/overview/presentation/widgets/lucratividade_combo_chart_controls.dart';
import 'package:colmeia/features/overview/presentation/widgets/lucratividade_combo_chart_display_series.dart';
import 'package:colmeia/features/overview/presentation/widgets/lucratividade_combo_chart_fullscreen_body.dart';
import 'package:colmeia/features/overview/presentation/widgets/lucratividade_combo_chart_types.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_load_failure_helpers.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_actions.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart' show TooltipArgs;

export 'package:colmeia/features/overview/presentation/widgets/lucratividade_combo_chart_types.dart';

/// Shared lucratividade combo chart: formatters, tooltip, segmented controls,
/// share and fullscreen. Feature widgets supply row type and copy only.
class LucratividadeComboChart<T> extends StatefulWidget {
  const LucratividadeComboChart({
    required this.l10n,
    required this.copy,
    required this.points,
    required this.loadFailed,
    required this.rowAccessors,
    required this.xLabelBuilder,
    required this.shareMetadataBuilder,
    required this.hasMultiAgentEmptyHint,
    super.key,
    this.loadFailure,
    this.loadFailureMessage,
    this.onViewAgentFailureDetails,
    this.onRequestFullscreen,
    this.onRequestShare,
    this.exportHeaderContext,
    this.landscapeStyleOverride,
  });

  final AppLocalizations l10n;
  final LucratividadeComboChartCopy copy;
  final ChartShareExportHeaderContext? exportHeaderContext;
  final List<T> points;
  final bool loadFailed;
  final AppFailure? loadFailure;
  final String? loadFailureMessage;
  final LucratividadeComboRowAccessors<T> rowAccessors;
  final String Function(T row) xLabelBuilder;
  final ChartShareMetadata Function({
    required List<T> sortedPoints,
    required AppComboChartStyle exportBaseStyle,
    required num Function(T) barFn,
    required num Function(T) lineFn,
    required String Function(T, num) labelFn,
    required String barSeriesLabel,
    required String lineSeriesLabel,
  })
  shareMetadataBuilder;
  final bool hasMultiAgentEmptyHint;
  final VoidCallback? onViewAgentFailureDetails;
  final AppChartFullscreenRequestCallback? onRequestFullscreen;
  final AppChartShareRequestCallback? onRequestShare;
  final AppComboChartStyle Function(
    AppComboChartStyle base,
    double height,
  )?
  landscapeStyleOverride;

  @override
  State<LucratividadeComboChart<T>> createState() =>
      _LucratividadeComboChartState<T>();
}

class _LucratividadeComboChartState<T>
    extends State<LucratividadeComboChart<T>> {
  final GlobalKey _shareKey = GlobalKey();

  LucratividadeComboDisplay _display = LucratividadeComboDisplay.profitRevenue;
  LucratividadePercentMetric _percentMetric =
      LucratividadePercentMetric.grossMargin;

  String _formatsLocaleTag = '';
  late NumberFormat _compactCurrencyFormat;
  late NumberFormat _percentFormat;
  late NumberFormat _markupAxisFormat;

  String? _emptyMessageCache;
  Widget? _emptyPlaceholderCache;

  LucratividadeComboRowAccessors<T> get _accessors => widget.rowAccessors;

  @override
  void initState() {
    super.initState();
    _formatsLocaleTag = widget.l10n.localeName;
    _initFormats(_formatsLocaleTag);
  }

  void _initFormats(String localeTag) {
    _compactCurrencyFormat = AppBrFormatters.compactCurrencyFormatForLocale(
      localeTag,
    );
    _percentFormat = NumberFormat.decimalPercentPattern(
      locale: localeTag,
      decimalDigits: 1,
    );
    _markupAxisFormat = NumberFormat('#0.0', localeTag);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tag = Localizations.localeOf(context).toString();
    if (_formatsLocaleTag != tag) {
      _formatsLocaleTag = tag;
      _initFormats(tag);
      _emptyMessageCache = null;
      _emptyPlaceholderCache = null;
    }
  }

  @override
  void didUpdateWidget(covariant LucratividadeComboChart<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.l10n.localeName != oldWidget.l10n.localeName) {
      _formatsLocaleTag = widget.l10n.localeName;
      _initFormats(widget.l10n.localeName);
      _emptyMessageCache = null;
      _emptyPlaceholderCache = null;
    } else if (!identical(widget.points, oldWidget.points) ||
        widget.hasMultiAgentEmptyHint != oldWidget.hasMultiAgentEmptyHint) {
      _emptyMessageCache = null;
      _emptyPlaceholderCache = null;
    }
  }

  String _barLabelCurrency(T _, num v) =>
      widget.copy.useSmartCompactCurrencyLabels
      ? AppBrFormatters.smartCompactCurrencyForLocale(v, _formatsLocaleTag)
      : _compactCurrencyFormat.format(v);

  String _barLabelPercentScale(T _, num v) => _percentFormat.format(v / 100);

  String _barLabelMarkup(T row, num v) {
    if (_accessors.custoReposicao(row) <= 0) {
      return widget.l10n.overviewLucratividadeMarkupNotApplicable;
    }
    return '${_markupAxisFormat.format(v)}%';
  }

  Widget _emptyPlaceholder(AppThemeTokens tokens, String message) {
    if (_emptyMessageCache == message && _emptyPlaceholderCache != null) {
      return _emptyPlaceholderCache!;
    }
    _emptyMessageCache = message;
    if (widget.loadFailed) {
      return _emptyPlaceholderCache = overviewChartEmptyPlaceholder(
        emptyMessage: message,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        verticalPadding: tokens.contentSpacing,
        onViewAgentFailureDetails: widget.onViewAgentFailureDetails,
        loadFailure: widget.loadFailure,
      );
    }
    return _emptyPlaceholderCache = Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.contentSpacing),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            SizedBox(height: tokens.gapMd),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  AppComboChartStyle _buildStyle(
    AppThemeTokens tokens, {
    required AppLocalizations l10n,
    required bool usePercentPrimaryAxis,
    required bool useMarkupAxisFormat,
    required Color barColor,
    double? heightOverride,
    bool fastChartAnimation = false,
    String? Function(TooltipArgs args)? tooltipBodyResolver,
  }) {
    final leftAxis = usePercentPrimaryAxis
        ? (useMarkupAxisFormat ? _markupAxisFormat : _percentFormat)
        : null;
    final paddingBottom = widget.copy.chartPaddingBottom;

    return AppComboChartStyle(
      height:
          heightOverride ??
          (tokens.chartStandardHeight + tokens.contentSpacing * 2),
      animationDuration: Duration(milliseconds: fastChartAnimation ? 150 : 350),
      tooltipBodyResolver: tooltipBodyResolver,
      leftAxisFormat: leftAxis ?? _compactCurrencyFormat,
      rightAxisFormat: _compactCurrencyFormat,
      chartPadding: paddingBottom == null
          ? EdgeInsets.zero
          : EdgeInsets.only(bottom: paddingBottom),
      showRightYAxis: false,
      showLineSeries: false,
      showDataLabels: true,
      barDataLabelOffset: Offset(0, tokens.gapSm),
      minCategorySlotWidth:
          widget.copy.minCategorySlotWidth ??
          AppChartEngineCartesianBarGeometryDefaults.minCategorySlotWidth,
      horizontalScrollSemanticsHint:
          l10n.overviewComparisonBarHorizontalScrollHint,
      stickyPrimaryYAxisWhileScrolling: false,
      loadingLabel: l10n.overviewComparisonChartLoading,
      barColor: barColor,
    );
  }

  List<T> _sortedPoints() {
    final sorted = List<T>.of(widget.points);
    _accessors.sortPoints?.call(sorted, _display, _percentMetric);
    return sorted;
  }

  LucratividadeComboDisplaySeries<T> _resolveDisplaySeries() {
    return resolveLucratividadeComboDisplaySeries<T>(
      display: _display,
      percentMetric: _percentMetric,
      copy: widget.copy,
      l10n: widget.l10n,
      accessors: _accessors,
      barLabelCurrency: _barLabelCurrency,
      barLabelPercentScale: _barLabelPercentScale,
      barLabelMarkup: _barLabelMarkup,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = widget.l10n;
    final copy = widget.copy;
    final series = _resolveDisplaySeries();
    final sortedPoints = _sortedPoints();

    final barColor = series.isCost ? tokens.warning : tokens.chartSeriesPrimary;

    final emptyMessage = widget.loadFailed
        ? overviewChartLoadFailureMessage(
            l10n: l10n,
            loadFailed: true,
            loadFailure: widget.loadFailure,
            legacyMessage: widget.loadFailureMessage,
            genericFallback: copy.loadFailedFallback,
          )
        : widget.hasMultiAgentEmptyHint
        ? copy.emptyMessage
        : copy.multiAgentHintMessage;

    final useMarkupAxis =
        series.isPercent &&
        _percentMetric == LucratividadePercentMetric.markupOverCost;

    final tooltipResolver = lucratividadeMarkupTooltipBodyResolver<T>(
      points: sortedPoints,
      metric: _percentMetric,
      l10n: l10n,
      custoReposicao: _accessors.custoReposicao,
    );

    final style = _buildStyle(
      tokens,
      l10n: l10n,
      usePercentPrimaryAxis: series.isPercent,
      useMarkupAxisFormat: useMarkupAxis,
      barColor: barColor,
      fastChartAnimation: series.isPercent,
      tooltipBodyResolver: tooltipResolver,
    );

    final belowSubtitle = LucratividadeComboChartControls(
      l10n: l10n,
      copy: copy,
      tokens: tokens,
      display: _display,
      percentMetric: _percentMetric,
      hasChartData: widget.points.isNotEmpty,
      onDisplayChanged: (v) => setState(() => _display = v),
      onPercentMetricChanged: (v) => setState(() => _percentMetric = v),
    );

    final metadata = widget.shareMetadataBuilder(
      sortedPoints: sortedPoints,
      exportBaseStyle: style,
      barFn: series.barFn,
      lineFn: series.lineFn,
      labelFn: series.labelFn,
      barSeriesLabel: series.barSeriesLabel,
      lineSeriesLabel: series.lineSeriesLabel,
    );
    final shareActions = ChartShareActions(
      context: context,
      captureKey: _shareKey,
      metadata: metadata,
      onRequestShare: widget.onRequestShare,
      onRequestFullscreen: widget.onRequestFullscreen,
    );

    void openFullscreen() {
      final snapshot = List<T>.of(sortedPoints, growable: false);
      final fullscreenShareKey = GlobalKey();
      shareActions.openFullscreen(
        metadata.toFullscreenRequest(
          semanticsLabel: copy.title,
          shareCaptureKey: fullscreenShareKey,
          chartBuilder: (fullscreenContext) =>
              buildLucratividadeComboFullscreenBody<T>(
                shareCaptureKey: fullscreenShareKey,
                snapshot: snapshot,
                initialDisplay: _display,
                initialPercentMetric: _percentMetric,
                copy: copy,
                l10n: l10n,
                emptyMessage: emptyMessage,
                accessors: _accessors,
                xLabelBuilder: widget.xLabelBuilder,
                styleBuilder: _buildStyle,
                landscapeStyleOverride: widget.landscapeStyleOverride,
                barLabelCurrency: _barLabelCurrency,
                barLabelPercentScale: _barLabelPercentScale,
                barLabelMarkup: _barLabelMarkup,
              ),
        ),
      );
    }

    return RepaintBoundary(
      key: _shareKey,
      child: AppComboChart<T>(
        key: ValueKey<Object>(
          Object.hash(
            identityHashCode(widget.points),
            _display,
            _percentMetric,
          ),
        ),
        title: copy.title,
        onShare: shareActions.shareCallback(),
        shareProgressKey: _shareKey,
        onOpenFullscreen: shareActions.fullscreenCallback(openFullscreen),
        subtitle: copy.subtitle,
        belowSubtitle: belowSubtitle,
        items: sortedPoints,
        xLabelBuilder: widget.xLabelBuilder,
        barValueBuilder: series.barFn,
        barSeriesLabel: series.barSeriesLabel,
        lineValueBuilder: series.lineFn,
        lineSeriesLabel: series.lineSeriesLabel,
        barDataLabelBuilder: series.labelFn,
        style: style,
        emptyPlaceholder: widget.points.isEmpty
            ? DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.bodyMedium,
                child: _emptyPlaceholder(tokens, emptyMessage),
              )
            : null,
      ),
    );
  }
}
