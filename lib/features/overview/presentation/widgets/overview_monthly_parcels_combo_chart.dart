import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OverviewMonthlyParcelsComboChart extends StatefulWidget {
  const OverviewMonthlyParcelsComboChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewMonthlyParcelPoint> points;
  final bool loadFailed;

  @override
  State<OverviewMonthlyParcelsComboChart> createState() =>
      _OverviewMonthlyParcelsComboChartState();
}

class _OverviewMonthlyParcelsComboChartState
    extends State<OverviewMonthlyParcelsComboChart> {
  String _formatsLocaleTag = '';
  late NumberFormat _leftAxisFormat;
  late NumberFormat _rightAxisFormat;

  String? _emptyMessageCache;
  Widget? _emptyPlaceholderCache;

  Widget? _emptyPlaceholder({
    required AppThemeTokens tokens,
    required String message,
  }) {
    if (_emptyMessageCache == message && _emptyPlaceholderCache != null) {
      return _emptyPlaceholderCache;
    }
    _emptyMessageCache = message;
    return _emptyPlaceholderCache = Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.contentSpacing),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tag = Localizations.localeOf(context).toString();
    if (_formatsLocaleTag != tag) {
      _formatsLocaleTag = tag;
      _leftAxisFormat = NumberFormat.decimalPattern(tag);
      _rightAxisFormat = AppBrFormatters.compactCurrencyFormatForLocale(tag);
      _emptyMessageCache = null;
      _emptyPlaceholderCache = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = widget.l10n;
    final left = _leftAxisFormat;
    final right = _rightAxisFormat;

    final emptyMessage = widget.loadFailed
        ? l10n.overviewMonthlyParcelsLoadFailed
        : l10n.overviewMonthlyParcelsEmpty;

    return Semantics(
      label: l10n.overviewMonthlyParcelsChartSemantics,
      child: AppComboChart<OverviewMonthlyParcelPoint>(
        title: l10n.overviewMonthlyParcelsTitle,
        subtitle: l10n.overviewMonthlyParcelsSubtitle,
        items: widget.points,
        xLabelBuilder: (p) => p.anoMes,
        barValueBuilder: (p) => p.qtdVendas,
        barSeriesLabel: l10n.overviewMonthlyParcelsSalesSeriesLabel,
        lineValueBuilder: (p) => p.valorParcela,
        lineSeriesLabel: l10n.overviewMonthlyParcelsAmountSeriesLabel,
        style: AppComboChartStyle(
          height: tokens.chartStandardHeight + tokens.contentSpacing,
          animationDuration: Duration.zero,
          leftAxisFormat: left,
          rightAxisFormat: right,
          chartPadding: EdgeInsets.only(top: tokens.gapSm),
          showRightYAxis: false,
          minCategorySlotWidth: tokens.chartOverviewMonthlyCategoryMinSlotWidth,
          horizontalScrollSemanticsHint:
              l10n.overviewComparisonBarHorizontalScrollHint,
          stickyPrimaryYAxisWhileScrolling: false,
          enableAutoScroll: false,
        ),
        emptyPlaceholder: widget.points.isEmpty
            ? DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.bodyMedium,
                child: _emptyPlaceholder(
                  tokens: tokens,
                  message: emptyMessage,
                )!,
              )
            : null,
      ),
    );
  }
}
