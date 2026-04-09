import 'package:colmeia/features/overview/domain/entities/overview_summary_metric.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_summary_metric_icon_material.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_card.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_icon_badge.dart';
import 'package:flutter/material.dart';

enum OverviewSummaryCardEmphasis {
  standard,
  accent,
  hero,
}

class OverviewSummaryCard extends StatelessWidget {
  const OverviewSummaryCard({
    required this.title,
    required this.value,
    super.key,
    this.deltaLabel,
    this.icon,
    this.leading,
    this.emphasis = OverviewSummaryCardEmphasis.standard,
  }) : assert(
         leading != null || icon != null,
         'OverviewSummaryCard requires icon or leading.',
       );

  final String title;
  final String value;
  final String? deltaLabel;
  final OverviewSummaryMetricIcon? icon;
  final Widget? leading;
  final OverviewSummaryCardEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    final Widget resolvedLeading;
    if (leading != null) {
      resolvedLeading = leading!;
    } else {
      final (Color bg, Color fg) = icon!.kpiBadgeColors(colors);
      resolvedLeading = AppMetricStatIconBadge(
        backgroundColor: bg,
        child: Icon(
          icon!.materialIconData,
          size: 22,
          color: fg,
        ),
      );
    }

    return AppMetricStatCard(
      leading: resolvedLeading,
      trendLabel: deltaLabel,
      label: title,
      value: value,
      emphasis: switch (emphasis) {
        OverviewSummaryCardEmphasis.hero => AppMetricStatCardEmphasis.hero,
        OverviewSummaryCardEmphasis.accent => AppMetricStatCardEmphasis.accent,
        OverviewSummaryCardEmphasis.standard =>
          AppMetricStatCardEmphasis.standard,
      },
      style: AppMetricStatCardStyle(
        borderSide: emphasis == OverviewSummaryCardEmphasis.standard
            ? tokens.cardOutlineBorderSide(cs)
            : null,
      ),
    );
  }
}
