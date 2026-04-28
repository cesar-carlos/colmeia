import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String _xLabel(ResumoProdutoVendaLucratividadeMensalRow r) => r.anoMes;

num _barByProfit(ResumoProdutoVendaLucratividadeMensalRow r) => r.lucro;
num _lineByProfit(ResumoProdutoVendaLucratividadeMensalRow r) => r.valorTotalItem;

num _barByRevenue(ResumoProdutoVendaLucratividadeMensalRow r) =>
    r.valorTotalItem;
num _lineByRevenue(ResumoProdutoVendaLucratividadeMensalRow r) =>
    r.custoReposicao;

num _barByCost(ResumoProdutoVendaLucratividadeMensalRow r) => r.custoReposicao;
num _lineByCost(ResumoProdutoVendaLucratividadeMensalRow r) => r.valorTotalItem;

num _barByMargin(ResumoProdutoVendaLucratividadeMensalRow r) =>
    r.percentualLucro;
num _lineByMargin(ResumoProdutoVendaLucratividadeMensalRow r) =>
    r.valorTotalItem;

enum _LucratividadeDisplay {
  /// Bars = profit, line = revenue.
  profitRevenue,

  /// Bars = revenue, line = cost.
  revenueCost,

  /// Bars = cost, line = revenue.
  costRevenue,

  /// Bars = cost-to-revenue % (PercentualLucro), line = revenue.
  marginPercent,
}

/// Monthly product profitability chart (lucratividade mensal) using the same
/// `AppComboChart` pattern as `OverviewMonthlyParcelsComboChart`.
///
/// Monthly product profitability chart. Always rendered; when multiple agents
/// are selected ([isSingleAgentSelected] is false) an informational placeholder
/// explains that single-agent context is required. When [points] is empty and
/// [loadFailed] is false the chart shows the empty-period message.
class OverviewLucratividadeMensalChart extends StatefulWidget {
  const OverviewLucratividadeMensalChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    required this.isSingleAgentSelected,
    this.loadFailureMessage,
    super.key,
  });

  final AppLocalizations l10n;
  final List<ResumoProdutoVendaLucratividadeMensalRow> points;
  final bool loadFailed;

  /// True when exactly one agent is selected in the active filter.
  /// When false, a hint is shown instead of the empty-period message.
  final bool isSingleAgentSelected;
  final String? loadFailureMessage;

  @override
  State<OverviewLucratividadeMensalChart> createState() =>
      _OverviewLucratividadeMensalChartState();
}

