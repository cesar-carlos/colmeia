import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

/// Compact data row height (36px); aligned with report grid compact density.
const double kAppCompactDataRowHeight = 36;

/// Compact header row height (40px); aligned with report grid compact density.
const double kAppCompactHeaderRowHeight = 40;

/// Row count above which the compact grid body scrolls vertically with a
/// pinned header.
const int kAppCompactDataGridStickyRowThreshold = 7;

/// Max height of the vertically scrollable body when the sticky header is active.
const double kAppCompactDataGridStickyBodyMaxHeight = 288;

/// Divider vertical extent between compact data grid rows.
double appDataGridRowDividerHeight(AppThemeTokens tokens) => tokens.gapSm;

/// Standard cell padding for compact manual data grid rows.
EdgeInsets appDataGridRowPadding(AppThemeTokens tokens) => EdgeInsets.symmetric(
  horizontal: tokens.gapSm,
  vertical: tokens.gapXs,
);

/// Background for compact grid header rows (stronger than body zebra).
Color appDataGridHeaderBackgroundColor(ColorScheme scheme) =>
    scheme.surfaceContainerHigh;

/// Bottom divider color for compact grid header rows.
Color appDataGridHeaderDividerColor(ColorScheme scheme) =>
    scheme.outlineVariant.withValues(alpha: 0.48);

/// Label style for compact grid header cells.
TextStyle appDataGridHeaderLabelStyle({
  required ThemeData theme,
  TextAlign textAlign = TextAlign.start,
}) {
  final typography = theme.appTypography;
  return typography.utilityOverline.copyWith(
    letterSpacing: 0.2,
    color: theme.colorScheme.onSurface,
    fontWeight: FontWeight.w700,
    height: textAlign == TextAlign.end ? 1.2 : 1.3,
  );
}

/// Decoration shell for a full-width compact grid header row.
BoxDecoration appDataGridHeaderDecoration(ColorScheme scheme) => BoxDecoration(
  color: appDataGridHeaderBackgroundColor(scheme),
  border: Border(
    bottom: BorderSide(color: appDataGridHeaderDividerColor(scheme)),
  ),
);

/// Single skeleton placeholder row matching [kAppCompactDataRowHeight].
Widget appDataGridSkeletonRowPlaceholder(AppThemeTokens tokens) {
  return ConstrainedBox(
    constraints: const BoxConstraints(minHeight: kAppCompactDataRowHeight),
    child: Padding(
      padding: appDataGridRowPadding(tokens),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );
}

/// Loading skeleton block with [rowCount] compact rows and dividers.
Widget appDataGridSkeletonColumn({
  required AppThemeTokens tokens,
  required Color dividerColor,
  int rowCount = 5,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      for (var i = 0; i < rowCount; i++) ...<Widget>[
        appDataGridSkeletonRowPlaceholder(tokens),
        if (i < rowCount - 1)
          Divider(
            height: appDataGridRowDividerHeight(tokens),
            color: dividerColor,
          ),
      ],
    ],
  );
}
