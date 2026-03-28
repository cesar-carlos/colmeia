import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';

/// Horizontal strip of KPI tiles built from [AppReportSummaryItem] list.
///
/// Scrolls horizontally when items overflow, so it stays readable on compact
/// screens.
class AppReportSummaryBar extends StatelessWidget {
  const AppReportSummaryBar({
    required this.items,
    super.key,
    this.color,
  });

  final List<AppReportSummaryItem> items;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    if (items.isEmpty) return const SizedBox.shrink();

    return AppSectionCard(
      color: color ?? theme.colorScheme.surfaceContainerLow,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.contentSpacing,
        vertical: tokens.gapMd,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Row(
            children: items.indexed.expand<Widget>((entry) {
              final i = entry.$1;
              final item = entry.$2;
              return <Widget>[
                if (i > 0) ...<Widget>[
                  SizedBox(width: tokens.gapMd),
                  VerticalDivider(
                    width: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  SizedBox(width: tokens.gapMd),
                ],
                _SummaryTile(item: item),
              ];
            }).toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.item});

  final AppReportSummaryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (item.icon != null) ...<Widget>[
              Icon(
                item.icon,
                size: 14,
                color: colors.onSurfaceVariant,
              ),
              SizedBox(width: tokens.gapXs),
            ],
            Text(
              item.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.gapXs),
        Text(
          item.value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: item.valueColor,
          ),
        ),
        if (item.detailLabel != null) ...<Widget>[
          SizedBox(height: tokens.gapXs / 2),
          Text(
            item.detailLabel!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}
