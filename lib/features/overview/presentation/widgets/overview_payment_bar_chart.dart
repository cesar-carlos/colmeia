import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';

class OverviewPaymentBarChart extends StatefulWidget {
  const OverviewPaymentBarChart({
    required this.l10n,
    required this.methods,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewPaymentMethodBreakdown> methods;

  @override
  State<OverviewPaymentBarChart> createState() =>
      _OverviewPaymentBarChartState();
}

class _OverviewPaymentBarChartState extends State<OverviewPaymentBarChart> {
  List<OverviewPaymentMethodBreakdown>? _methodsRef;
  late List<OverviewPaymentMethodBreakdown> _sortedMethods;

  void _recomputeSortedIfNeeded() {
    if (identical(_methodsRef, widget.methods)) {
      return;
    }
    _methodsRef = widget.methods;
    _sortedMethods = List<OverviewPaymentMethodBreakdown>.of(widget.methods)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  }

  @override
  void initState() {
    super.initState();
    _sortedMethods = List<OverviewPaymentMethodBreakdown>.of(widget.methods)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    _methodsRef = widget.methods;
  }

  @override
  void didUpdateWidget(covariant OverviewPaymentBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recomputeSortedIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = widget.l10n;
    final sorted = _sortedMethods;
    return AppComparisonBarChart<OverviewPaymentMethodBreakdown>(
      title: l10n.overviewPaymentBarTitle,
      subtitle: l10n.overviewPaymentBarSubtitle,
      items: sorted,
      plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
      extremeSpreadAccessibilityNotice:
          l10n.chartComparisonExtremeValueSpreadNotice,
      labelBuilder: (m) => m.label,
      valueBuilder: (m) => m.totalAmount,
      tooltipLabelBuilder: (m, v) => l10n.overviewPaymentBarTooltip(
        m.label,
        AppBrFormatters.currency(v),
      ),
      dataLabelBuilder: (m, v) => AppBrFormatters.compactCurrency(v),
      style: overviewHomeComparisonBarChartStyle(
        tokens: tokens,
        kind: OverviewHomeBarChartKind.payment,
        l10n: l10n,
      ),
    );
  }
}
