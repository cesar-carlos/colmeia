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

  static const double _scrollTileWidthFraction = 0.42;
  static const double _minScrollTileWidth = 136;
  static const double _maxScrollTileWidth = 176;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 640) {
            final scrollTileWidth =
                (constraints.maxWidth * _scrollTileWidthFraction).clamp(
                  _minScrollTileWidth,
                  _maxScrollTileWidth,
                );
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: items.indexed
                    .expand<Widget>((entry) {
                      final i = entry.$1;
                      final item = entry.$2;
                      return <Widget>[
                        if (i > 0) SizedBox(width: tokens.gapMd),
                        SizedBox(
                          width: scrollTileWidth,
                          child: _SummaryTile(item: item),
                        ),
                      ];
                    })
                    .toList(growable: false),
              ),
            );
          }

          final tileWidth = ((constraints.maxWidth - tokens.gapMd) / 2).clamp(
            180.0,
            320.0,
          );

          return Wrap(
            spacing: tokens.gapMd,
            runSpacing: tokens.gapMd,
            children: items
                .map(
                  (item) => SizedBox(
                    width: tileWidth,
                    child: _SummaryTile(item: item),
                  ),
                )
                .toList(growable: false),
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

    return DecoratedBox(
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
                    Icon(
                      item.icon,
                      size: 14,
                      color: colors.onSurfaceVariant,
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
    );
  }
}
