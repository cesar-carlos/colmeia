import 'dart:math' as math;

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_ranking_produtos_faturamento_grid_style.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_ranking_produtos_faturamento_rank_badge.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_data_grid_density.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Right padding so the vertical scrollbar does not cover numeric columns.
const double _kRankingFaturamentoTableScrollbarGutter = 14;

/// Detailed rows table aligned with produto tendencia detailed-rows styling:
/// horizontal dividers only, compact rows, accent percent column.
class SalesRankingProdutosFaturamentoDetailsTable extends StatelessWidget {
  const SalesRankingProdutosFaturamentoDetailsTable({
    required this.l10n,
    required this.rows,
    required this.currentSorts,
    required this.onSortChanged,
    super.key,
    this.maxHeight,
    this.expandVertically = false,
    this.isLoading = false,
  });

  final AppLocalizations l10n;
  final List<RankingProdutosFaturamentoRow> rows;
  final List<AppReportSortDescriptor> currentSorts;
  final ValueChanged<List<AppReportSortDescriptor>> onSortChanged;
  final double? maxHeight;
  final bool expandVertically;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final dividerColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.35,
    );
    final headerDividerColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.5,
    );

    if (isLoading && rows.isEmpty) {
      return _RankingFaturamentoLoadingPlaceholder(tokens: tokens);
    }

    if (rows.isEmpty) {
      return Text(
        l10n.salesRankingProdutosFaturamentoEmptyMessage,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final header = _RankingFaturamentoTableHeader(
      l10n: l10n,
      currentSorts: currentSorts,
      onSortChanged: onSortChanged,
    );

    final boundedVertically = expandVertically || maxHeight != null;

    final list = _RankingFaturamentoScrollableBody(
      rows: rows,
      l10n: l10n,
      dividerColor: dividerColor,
      shrinkWrap: !boundedVertically,
    );

    final scrollableBody = boundedVertically ? Expanded(child: list) : list;

    final tableColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        header,
        Divider(
          height: appDataGridRowDividerHeight(tokens),
          color: headerDividerColor,
        ),
        scrollableBody,
      ],
    );

    if (maxHeight != null && !expandVertically) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: tableColumn,
      );
    }

    return tableColumn;
  }
}

class _RankingFaturamentoLoadingPlaceholder extends StatelessWidget {
  const _RankingFaturamentoLoadingPlaceholder({required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.35,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var i = 0; i < 5; i++) ...<Widget>[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.gapSm,
              vertical: tokens.gapSm,
            ),
            child: const Text(
              '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (i < 4)
            Divider(
              height: appDataGridRowDividerHeight(tokens),
              color: dividerColor,
            ),
        ],
      ],
    );
  }
}

class _RankingFaturamentoScrollableBody extends StatefulWidget {
  const _RankingFaturamentoScrollableBody({
    required this.rows,
    required this.l10n,
    required this.dividerColor,
    this.shrinkWrap = true,
  });

  final List<RankingProdutosFaturamentoRow> rows;
  final AppLocalizations l10n;
  final Color dividerColor;
  final bool shrinkWrap;

  @override
  State<_RankingFaturamentoScrollableBody> createState() =>
      _RankingFaturamentoScrollableBodyState();
}

class _RankingFaturamentoScrollableBodyState
    extends State<_RankingFaturamentoScrollableBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;
    final divider = Divider(
      height: appDataGridRowDividerHeight(tokens),
      color: widget.dividerColor,
    );

    final listView = ListView.separated(
      controller: _scrollController,
      shrinkWrap: widget.shrinkWrap,
      primary: false,
      padding: const EdgeInsets.only(
        right: _kRankingFaturamentoTableScrollbarGutter,
      ),
      physics: const ClampingScrollPhysics(),
      itemCount: widget.rows.length,
      separatorBuilder: (_, _) => divider,
      itemBuilder: (context, index) {
        return _RankingFaturamentoTableRow(
          row: widget.rows[index],
          l10n: widget.l10n,
        );
      },
    );

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: false,
        interactive: true,
        child: listView,
      ),
    );
  }
}

abstract final class _RankingFaturamentoTableLayout {
  static double posicao(AppThemeTokens t) => math.max(52, t.gapMd * 5);
  static double venda(AppThemeTokens t) => math.max(104, t.gapMd * 9);
  static double percentual(AppThemeTokens t) => math.max(88, t.gapMd * 8);
}

class _RankingFaturamentoTableHeader extends StatelessWidget {
  const _RankingFaturamentoTableHeader({
    required this.l10n,
    required this.currentSorts,
    required this.onSortChanged,
  });

  final AppLocalizations l10n;
  final List<AppReportSortDescriptor> currentSorts;
  final ValueChanged<List<AppReportSortDescriptor>> onSortChanged;

