import 'dart:math' as math;

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_approved_agents_table.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_data_grid_widgets.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_shared_widgets.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_data_grid_density.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_compact_data_grid_scroll_table.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClientAgentsRequestTableRowData {
  const ClientAgentsRequestTableRowData({
    required this.name,
    required this.description,
    required this.statusLabel,
    required this.statusKind,
    required this.statusSortRank,
    this.date,
    this.showRetry = false,
    this.showDiscard = false,
    this.onRetry,
    this.onDiscard,
  });

  final String name;
  final String description;
  final String statusLabel;
  final ClientAgentsStatusChipKind statusKind;
  final int statusSortRank;
  final DateTime? date;
  final bool showRetry;
  final bool showDiscard;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;
}

abstract final class ClientAgentsRequestsTableLayout {
  static double _name(AppThemeTokens t) => math.max(160, t.gapMd * 14);
  static double _description(AppThemeTokens t) => math.max(200, t.gapMd * 16);
  static double _status(AppThemeTokens t) => math.max(120, t.gapMd * 10);
  static double _date(AppThemeTokens t) => math.max(120, t.gapMd * 10);
  static double _actions(AppThemeTokens t) => math.max(88, t.gapMd * 7);

  static double minWidth({required AppThemeTokens tokens}) {
    return _name(tokens) +
        _description(tokens) +
        _status(tokens) +
        _date(tokens) +
        _actions(tokens);
  }

  static double minScrollContentWidth({required AppThemeTokens tokens}) =>
      minWidth(tokens: tokens) + 2 * tokens.gapSm;
}

class ClientAgentsRequestsTable extends StatelessWidget {
  const ClientAgentsRequestsTable({
    required this.l10n,
    required this.rows,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.onPageSelected,
    required this.onPageSizeChanged,
    required this.isMutating,
    required this.currentSort,
    required this.onSortChanged,
    super.key,
  });

