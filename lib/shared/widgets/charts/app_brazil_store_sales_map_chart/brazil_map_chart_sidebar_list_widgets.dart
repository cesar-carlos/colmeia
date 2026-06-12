import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_snapshot.dart';
import 'package:flutter/material.dart';

class BrazilMapChartDesktopBranchSidebarEmptyState extends StatelessWidget {
  const BrazilMapChartDesktopBranchSidebarEmptyState({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colorScheme = theme.colorScheme;

    return Center(
      child: KeyedSubtree(
        key: const ValueKey<String>('brazil-store-sales-map-sidebar-empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.storefront_outlined,
              size: 28,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: tokens.gapSm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: tokens.gapXs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BrazilMapChartDesktopBranchSidebarItem extends StatelessWidget {
  const BrazilMapChartDesktopBranchSidebarItem({
    required this.rank,
    required this.entry,
    required this.focusNode,
    required this.isFocused,
    required this.isSelected,
    required this.onFocus,
    required this.onTap,
    required this.onPreviewStart,
    required this.onPreviewEnd,
    super.key,
  });

  final int rank;
  final AppBrazilStoreSalesVisibleBranchListItem entry;
  final FocusNode focusNode;
  final bool isFocused;
  final bool isSelected;
  final VoidCallback onFocus;
  final VoidCallback onTap;
  final VoidCallback onPreviewStart;
  final VoidCallback onPreviewEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colorScheme = theme.colorScheme;
    final highlight = context.appColors.secondary;
    final amountLabel = AppBrFormatters.currency(entry.salesAmount);
    final statusLabel = _statusLabel(context);
    final rankLabel = '#$rank';

    return Semantics(
      button: true,
      selected: isSelected,
      label: [
        rankLabel,
        entry.displayName,
        if (entry.secondaryDisplayName != null) entry.secondaryDisplayName!,
        entry.cityUfLabel,
        if (statusLabel != null) statusLabel else amountLabel,
      ].join(', '),
      child: MouseRegion(
        onEnter: (_) => onPreviewStart(),
        onExit: (_) => onPreviewEnd(),
        child: InkWell(
          key: ValueKey<String>(
            'brazil-store-sales-map-sidebar-item-${entry.id}',
          ),
          focusNode: focusNode,
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              onFocus();
            }
          },
          borderRadius: BorderRadius.circular(tokens.formFieldRadius),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected
                  ? highlight.withValues(alpha: 0.12)
                  : isFocused
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(tokens.formFieldRadius),
              border: Border.all(
                color: isSelected
                    ? highlight
                    : isFocused
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: isSelected
                    ? 1.8
                    : isFocused
                    ? 1.4
                    : 1,
              ),
              boxShadow: isSelected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: highlight.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.gapSm,
                vertical: tokens.gapXs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.gapXs,
                          vertical: tokens.gapXs * 0.6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? highlight.withValues(alpha: 0.18)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            tokens.formFieldRadius,
                          ),
                        ),
                        child: Text(
                          rankLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? highlight
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(width: tokens.gapXs),
                      Expanded(
                        child: Text(
                          entry.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.gapXs * 0.5),
                  if (entry.secondaryDisplayName != null) ...[
                    Text(
                      entry.secondaryDisplayName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: tokens.gapXs * 0.5),
                  ],
                  Text(
                    entry.cityUfLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: tokens.gapXs),
                  if (entry.state ==
                      AppBrazilStoreSalesVisibleBranchListItemState.loading)
                    BrazilMapChartDesktopBranchSidebarStatusRow(
                      icon: Icons.sync_rounded,
                      label: _statusLabel(context)!,
                      color: highlight,
                    )
                  else ...[
                    Text(
                      amountLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isSelected ? highlight : colorScheme.onSurface,
                      ),
                    ),
                    if (statusLabel != null) ...[
                      SizedBox(height: tokens.gapXs),
                      BrazilMapChartDesktopBranchSidebarStatusRow(
                        icon: _statusIcon,
                        label: statusLabel,
                        color: _statusColor(
                          colorScheme: colorScheme,
                          highlight: highlight,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData get _statusIcon => switch (entry.state) {
    AppBrazilStoreSalesVisibleBranchListItemState.loading => Icons.sync_rounded,
    AppBrazilStoreSalesVisibleBranchListItemState.unavailable =>
      Icons.sync_problem_outlined,
    AppBrazilStoreSalesVisibleBranchListItemState.zeroSales =>
      Icons.remove_shopping_cart_outlined,
    AppBrazilStoreSalesVisibleBranchListItemState.regular => Icons.attach_money,
  };

  String? _statusLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (entry.state) {
      AppBrazilStoreSalesVisibleBranchListItemState.loading =>
        l10n.brazilStoreSalesMapSalesLoadingLabel,
      AppBrazilStoreSalesVisibleBranchListItemState.unavailable =>
        entry.point.salesDataStatusLabel ??
            l10n.brazilStoreSalesMapSalesUnavailableFallback,
      AppBrazilStoreSalesVisibleBranchListItemState.zeroSales =>
        l10n.brazilStoreSalesMapSidebarZeroSalesLabel,
      AppBrazilStoreSalesVisibleBranchListItemState.regular => null,
    };
  }

  Color _statusColor({
    required ColorScheme colorScheme,
    required Color highlight,
  }) {
    return switch (entry.state) {
      AppBrazilStoreSalesVisibleBranchListItemState.loading => highlight,
      AppBrazilStoreSalesVisibleBranchListItemState.unavailable =>
        colorScheme.error,
      AppBrazilStoreSalesVisibleBranchListItemState.zeroSales =>
        colorScheme.onSurfaceVariant,
      AppBrazilStoreSalesVisibleBranchListItemState.regular =>
        colorScheme.onSurface,
    };
  }
}

class BrazilMapChartDesktopBranchSidebarStatusRow extends StatelessWidget {
  const BrazilMapChartDesktopBranchSidebarStatusRow({
    required this.icon,
    required this.label,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Row(
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        SizedBox(width: tokens.gapXs),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
