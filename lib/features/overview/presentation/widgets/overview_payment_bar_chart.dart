import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';

class OverviewPaymentBarChart extends StatelessWidget {
  const OverviewPaymentBarChart({
    required this.l10n,
    required this.methods,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewPaymentMethodBreakdown> methods;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final sorted = List<OverviewPaymentMethodBreakdown>.of(methods)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
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
