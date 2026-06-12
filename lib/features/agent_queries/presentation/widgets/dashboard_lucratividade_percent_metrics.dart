import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_percent_metric.dart';
import 'package:colmeia/features/agent_queries/presentation/lucratividade_percent_metric_labels.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';

/// Sub-selector for [LucratividadePercentMetric] plus explanation text.
class DashboardLucratividadePercentMetricSection extends StatelessWidget {
  const DashboardLucratividadePercentMetricSection({
    required this.l10n,
    required this.tokens,
    required this.metric,
    required this.onMetricChanged,
    required this.hasChartData,
    super.key,
    this.useDropdownLayout = false,
    this.showChronologicalHint = false,
  });

  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final LucratividadePercentMetric metric;
  final ValueChanged<LucratividadePercentMetric> onMetricChanged;

  /// When true (narrow layout), uses a dropdown instead of a second segmented control.
  final bool useDropdownLayout;

  /// When false, shows the empty-state copy instead of the formula explanation.
  final bool hasChartData;

  /// Monthly chart only: short note that months stay chronological in percent mode.
  final bool showChronologicalHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final explanation = lucratividadePercentMetricExplanation(l10n, metric);
    final semanticsSummary = lucratividadePercentMetricSemanticsLabel(
      l10n,
      metric,
    );
    final emptyHelp = l10n.overviewLucratividadePercentEmptyHelp;

    final selector = useDropdownLayout
        ? Row(
            children: <Widget>[
              Text(
                l10n.overviewLucratividadePercentIndicatorLabel,
                style: theme.textTheme.labelLarge,
              ),
              SizedBox(width: tokens.gapSm),
              Expanded(
                child: DropdownButton<LucratividadePercentMetric>(
                  value: metric,
                  isExpanded: true,
                  items: <DropdownMenuItem<LucratividadePercentMetric>>[
                    DropdownMenuItem(
                      value: LucratividadePercentMetric.costOverRevenue,
                      child: Text(
                        l10n.overviewLucratividadePercentMetricCostShort,
                      ),
                    ),
                    DropdownMenuItem(
                      value: LucratividadePercentMetric.grossMargin,
                      child: Text(
                        l10n.overviewLucratividadePercentMetricGrossShort,
                      ),
                    ),
                    DropdownMenuItem(
                      value: LucratividadePercentMetric.markupOverCost,
                      child: Text(
                        l10n.overviewLucratividadePercentMetricMarkupShort,
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      onMetricChanged(v);
                    }
                  },
                ),
              ),
            ],
          )
        : AppSegmentedControl<LucratividadePercentMetric>(
            expandToFill: true,
            options: <AppSegmentedControlOption<LucratividadePercentMetric>>[
              AppSegmentedControlOption<LucratividadePercentMetric>(
                value: LucratividadePercentMetric.costOverRevenue,
                label: l10n.overviewLucratividadePercentMetricCostShort,
                tooltip: lucratividadePercentMetricSegmentTooltip(
                  l10n,
                  LucratividadePercentMetric.costOverRevenue,
                ),
              ),
              AppSegmentedControlOption<LucratividadePercentMetric>(
                value: LucratividadePercentMetric.grossMargin,
                label: l10n.overviewLucratividadePercentMetricGrossShort,
                tooltip: lucratividadePercentMetricSegmentTooltip(
                  l10n,
                  LucratividadePercentMetric.grossMargin,
                ),
              ),
              AppSegmentedControlOption<LucratividadePercentMetric>(
                value: LucratividadePercentMetric.markupOverCost,
                label: l10n.overviewLucratividadePercentMetricMarkupShort,
                tooltip: lucratividadePercentMetricSegmentTooltip(
                  l10n,
                  LucratividadePercentMetric.markupOverCost,
                ),
              ),
            ],
            value: metric,
            onChanged: onMetricChanged,
          );

    final bodyStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.overviewLucratividadePercentIndicatorHeading,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.gapSm / 2),
        selector,
        SizedBox(height: tokens.gapSm),
        Semantics(
          label: hasChartData ? semanticsSummary : emptyHelp,
          child: Text(
            hasChartData ? explanation : emptyHelp,
            style: bodyStyle,
          ),
        ),
        if (showChronologicalHint && hasChartData) ...<Widget>[
          SizedBox(height: tokens.gapSm),
          Text(
            l10n.overviewLucratividadeMensalPercentChronologicalHint,
            style: bodyStyle,
          ),
        ],
      ],
    );
  }
}
