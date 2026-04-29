import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';

double _twoLineLabelBlockHeight(TextStyle labelStyle, TextScaler scaler) {
  final fontSize = labelStyle.fontSize ?? 10;
  final heightFactor = labelStyle.height ?? 1.35;
  return scaler.scale(fontSize) * heightFactor * 2;
}

/// KPI tiles from [AppReportSummaryItem] in a **two-column** grid that always
/// stretches to the card’s inner width (same edge alignment as other section
/// cards on narrow and wide layouts).
class AppReportSummaryBar extends StatelessWidget {
  const AppReportSummaryBar({
    required this.items,
    super.key,
    this.color,
  });

  final List<AppReportSummaryItem> items;
  final Color? color;

  static List<Widget> _summaryGridRows({
    required List<AppReportSummaryItem> items,
    required double gap,
    required int crossAxisCount,
  }) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += crossAxisCount) {
      if (i > 0) {
        rows.add(SizedBox(height: gap));
      }
      final rowChildren = <Widget>[];
      for (var j = 0; j < crossAxisCount; j++) {
        if (j > 0) {
          rowChildren.add(SizedBox(width: gap));
        }
        if (i + j < items.length) {
          rowChildren.add(Expanded(child: _SummaryTile(item: items[i + j])));
        } else {
          rowChildren.add(const Expanded(child: SizedBox.shrink()));
        }
      }
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren,
        ),
      );
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    if (items.isEmpty) return const SizedBox.shrink();

    final gap = tokens.gapMd;

    return AppSectionCard(
      color: color ?? theme.colorScheme.surfaceContainerLow,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.contentSpacing,
        vertical: tokens.gapMd,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 600 ? 4 : 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _summaryGridRows(
              items: items,
              gap: gap,
              crossAxisCount: crossAxisCount,
            ),
          );
        },
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
    final typography = theme.appTypography;
    final labelStyle = typography.utilityOverline.copyWith(
      color: colors.onSurfaceVariant,
    );
    final labelBlockHeight = _twoLineLabelBlockHeight(
      labelStyle,
      MediaQuery.textScalerOf(context),
    );

    // Merge all texts into a single semantics node so screen readers announce
    // the KPI tile as one logical unit ("label, value, detail") instead of
    // three separate elements.
    return MergeSemantics(
      child: Tooltip(
        message: item.detailLabel != null
            ? '${item.label} — ${item.detailLabel}'
            : item.label,
        waitDuration: const Duration(milliseconds: 600),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(tokens.formFieldRadius),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(tokens.gapMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: labelBlockHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (item.icon != null) ...<Widget>[
                        ExcludeSemantics(
                          child: Icon(
                            item.icon,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(width: tokens.gapXs),
                      ],
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: labelStyle,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: tokens.gapXs),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.sectionHeaderH2.copyWith(
                    fontWeight: FontWeight.w700,
                    color: item.valueColor,
                  ),
                ),
                if (item.detailLabel != null) ...<Widget>[
                  SizedBox(height: tokens.gapXs / 2),
                  Text(
                    item.detailLabel!,
                    style: typography.caption.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
