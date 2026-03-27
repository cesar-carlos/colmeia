import 'package:colmeia/features/dashboards/domain/entities/dashboard_summary_metric.dart';
import 'package:colmeia/features/dashboards/presentation/widgets/dashboard_summary_metric_icon_material.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';

enum DashboardSummaryCardEmphasis { standard, accent }

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({
    required this.title,
    required this.value,
    required this.deltaLabel,
    required this.icon,
    super.key,
    this.emphasis = DashboardSummaryCardEmphasis.standard,
  });

  final String title;
  final String value;
  final String deltaLabel;
  final DashboardSummaryMetricIcon icon;
  final DashboardSummaryCardEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;
    final trimmedDelta = deltaLabel.trim();
    final deltaNegative =
        trimmedDelta.startsWith('-') || trimmedDelta.startsWith('−');
    final deltaColor = deltaNegative ? cs.error : cs.tertiary;
    final cardColor = switch (emphasis) {
      DashboardSummaryCardEmphasis.accent => Color.alphaBlend(
        cs.primaryContainer.withValues(alpha: 0.65),
        cs.surfaceContainerLowest,
      ),
      DashboardSummaryCardEmphasis.standard => null,
    };

    return AppSectionCard(
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                icon.materialIconData,
                size: 22,
                color: cs.primary,
              ),
              SizedBox(width: tokens.gapSm),
              Expanded(
                child: Text(
                  deltaLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: deltaColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.gapMd),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.gapXs),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
