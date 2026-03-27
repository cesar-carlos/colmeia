import 'package:colmeia/features/dashboards/domain/entities/dashboard_category_share.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';

/// Category share bars (Stitch: resumo de vendas por categoria).
class DashboardCategoryMixCard extends StatelessWidget {
  const DashboardCategoryMixCard({
    required this.shares,
    super.key,
  });

  final List<DashboardCategoryShare> shares;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Resumo de vendas por categoria',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.contentSpacing),
          ...shares.asMap().entries.map((entry) {
            final isLast = entry.key == shares.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : tokens.gapMd),
              child: _CategoryShareRow(
                share: entry.value,
                tokens: tokens,
                colorScheme: cs,
                theme: theme,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryShareRow extends StatelessWidget {
  const _CategoryShareRow({
    required this.share,
    required this.tokens,
    required this.colorScheme,
    required this.theme,
  });

  final DashboardCategoryShare share;
  final AppThemeTokens tokens;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final pctLabel = share.percent >= 10
        ? '${share.percent.round()}%'
        : '${share.percent.toStringAsFixed(1)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                share.label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              pctLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.gapSm),
        ClipRRect(
          borderRadius: BorderRadius.circular(tokens.formFieldRadius),
          child: LinearProgressIndicator(
            value: (share.percent / 100).clamp(0, 1),
            minHeight: 8,
            backgroundColor: colorScheme.surfaceContainerHigh,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
