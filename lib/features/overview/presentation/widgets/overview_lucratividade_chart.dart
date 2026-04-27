import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String _xLabel(ResumoProdutoVendaLucratividadeRow r) => r.filialLabel;

num _barByRevenue(ResumoProdutoVendaLucratividadeRow r) => r.valorTotalItem;
num _lineByRevenue(ResumoProdutoVendaLucratividadeRow r) => r.custoReposicao;

num _barByCost(ResumoProdutoVendaLucratividadeRow r) => r.custoReposicao;
num _lineByCost(ResumoProdutoVendaLucratividadeRow r) => r.valorTotalItem;

num _barByMargin(ResumoProdutoVendaLucratividadeRow r) => r.percentualLucro;
num _lineByMargin(ResumoProdutoVendaLucratividadeRow r) => r.valorTotalItem;

enum _LucratividadeDisplay {
  /// Bars = revenue, line = replacement cost (default).
  revenueCost,

  /// Bars = replacement cost, line = revenue.
  costRevenue,

  /// Bars = cost-to-revenue % (PercentualLucro), line = revenue.
  marginPercent,
}

/// Period product profitability chart, aggregated by `CodEmpresa/CodFilial`
/// for the active overview filter date range.
///
/// Runs for each selected agent in parallel; when no agents are explicitly
/// selected ([isSingleOrMultiAgentSelected] is false) an informational
/// placeholder is shown instead.
class OverviewLucratividadeChart extends StatefulWidget {
  const OverviewLucratividadeChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    required this.isSingleOrMultiAgentSelected,
    this.loadFailureMessage,
    super.key,
  });

  final AppLocalizations l10n;
  final List<ResumoProdutoVendaLucratividadeRow> points;
  final bool loadFailed;

  /// True when at least one agent is explicitly selected in the active filter.
  /// When false (all-agents mode), a hint is shown instead of chart data.
  final bool isSingleOrMultiAgentSelected;
  final String? loadFailureMessage;

  @override
  State<OverviewLucratividadeChart> createState() =>
      _OverviewLucratividadeChartState();
}

class _OverviewLucratividadeChartState
    extends State<OverviewLucratividadeChart> {
  _LucratividadeDisplay _display = _LucratividadeDisplay.revenueCost;

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
  void didUpdateWidget(covariant OverviewLucratividadeChart oldWidget) {
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

  String _barLabelCurrency(ResumoProdutoVendaLucratividadeRow _, num v) =>
      _compactCurrencyFormat.format(v);

  String _barLabelPercent(ResumoProdutoVendaLucratividadeRow _, num v) =>
      _percentFormat.format(v / 100);

  Widget _emptyPlaceholder(AppThemeTokens tokens, String message) {
    if (_emptyMessageCache == message && _emptyPlaceholderCache != null) {
      return _emptyPlaceholderCache!;
    }
    _emptyMessageCache = message;
    return _emptyPlaceholderCache = Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.contentSpacing),
      child: Center(child: Text(message, textAlign: TextAlign.center)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = widget.l10n;
    final isMargin = _display == _LucratividadeDisplay.marginPercent;
    final isCost = _display == _LucratividadeDisplay.costRevenue;

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
    );

    final emptyMessage = widget.loadFailed
        ? (widget.loadFailureMessage ?? l10n.overviewMonthlyParcelsLoadFailed)
        : widget.isSingleOrMultiAgentSelected
        ? l10n.overviewLucratividadeEmpty
        : l10n.overviewLucratividadeMultiAgentHint;

    num Function(ResumoProdutoVendaLucratividadeRow) barFn;
    num Function(ResumoProdutoVendaLucratividadeRow) lineFn;
    String Function(ResumoProdutoVendaLucratividadeRow, num) labelFn;

    if (isMargin) {
      barFn = _barByMargin;
      lineFn = _lineByMargin;
      labelFn = _barLabelPercent;
    } else if (isCost) {
      barFn = _barByCost;
      lineFn = _lineByCost;
      labelFn = _barLabelCurrency;
    } else {
      barFn = _barByRevenue;
      lineFn = _lineByRevenue;
      labelFn = _barLabelCurrency;
    }

    return RepaintBoundary(
      child: AppComboChart<ResumoProdutoVendaLucratividadeRow>(
        key: ValueKey<int>(identityHashCode(widget.points)),
        title: l10n.overviewLucratividadeTitle,
        subtitle: l10n.overviewLucratividadeSubtitle,
        belowSubtitle: AppSegmentedControl<_LucratividadeDisplay>(
          options: <AppSegmentedControlOption<_LucratividadeDisplay>>[
            AppSegmentedControlOption<_LucratividadeDisplay>(
              value: _LucratividadeDisplay.revenueCost,
              label: l10n.overviewLucratividadeSwitchRevenue,
            ),
            AppSegmentedControlOption<_LucratividadeDisplay>(
              value: _LucratividadeDisplay.costRevenue,
              label: l10n.overviewLucratividadeSwitchCost,
            ),
            AppSegmentedControlOption<_LucratividadeDisplay>(
              value: _LucratividadeDisplay.marginPercent,
              label: l10n.overviewLucratividadeSwitchMargin,
            ),
          ],
          value: _display,
          onChanged: (v) => setState(() => _display = v),
        ),
        items: widget.points,
        xLabelBuilder: _xLabel,
        barValueBuilder: barFn,
        barSeriesLabel: isMargin
            ? l10n.overviewLucratividadeMarginSeriesLabel
            : isCost
            ? l10n.overviewLucratividadeCostSeriesLabel
            : l10n.overviewLucratividadeRevenueSeriesLabel,
        lineValueBuilder: lineFn,
        lineSeriesLabel: isMargin || isCost
            ? l10n.overviewLucratividadeRevenueSeriesLabel
            : l10n.overviewLucratividadeCostSeriesLabel,
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
