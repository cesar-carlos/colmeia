import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';

/// "Revenue by payment method" home card.
///
/// Caches the sorted, non-zero list while [methods] keeps the same identity so
/// the staged dashboard pipeline doesn't re-sort + re-filter on every parent
/// rebuild (e.g. while sibling chart stages are still mounting).
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
  late List<OverviewPaymentMethodBreakdown> _nonZeroSorted;

  void _recomputeIfNeeded() {
    if (identical(_methodsRef, widget.methods)) {
      return;
    }
    _methodsRef = widget.methods;
    final sorted = List<OverviewPaymentMethodBreakdown>.of(widget.methods)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    _nonZeroSorted = <OverviewPaymentMethodBreakdown>[
      for (final m in sorted)
        if (m.totalAmount > 0) m,
    ];
  }

  @override
  void initState() {
    super.initState();
    _recomputeIfNeeded();
  }

  @override
  void didUpdateWidget(covariant OverviewPaymentBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recomputeIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = widget.l10n;
    final showEmpty = widget.methods.isEmpty || _nonZeroSorted.isEmpty;
    return AppComparisonBarChart<OverviewPaymentMethodBreakdown>(
      title: l10n.overviewPaymentBarTitle,
      subtitle: l10n.overviewPaymentBarSubtitle,
      items: _nonZeroSorted,
      plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
      extremeSpreadAccessibilityNotice:
          l10n.chartComparisonExtremeValueSpreadNotice,
      labelBuilder: (m) => m.label,
      valueBuilder: (m) => m.totalAmount,
      tooltipLabelBuilder: (m, v) => l10n.overviewPaymentBarTooltip(
        m.label,
        AppBrFormatters.currency(v),
      ),
      // Smart formatter: bars below R$ 1.000 show the full currency
      // ("R$ 26,80") so they aren't visually mistaken for thousands.
      dataLabelBuilder: (m, v) => AppBrFormatters.smartCompactCurrency(v),
      style: overviewHomeComparisonBarChartStyle(
        tokens: tokens,
        kind: OverviewHomeBarChartKind.payment,
        l10n: l10n,
      ),
      emptyPlaceholder: showEmpty
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.contentSpacing),
              child: Center(
                child: Text(
                  l10n.overviewPaymentBarEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          : null,
    );
  }
}
