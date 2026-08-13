import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_error_panel_factory.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_columns.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_sort.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_events.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';
import 'package:colmeia/shared/widgets/reports/app_report_style.dart';
import 'package:colmeia/shared/widgets/reports/app_report_viewer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const double kSalesMargemProdutoDataRowHeight = 56;
const double kSalesMargemProdutoHeaderRowHeight = 40;
const double kSalesMargemProdutoGridMinHeight = 240;
const double kSalesMargemProdutoPageChromeHeight = 176;
const double kSalesMargemProdutoPageGridMaxHeight = 720;
const double kSalesMargemProdutoFullscreenChromeHeight = 168;

/// Fits the catalog grid into [maxHeight] after reserving viewer chrome.
///
/// Never throws when [maxHeight] is below [minHeight] (short landscape
/// viewports). Prefer shrinking the grid over overflowing the parent.
double resolveSalesMargemProdutoGridHeight({
  required double maxHeight,
  required double chromeHeight,
  double minHeight = kSalesMargemProdutoGridMinHeight,
  double? maxGridHeight,
}) {
  if (!maxHeight.isFinite || maxHeight <= 0) {
    return minHeight;
  }
  final upper = maxGridHeight == null
      ? maxHeight
      : maxGridHeight.clamp(0.0, maxHeight);
  final remaining = maxHeight - chromeHeight;
  if (remaining >= minHeight && minHeight <= upper) {
    return remaining.clamp(minHeight, upper);
  }
  return remaining.clamp(0.0, upper);
}

@immutable
class SalesMargemProdutoGridSnapshot {
  const SalesMargemProdutoGridSnapshot({
    required this.rows,
    required this.pageInfo,
    required this.query,
    required this.isLoading,
    this.loadFailure,
  });

  factory SalesMargemProdutoGridSnapshot.initial() {
    return SalesMargemProdutoGridSnapshot(
      rows: const <MargemProdutoRow>[],
      pageInfo: SalesMargemProdutoSort.pageInfo(
        page: 1,
        pageSize: SalesMargemProdutoSort.defaultPageSize,
        totalCount: 0,
      ),
      query: SalesMargemProdutoSort.queryFor(
        sortBy: SalesMargemProdutoSort.defaultSortBy,
        sortDirection: SalesMargemProdutoSort.defaultSortDirection,
        page: 1,
        pageSize: SalesMargemProdutoSort.defaultPageSize,
      ),
      isLoading: false,
    );
  }

  final List<MargemProdutoRow> rows;
  final AppReportPageInfo pageInfo;
  final AppReportQuery query;
  final bool isLoading;
  final AppFailure? loadFailure;

  @override
  bool operator ==(Object other) {
    return other is SalesMargemProdutoGridSnapshot &&
        identical(rows, other.rows) &&
        pageInfo.currentPage == other.pageInfo.currentPage &&
        pageInfo.pageSize == other.pageInfo.pageSize &&
        pageInfo.totalRows == other.pageInfo.totalRows &&
        pageInfo.totalPages == other.pageInfo.totalPages &&
        query.page == other.query.page &&
        query.pageSize == other.query.pageSize &&
        listEquals(query.sorts, other.query.sorts) &&
        isLoading == other.isLoading &&
        identical(loadFailure, other.loadFailure);
  }

  @override
  int get hashCode => Object.hash(
    identityHashCode(rows),
    pageInfo.currentPage,
    pageInfo.pageSize,
    pageInfo.totalRows,
    pageInfo.totalPages,
    query.page,
    query.pageSize,
    Object.hashAll(query.sorts),
    isLoading,
    identityHashCode(loadFailure),
  );
}

class SalesMargemProdutoFullscreen extends StatefulWidget {
  const SalesMargemProdutoFullscreen({
    required this.snapshot,
    required this.onQueryChanged,
    required this.onRefresh,
    this.agentId,
    this.retryCountdownLabel,
    super.key,
  });

  final SalesMargemProdutoGridSnapshot snapshot;
  final ValueChanged<AppReportQuery> onQueryChanged;
  final Future<void> Function() onRefresh;
  final String? agentId;
  final String? retryCountdownLabel;

  @override
  State<SalesMargemProdutoFullscreen> createState() =>
      _SalesMargemProdutoFullscreenState();
}

class _SalesMargemProdutoFullscreenState
    extends State<SalesMargemProdutoFullscreen> {
  // Stable identity across rebuilds; required for AppReportGrid column-cache hits.
  late List<AppReportColumn<MargemProdutoRow>> _columns;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _columns = buildSalesMargemProdutoColumns(
      labels: SalesMargemProdutoColumnLabels.fromL10n(
        AppLocalizations.of(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loadFailure = widget.snapshot.loadFailure;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridHeight = resolveSalesMargemProdutoGridHeight(
          maxHeight: constraints.maxHeight,
          chromeHeight: kSalesMargemProdutoFullscreenChromeHeight,
        );
        return AppReportViewer<MargemProdutoRow>(
          columns: _columns,
          rows: widget.snapshot.rows,
          pageInfo: widget.snapshot.pageInfo,
          query: widget.snapshot.query,
          events: AppReportEvents<MargemProdutoRow>(
            onQueryChanged: widget.onQueryChanged,
            onRefresh: widget.onRefresh,
          ),
          style:
              AppReportViewerStyle.numericalDetailing(
                entityLabel: l10n.salesMargemProdutoEntityLabel,
                gridHeight: gridHeight,
                frozenColumnsCount: 0,
                dataRowHeight: kSalesMargemProdutoDataRowHeight,
              ).copyWith(
                trustServerRowOrder: true,
                showRefreshAction: true,
                enablePullToRefresh: false,
                availablePageSizes: SalesMargemProdutoSort.allowedPageSizes,
                headerRowHeight: kSalesMargemProdutoHeaderRowHeight,
              ),
          isLoading: widget.snapshot.isLoading,
          loadErrorPanel: loadFailure == null
              ? null
              : AgentQueryErrorPanelFactory.fromFailure(
                  loadFailure,
                  l10n,
                  onRetry: () => unawaited(widget.onRefresh()),
                  retryCountdownLabel: widget.retryCountdownLabel,
                  supportContext: AgentQueryFailureSupportContext.environment(
                    extra: <String, String>{
                      'agentId': ?widget.agentId,
                      'screen': 'sales_margem_produto',
                    },
                  ),
                ),
          onRetry: () => unawaited(widget.onRefresh()),
          emptyMessage: l10n.salesMargemProdutoEmpty,
        );
      },
    );
  }
}