  final AppLocalizations l10n;
  final List<ClientAgentsRequestTableRowData> rows;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageSelected;
  final ValueChanged<int> onPageSizeChanged;
  final bool isMutating;
  final AppReportSortDescriptor? currentSort;
  final ValueChanged<AppReportSortDescriptor?> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final rowNumber = NumberFormat.decimalPattern(l10n.localeName);
    final totalPages = totalCount == 0 ? 0 : (totalCount / pageSize).ceil();
    final rangeStart = totalCount == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
    final rangeEnd = totalCount == 0
        ? 0
        : math.min(currentPage * pageSize, totalCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (rows.isNotEmpty) ...<Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              final minTable =
                  ClientAgentsRequestsTableLayout.minScrollContentWidth(
                    tokens: tokens,
                  );
              final outer = constraints.maxWidth;
              final contentWidth = outer.isFinite && outer > 0
                  ? math.max(outer, minTable)
                  : minTable;
              return AppCompactDataGridScrollTable(
                contentWidth: contentWidth,
                itemCount: rows.length,
                semanticsHint: l10n.clientAgentsRequestsTableHorizontalScroll,
                header: ClientAgentsRequestsTableHeader(
                  l10n: l10n,
                  currentSort: currentSort,
                  onSortChanged: onSortChanged,
                ),
                itemBuilder: (context, index) {
                  return ClientAgentsRequestsTableRow(
                    row: rows[index],
                    l10n: l10n,
                    isMutating: isMutating,
                  );
                },
              );
            },
          ),
          SizedBox(height: tokens.contentSpacing),
          AppTablePaginationFooter(
            currentPage: currentPage,
            totalPages: totalPages,
            pageSize: pageSize,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            totalItems: totalCount,
            entityLabel: l10n.clientAgentsRequestsPaginationEntityLabel,
            pageSizeOptions: kClientAgentsApprovedTablePageSizeOptions,
            itemsPerPageLabel: l10n.salesProdutoTendenciaFilterPageSize,
            onPageSizeChanged: onPageSizeChanged,
            onPrevious: currentPage > 1
                ? () => onPageSelected(currentPage - 1)
                : null,
            onNext: currentPage < totalPages
                ? () => onPageSelected(currentPage + 1)
                : null,
            onPageSelected: onPageSelected,
          ),
          if (totalCount > pageSize) ...<Widget>[
            SizedBox(height: tokens.gapSm),
            Text(
              l10n.salesProdutoTendenciaDetailsNotice(
                rowNumber.format(pageSize),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class ClientAgentsRequestsTableHeader extends StatelessWidget {
  const ClientAgentsRequestsTableHeader({
    required this.l10n,
    required this.currentSort,
    required this.onSortChanged,
    super.key,
  });

  final AppLocalizations l10n;
  final AppReportSortDescriptor? currentSort;
  final ValueChanged<AppReportSortDescriptor?> onSortChanged;

  void _toggleSort(String columnKey) {
    if (currentSort?.columnKey != columnKey) {
      onSortChanged(
        AppReportSortDescriptor(
          columnKey: columnKey,
          direction: AppReportSortDirection.descending,
        ),
      );
      return;
    }
    if (currentSort!.direction == AppReportSortDirection.descending) {
      onSortChanged(
        AppReportSortDescriptor(
          columnKey: columnKey,
          direction: AppReportSortDirection.ascending,
        ),
      );
      return;
    }
    onSortChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final style = appDataGridHeaderLabelStyle(theme: theme);
    return ClientAgentsDataGridHeaderShell(
      child: Row(
        children: <Widget>[
          ClientAgentsDataGridSortableHeaderCell(
            label: l10n.clientAgentsApprovedColName,
            style: style,
            columnKey: ClientAgentsRequestsSortColumns.name,
            currentSort: currentSort,
            width: ClientAgentsRequestsTableLayout._name(tokens),
            onPressed: () => _toggleSort(ClientAgentsRequestsSortColumns.name),
          ),
          SizedBox(
            width: ClientAgentsRequestsTableLayout._description(tokens),
            child: Text(l10n.clientAgentsRequestsColDescription, style: style),
          ),
          ClientAgentsDataGridSortableHeaderCell(
            label: l10n.clientAgentsRequestsColStatus,
            style: style,
            columnKey: ClientAgentsRequestsSortColumns.status,
            currentSort: currentSort,
            width: ClientAgentsRequestsTableLayout._status(tokens),
            onPressed: () =>
                _toggleSort(ClientAgentsRequestsSortColumns.status),
          ),
          ClientAgentsDataGridSortableHeaderCell(
            label: l10n.clientAgentsRequestsColDate,
            style: style,
            columnKey: ClientAgentsRequestsSortColumns.date,
            currentSort: currentSort,
            width: ClientAgentsRequestsTableLayout._date(tokens),
            onPressed: () => _toggleSort(ClientAgentsRequestsSortColumns.date),
          ),
          SizedBox(
            width: ClientAgentsRequestsTableLayout._actions(tokens),
            child: Text(l10n.clientAgentsApprovedColActions, style: style),
          ),
        ],
      ),
    );
  }
}

class ClientAgentsRequestsTableRow extends StatelessWidget {
  const ClientAgentsRequestsTableRow({
    required this.row,
    required this.l10n,
    required this.isMutating,
    super.key,
  });

  final ClientAgentsRequestTableRowData row;
  final AppLocalizations l10n;
  final bool isMutating;

  static const String _missingDateLabel = '—';

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final dateLabel = row.date == null
        ? _missingDateLabel
        : AppBrFormatters.shortDateTimeFormat.format(row.date!);

    return Padding(
      padding: appDataGridRowPadding(tokens),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kAppCompactDataRowHeight),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: ClientAgentsRequestsTableLayout._name(tokens),
              child: Text(
                row.name,
                softWrap: true,
                maxLines: 4,
              ),
            ),
            SizedBox(
              width: ClientAgentsRequestsTableLayout._description(tokens),
              child: Text(
                row.description,
                softWrap: true,
                maxLines: 4,
              ),
            ),
            SizedBox(
              width: ClientAgentsRequestsTableLayout._status(tokens),
              child: ClientAgentsStatusChip(
                label: row.statusLabel,
                kind: row.statusKind,
              ),
            ),
            SizedBox(
              width: ClientAgentsRequestsTableLayout._date(tokens),
              child: Text(
                dateLabel,
                softWrap: true,
                maxLines: 2,
              ),
            ),
            SizedBox(
              width: ClientAgentsRequestsTableLayout._actions(tokens),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (row.showRetry && row.onRetry != null)
                    ClientAgentsDataGridActionIconButton(
                      tooltip: l10n.clientAgentsRetryRequestAction,
                      icon: Icons.refresh_rounded,
                      onPressed: isMutating ? null : row.onRetry,
                    ),
                  if (row.showDiscard && row.onDiscard != null)
                    ClientAgentsDataGridActionIconButton(
                      tooltip: l10n.clientAgentsDiscardQueuedRequestAction,
                      icon: Icons.delete_outline_rounded,
                      onPressed: isMutating ? null : row.onDiscard,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
