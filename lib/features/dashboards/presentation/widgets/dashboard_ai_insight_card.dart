import 'package:colmeia/features/dashboards/domain/entities/dashboard_ai_insight.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';

/// Stitch-style IA insight callout: tonal surface and operational CTA.
class DashboardAiInsightCard extends StatelessWidget {
  const DashboardAiInsightCard({
    required this.insight,
    this.onApply,
    super.key,
  });

  final DashboardAiInsight insight;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return AppSectionCard(
      color: cs.secondaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.lightbulb_outline,
                color: cs.primary,
                size: 26,
              ),
              SizedBox(width: tokens.gapSm),
              Expanded(
                child: Text(
                  insight.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.gapMd),
          Text(
            insight.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.35,
            ),
          ),
          SizedBox(height: tokens.gapMd),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onApply,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                minimumSize: Size(48, tokens.actionButtonMinHeight),
              ),
              child: Text(
                insight.ctaLabel.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