  void _toggleSort(String columnKey) {
    final current = currentSorts.isEmpty ? null : currentSorts.first;
    if (current?.columnKey != columnKey) {
      onSortChanged(<AppReportSortDescriptor>[
        AppReportSortDescriptor(
          columnKey: columnKey,
          direction: AppReportSortDirection.descending,
        ),
      ]);
      return;
    }
    if (current!.direction == AppReportSortDirection.descending) {
      onSortChanged(<AppReportSortDescriptor>[
        AppReportSortDescriptor(
          columnKey: columnKey,
          direction: AppReportSortDirection.ascending,
        ),
      ]);
      return;
    }
    onSortChanged(const <AppReportSortDescriptor>[]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final width = MediaQuery.sizeOf(context).width;
    final showPercent = width >= AppBreakpoints.reportColumnHideNarrow;
    final showRank = width >= AppBreakpoints.reportColumnHideExtraNarrow;

    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.gapSm),
      child: Row(
        children: <Widget>[
          if (showRank)
            SizedBox(
              width: _RankingFaturamentoTableLayout.posicao(tokens),
              child: Text(
                l10n.salesRankingProdutosFaturamentoGridColumnPosicao,
                style: labelStyle,
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: Text(
              l10n.salesRankingProdutosFaturamentoGridColumnProduto,
              style: labelStyle,
            ),
          ),
          SizedBox(
            width: _RankingFaturamentoTableLayout.venda(tokens),
            child: _SortableHeaderLabel(
              label: l10n.salesRankingProdutosFaturamentoGridColumnVenda,
              style: labelStyle,
              textAlign: TextAlign.end,
              columnKey: 'venda',
              currentSorts: currentSorts,
              onPressed: () => _toggleSort('venda'),
            ),
          ),
          if (showPercent)
            SizedBox(
              width: _RankingFaturamentoTableLayout.percentual(tokens),
              child: _SortableHeaderLabel(
                label: l10n.salesRankingProdutosFaturamentoGridColumnPercent,
                style: labelStyle,
                textAlign: TextAlign.end,
                columnKey: 'percent',
                currentSorts: currentSorts,
                onPressed: () => _toggleSort('percent'),
              ),
            ),
        ],
      ),
    );
  }
}

class _SortableHeaderLabel extends StatelessWidget {
  const _SortableHeaderLabel({
    required this.label,
    required this.style,
    required this.textAlign,
    required this.columnKey,
    required this.currentSorts,
    required this.onPressed,
  });

  final String label;
  final TextStyle? style;
  final TextAlign textAlign;
  final String columnKey;
  final List<AppReportSortDescriptor> currentSorts;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    AppReportSortDescriptor? activeSort;
    for (final sort in currentSorts) {
      if (sort.columnKey == columnKey) {
        activeSort = sort;
        break;
      }
    }
    final isActive = activeSort != null;
    final icon = !isActive
        ? Icons.unfold_more_rounded
        : activeSort.direction == AppReportSortDirection.ascending
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
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
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _RankingFaturamentoTableRow extends StatelessWidget {
  const _RankingFaturamentoTableRow({
    required this.row,
    required this.l10n,
  });

  final RankingProdutosFaturamentoRow row;
  final AppLocalizations l10n;

  static const List<FontFeature> _tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final width = MediaQuery.sizeOf(context).width;
    final showPercent = width >= AppBreakpoints.reportColumnHideNarrow;
    final showRank = width >= AppBreakpoints.reportColumnHideExtraNarrow;
    final percentFormat = NumberFormat('#,##0.0', l10n.localeName);

    final productLabel = row.isDiversos
        ? l10n.salesRankingProdutosFaturamentoDiversosLabel
        : row.nomeProduto.trim().toUpperCase();

    final rowBackground = row.isDiversos
        ? theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.65)
        : null;

    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.gapSm,
        vertical: tokens.gapXs,
      ),
      child: Row(
        children: <Widget>[
          if (showRank)
            SizedBox(
              width: _RankingFaturamentoTableLayout.posicao(tokens),
              child: Center(
                child: row.isDiversos
                    ? Text(
                        '–',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : SalesRankingProdutosFaturamentoRankBadge(
                        rank: row.posicao ?? 0,
                      ),
              ),
            ),
          Expanded(
            child: Text(
              productLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.25,
                color: row.isDiversos
                    ? theme.colorScheme.onSurfaceVariant
                    : null,
              ),
            ),
          ),
          SizedBox(
            width: _RankingFaturamentoTableLayout.venda(tokens),
            child: Text(
              AppBrFormatters.currency(row.valorVenda),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFeatures: _tabularFigures,
                fontWeight: row.isDiversos ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          if (showPercent)
            SizedBox(
              width: _RankingFaturamentoTableLayout.percentual(tokens),
              child: Text(
                '${percentFormat.format(row.percentual)}%',
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFeatures: _tabularFigures,
                  color: theme.appColors.tertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: kSalesRankingFaturamentoGridDataRowHeight,
      ),
      child: rowBackground == null
          ? content
          : DecoratedBox(
              decoration: BoxDecoration(color: rowBackground),
              child: content,
            ),
    );
  }
}
