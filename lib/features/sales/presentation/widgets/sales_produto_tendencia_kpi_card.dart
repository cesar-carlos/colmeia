import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_card.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_icon_badge.dart';
import 'package:flutter/material.dart';

class SalesProdutoTendenciaKpiCard extends StatelessWidget {
  const SalesProdutoTendenciaKpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconForeground,
    this.emphasis = AppMetricStatCardEmphasis.standard,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconForeground;
  final AppMetricStatCardEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final colors = theme.appColors;
    final colorScheme = theme.colorScheme;

    return AppMetricStatCard(
      emphasis: emphasis,
      leading: AppMetricStatIconBadge(
        backgroundColor: _iconBadgeBackground(colors, iconForeground),
        child: Icon(icon, size: 22, color: iconForeground),
      ),
      label: label,
      value: value,
      style: AppMetricStatCardStyle(
        borderSide: emphasis == AppMetricStatCardEmphasis.standard
            ? tokens.cardOutlineBorderSide(colorScheme)
            : null,
      ),
    );
  }

  static Color _iconBadgeBackground(AppColors colors, Color foreground) {
    return Color.alphaBlend(
      foreground.withValues(alpha: 0.16),
      colors.surfaceContainerLowest,
    );
  }
}
