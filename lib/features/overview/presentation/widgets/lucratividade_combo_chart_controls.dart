import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_percent_metric.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/dashboard_lucratividade_percent_metrics.dart';
import 'package:colmeia/features/overview/presentation/widgets/lucratividade_combo_chart_types.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Main display mode control plus optional percent-metric sub-selector.
class LucratividadeComboChartControls extends StatelessWidget {
  const LucratividadeComboChartControls({
    required this.l10n,
    required this.copy,
    required this.tokens,
    required this.display,
    required this.percentMetric,
    required this.hasChartData,
    required this.onDisplayChanged,
    required this.onPercentMetricChanged,
    super.key,
  });

  final AppLocalizations l10n;
  final LucratividadeComboChartCopy copy;
  final AppThemeTokens tokens;
  final LucratividadeComboDisplay display;
  final LucratividadePercentMetric percentMetric;
  final bool hasChartData;
  final ValueChanged<LucratividadeComboDisplay> onDisplayChanged;
  final ValueChanged<LucratividadePercentMetric> onPercentMetricChanged;

  @override
  Widget build(BuildContext context) {
    final isPercent = display == LucratividadeComboDisplay.percentMetrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          sortKey: const OrdinalSortKey(1),
          child: AppSegmentedControl<LucratividadeComboDisplay>(
            options: <AppSegmentedControlOption<LucratividadeComboDisplay>>[
              AppSegmentedControlOption<LucratividadeComboDisplay>(
                value: LucratividadeComboDisplay.profitRevenue,
                label: copy.switchProfit,
              ),
              AppSegmentedControlOption<LucratividadeComboDisplay>(
                value: LucratividadeComboDisplay.revenueCost,
                label: copy.switchRevenue,
              ),
              AppSegmentedControlOption<LucratividadeComboDisplay>(
                value: LucratividadeComboDisplay.costRevenue,
                label: copy.switchCost,
              ),
              AppSegmentedControlOption<LucratividadeComboDisplay>(
                value: LucratividadeComboDisplay.percentMetrics,
                label: copy.switchMargin,
              ),
            ],
            value: display,
            onChanged: onDisplayChanged,
          ),
        ),
        if (isPercent) ...<Widget>[
          SizedBox(height: tokens.gapSm),
          Semantics(
            sortKey: const OrdinalSortKey(2),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 380;
                return DashboardLucratividadePercentMetricSection(
                  l10n: l10n,
                  tokens: tokens,
                  metric: percentMetric,
                  useDropdownLayout: narrow,
                  hasChartData: hasChartData,
                  showChronologicalHint: copy.showChronologicalPercentHint,
                  onMetricChanged: onPercentMetricChanged,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