class _OverviewLucratividadeMensalChartState
    extends State<OverviewLucratividadeMensalChart> {
  _LucratividadeDisplay _display = _LucratividadeDisplay.profitRevenue;

  String _formatsLocaleTag = '';
  late NumberFormat _compactCurrencyFormat;
  late NumberFormat _percentFormat;

  String? _emptyMessageCache;
  Widget? _emptyPlaceholderCache;

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
  void didUpdateWidget(covariant OverviewLucratividadeMensalChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.l10n.localeName != oldWidget.l10n.localeName) {
      _formatsLocaleTag = widget.l10n.localeName;
      _initFormats(widget.l10n.localeName);
      _emptyMessageCache = null;
      _emptyPlaceholderCache = null;
    } else if (!identical(widget.points, oldWidget.points)) {
      _emptyMessageCache = null;
      _emptyPlaceholderCache = null;
    }
  }

  String _barLabelCurrency(ResumoProdutoVendaLucratividadeMensalRow _, num v) =>
      _compactCurrencyFormat.format(v);

  String _barLabelPercent(ResumoProdutoVendaLucratividadeMensalRow _, num v) =>
      _percentFormat.format(v / 100);

  Widget _emptyPlaceholder(AppThemeTokens tokens, String message) {
    if (_emptyMessageCache == message && _emptyPlaceholderCache != null) {
      return _emptyPlaceholderCache!;
    }
    _emptyMessageCache = message;
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

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = widget.l10n;
    final isMargin = _display == _LucratividadeDisplay.marginPercent;
    final isCost = _display == _LucratividadeDisplay.costRevenue;
    final isProfit = _display == _LucratividadeDisplay.profitRevenue;

    final Color barColor;
    final Color lineColor;
    if (isCost) {
      barColor = tokens.warning;
      lineColor = tokens.chartSeriesPrimary;
    } else if (isProfit) {
      barColor = tokens.chartSeriesPrimary;
      lineColor = tokens.chartSeriesSecondary;
    } else {
      barColor = tokens.chartSeriesPrimary;
      lineColor = tokens.warning;
    }

    final style = AppComboChartStyle(
      height: tokens.chartStandardHeight + tokens.contentSpacing * 2,
      animationDuration: const Duration(milliseconds: 350),
      leftAxisFormat: isMargin ? _percentFormat : _compactCurrencyFormat,
      rightAxisFormat: _compactCurrencyFormat,
      chartPadding: EdgeInsets.zero,
      showRightYAxis: false,
      showDataLabels: true,
      barDataLabelOffset: Offset(0, tokens.gapSm),
      minCategorySlotWidth: tokens.chartOverviewMonthlyCategoryMinSlotWidth,
      horizontalScrollSemanticsHint:
          l10n.overviewComparisonBarHorizontalScrollHint,
      stickyPrimaryYAxisWhileScrolling: false,
      loadingLabel: l10n.overviewComparisonChartLoading,
      barColor: barColor,
      lineColor: lineColor,
    );

    final emptyMessage = widget.loadFailed
        ? (widget.loadFailureMessage ?? l10n.overviewMonthlyParcelsLoadFailed)
        : widget.isSingleAgentSelected
        ? l10n.overviewLucratividadeMensalEmpty
        : l10n.overviewLucratividadeMensalMultiAgentHint;

    num Function(ResumoProdutoVendaLucratividadeMensalRow) barFn;
    num Function(ResumoProdutoVendaLucratividadeMensalRow) lineFn;
    String Function(ResumoProdutoVendaLucratividadeMensalRow, num) labelFn;

    if (isMargin) {
      barFn = _barByMargin;
      lineFn = _lineByMargin;
      labelFn = _barLabelPercent;
    } else if (isCost) {
      barFn = _barByCost;
      lineFn = _lineByCost;
      labelFn = _barLabelCurrency;
    } else if (isProfit) {
      barFn = _barByProfit;
      lineFn = _lineByProfit;
      labelFn = _barLabelCurrency;
    } else {
      barFn = _barByRevenue;
      lineFn = _lineByRevenue;
      labelFn = _barLabelCurrency;
    }

    return RepaintBoundary(
      child: AppComboChart<ResumoProdutoVendaLucratividadeMensalRow>(
        key: ValueKey<int>(identityHashCode(widget.points)),
        title: l10n.overviewLucratividadeMensalTitle,
        subtitle: l10n.overviewLucratividadeMensalSubtitle,
        belowSubtitle: AppSegmentedControl<_LucratividadeDisplay>(
          options: <AppSegmentedControlOption<_LucratividadeDisplay>>[
            AppSegmentedControlOption<_LucratividadeDisplay>(
              value: _LucratividadeDisplay.profitRevenue,
              label: l10n.overviewLucratividadeMensalSwitchProfit,
            ),
            AppSegmentedControlOption<_LucratividadeDisplay>(
              value: _LucratividadeDisplay.revenueCost,
              label: l10n.overviewLucratividadeMensalSwitchRevenue,
            ),
            AppSegmentedControlOption<_LucratividadeDisplay>(
              value: _LucratividadeDisplay.costRevenue,
              label: l10n.overviewLucratividadeMensalSwitchCost,
            ),
            AppSegmentedControlOption<_LucratividadeDisplay>(
              value: _LucratividadeDisplay.marginPercent,
              label: l10n.overviewLucratividadeMensalSwitchMargin,
            ),
          ],
          value: _display,
          onChanged: (v) => setState(() => _display = v),
        ),
        items: widget.points,
        xLabelBuilder: _xLabel,
        barValueBuilder: barFn,
        barSeriesLabel: isMargin
            ? l10n.overviewLucratividadeMensalMarginSeriesLabel
            : isCost
            ? l10n.overviewLucratividadeMensalCostSeriesLabel
            : isProfit
            ? l10n.overviewLucratividadeMensalProfitSeriesLabel
            : l10n.overviewLucratividadeMensalRevenueSeriesLabel,
        lineValueBuilder: lineFn,
        lineSeriesLabel: isMargin || isCost || isProfit
            ? l10n.overviewLucratividadeMensalRevenueSeriesLabel
            : l10n.overviewLucratividadeMensalCostSeriesLabel,
        barDataLabelBuilder: labelFn,
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
