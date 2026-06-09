import 'package:colmeia/shared/design_system/app_data_grid_density.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';

abstract final class ClientAgentsRequestsSortColumns {
  static const String name = 'name';
  static const String status = 'status';
  static const String date = 'date';
}

class ClientAgentsDataGridHeaderShell extends StatelessWidget {
  const ClientAgentsDataGridHeaderShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    return DecoratedBox(
      decoration: appDataGridHeaderDecoration(theme.colorScheme),
      child: SizedBox(
        height: kAppCompactHeaderRowHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.gapSm),
            child: child,
          ),
        ),
      ),
    );
  }
}

class ClientAgentsDataGridSortableHeaderCell extends StatelessWidget {
  const ClientAgentsDataGridSortableHeaderCell({
    required this.label,
    required this.style,
    required this.columnKey,
    required this.currentSort,
    required this.onPressed,
    super.key,
    this.width,
    this.textAlign = TextAlign.start,
  });

  final String label;
  final TextStyle? style;
  final String columnKey;
  final AppReportSortDescriptor? currentSort;
  final VoidCallback onPressed;
  final double? width;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final isActive = currentSort?.columnKey == columnKey;
    final icon = !isActive
        ? Icons.unfold_more_rounded
        : currentSort!.direction == AppReportSortDirection.ascending
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    final cell = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(
                label,
                style: style,
                textAlign: textAlign,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );

    if (width == null) {
      return cell;
    }
    return SizedBox(width: width, child: cell);
  }
}

class ClientAgentsDataGridActionIconButton extends StatelessWidget {
  const ClientAgentsDataGridActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(
          minWidth: kAppCompactDataRowHeight,
          minHeight: kAppCompactDataRowHeight,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class ClientAgentsTableLoadingSkeleton extends StatelessWidget {
  const ClientAgentsTableLoadingSkeleton({super.key, this.rowCount = 5});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final dividerColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.35,
    );
    final headerStyle = appDataGridHeaderLabelStyle(theme: theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClientAgentsDataGridHeaderShell(
          child: Row(
            children: <Widget>[
              Expanded(child: Text('Header', style: headerStyle)),
              Expanded(child: Text('Header', style: headerStyle)),
              Expanded(child: Text('Header', style: headerStyle)),
            ],
          ),
        ),
        appDataGridSkeletonColumn(
          tokens: tokens,
          dividerColor: dividerColor,
          rowCount: rowCount,
        ),
      ],
    );
  }
}
