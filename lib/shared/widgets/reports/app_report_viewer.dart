import 'dart:async';

import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_detail_panel.dart';
import 'package:colmeia/shared/widgets/reports/app_report_events.dart';
import 'package:colmeia/shared/widgets/reports/app_report_filters_panel.dart';
import 'package:colmeia/shared/widgets/reports/app_report_grid.dart';
import 'package:colmeia/shared/widgets/reports/app_report_header.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_pagination_bar.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';
import 'package:colmeia/shared/widgets/reports/app_report_style.dart';
import 'package:colmeia/shared/widgets/reports/app_report_summary_bar.dart';
import 'package:colmeia/shared/widgets/reports/app_report_toolbar.dart';
import 'package:flutter/material.dart';

/// Generic, interactive ERP-style report viewer.
///
/// Usage:
/// ```dart
/// AppReportViewer<SalesRow>(
///   title: 'Vendas por loja',
///   columns: SalesReport.columns,
///   rows: controller.rows,
///   pageInfo: controller.pageInfo,
///   summaryItems: controller.summaries,
///   filters: SalesReport.filters,
///   filterValues: controller.currentFilters,
///   style: const AppReportViewerStyle(
///     showExportActions: true,
///     showColumnChooser: true,
///   ),
///   events: AppReportEvents<SalesRow>(
///     onQueryChanged: controller.onQueryChanged,
///     onExportRequested: controller.onExportRequested,
///   ),
///   isLoading: controller.isLoading,
///   errorMessage: controller.errorMessage,
///   onRetry: controller.reload,
/// )
/// ```
class AppReportViewer<T> extends StatefulWidget {
  const AppReportViewer({
    required this.columns,
    required this.rows,
    super.key,
    this.title,
    this.subtitle,
    this.contextChips,
    this.headerTrailing,
    this.filters,
    this.filterValues,
    this.summaryItems,
    this.pageInfo,
    this.query,
    this.events = const AppReportEvents(),
    this.style = const AppReportViewerStyle(),
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.emptyMessage,
  });

  /// Column definitions. Required -- defines schema and behaviour.
  final List<AppReportColumn<T>> columns;

  /// Current page of data rows. Required.
  final List<T> rows;

  final String? title;
  final String? subtitle;

  /// Short chips shown in the header (store name, date, etc.).
  final List<String>? contextChips;

  /// Widget placed in the trailing position of the header row (e.g. a link).
  final Widget? headerTrailing;

  /// Filter descriptors. When null the filters panel is not rendered.
  final List<AppReportFilterDescriptor>? filters;

  /// Current filter values applied by the consumer.
  final Map<String, Object?>? filterValues;

  /// KPI tiles shown in the summary bar.
  final List<AppReportSummaryItem>? summaryItems;

  /// Pagination info. When null the pagination bar is hidden.
  final AppReportPageInfo? pageInfo;

  /// External query state. When provided the viewer reads initial visible
  /// columns, density and sort from this object.
  final AppReportQuery? query;

  final AppReportEvents<T> events;
  final AppReportViewerStyle style;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String? emptyMessage;

  @override
  State<AppReportViewer<T>> createState() => _AppReportViewerState<T>();
}

class _AppReportViewerState<T> extends State<AppReportViewer<T>> {
  late Set<String> _visibleColumnKeys;
  late AppReportDensity _density;
  late List<AppReportSortDescriptor> _sorts;

  @override
  void initState() {
    super.initState();
    _initFromQuery();
  }

  @override
  void didUpdateWidget(covariant AppReportViewer<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query && widget.query != null) {
      _applyExternalQuery(widget.query!);
    }
    if (oldWidget.columns != widget.columns) {
      _refreshDefaultVisibleKeys();
    }
  }

  void _initFromQuery() {
    final query = widget.query;
    _density = query?.density ?? widget.style.density;
    _sorts = query?.sorts ?? <AppReportSortDescriptor>[];
    _visibleColumnKeys = query?.visibleColumnKeys ?? _defaultVisibleKeys();
  }

  void _applyExternalQuery(AppReportQuery query) {
    setState(() {
      _density = query.density;
      _sorts = query.sorts;
      if (query.visibleColumnKeys != null) {
        _visibleColumnKeys = Set<String>.from(query.visibleColumnKeys!);
      }
    });
  }

  void _refreshDefaultVisibleKeys() {
    setState(() {
      _visibleColumnKeys = _defaultVisibleKeys();
    });
  }

  Set<String> _defaultVisibleKeys() {
    return widget.columns
        .where((c) => c.visibleByDefault)
        .map((c) => c.key)
        .toSet();
  }

  List<AppReportColumn<T>> get _visibleColumns {
    return widget.columns
        .where((c) => _visibleColumnKeys.contains(c.key))
        .toList(growable: false);
  }

  void _onSortChanged(List<AppReportSortDescriptor> sorts) {
    setState(() => _sorts = sorts);
    widget.events.onSortChanged?.call(sorts);
    _emitQueryChanged(sorts: sorts);
  }

  void _onDensityChanged(AppReportDensity density) {
    setState(() => _density = density);
    widget.events.onDensityChanged?.call(density);
    _emitQueryChanged(density: density);
  }

  void _onColumnVisibilityChanged(Set<String> keys) {
    setState(() => _visibleColumnKeys = keys);
    widget.events.onColumnVisibilityChanged?.call(keys);
    _emitQueryChanged(visibleColumnKeys: keys);
  }

  void _onRowTap(T row, int index) {
    widget.events.onRowTap?.call(row, index);
    if (widget.style.showRowDetailOnTap && mounted) {
      unawaited(
        showAppReportDetailPanel<T>(
          context: context,
          row: row,
          columns: _visibleColumns,
          title: widget.title ?? 'Detalhes',
        ),
      );
    }
  }

  void _emitQueryChanged({
    List<AppReportSortDescriptor>? sorts,
    AppReportDensity? density,
    Set<String>? visibleColumnKeys,
    Map<String, Object?>? filters,
    int? page,
    String? searchTerm,
  }) {
    final current = widget.query ?? const AppReportQuery();
    final updated = current.copyWith(
      sorts: sorts ?? _sorts,
      density: density ?? _density,
      visibleColumnKeys: visibleColumnKeys ?? _visibleColumnKeys,
      filters: filters ?? current.filters,
      page: page ?? current.page,
      searchTerm: searchTerm ?? current.searchTerm,
    );
    widget.events.onQueryChanged?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final style = widget.style;

    final showHeader =
        widget.title != null ||
        (widget.contextChips?.isNotEmpty ?? false);
    final showFilters =
        style.showFiltersPanel && (widget.filters?.isNotEmpty ?? false);
    final showSummary =
        style.showSummaryBar && (widget.summaryItems?.isNotEmpty ?? false);
    final showPagination =
        style.showPagination && widget.pageInfo != null;

    final body = ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      physics: style.enablePullToRefresh
          ? const AlwaysScrollableScrollPhysics()
          : null,
      children: <Widget>[
        if (showHeader) ...<Widget>[
          AppReportHeader(
            title: widget.title ?? '',
            subtitle: widget.subtitle,
            contextChips: widget.contextChips ?? <String>[],
            trailing: widget.headerTrailing,
          ),
          SizedBox(height: tokens.sectionSpacing),
        ],
        if (widget.errorMessage != null) ...<Widget>[
          AppInlineErrorPanel(
            title: 'Não foi possível carregar os dados',
            message: widget.errorMessage!,
            onRetry: widget.onRetry,
          ),
          SizedBox(height: tokens.sectionSpacing),
        ],
        if (showFilters) ...<Widget>[
          AppSkeleton(
            enabled: widget.isLoading,
            loadingSemanticsLabel: 'Carregando filtros...',
            child: AppReportFiltersPanel(
              filters: widget.filters!,
              initialValues: widget.filterValues ?? <String, Object?>{},
              onApply: (values) {
                widget.events.onFiltersApplied?.call(values);
                _emitQueryChanged(filters: values, page: 1);
              },
              onClear: () {
                widget.events.onFilterCleared?.call();
                _emitQueryChanged(
                  filters: const <String, Object?>{},
                  page: 1,
                );
              },
              startExpanded: style.filtersStartExpanded,
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
        ],
        if (showSummary) ...<Widget>[
          AppSkeleton(
            enabled: widget.isLoading,
            loadingSemanticsLabel: 'Carregando resumo...',
            child: AppReportSummaryBar(items: widget.summaryItems!),
          ),
          SizedBox(height: tokens.sectionSpacing),
        ],
        AppSkeleton(
          enabled: widget.isLoading,
          loadingSemanticsLabel: 'Carregando tabela...',
          child: AppSectionCard(
            padding: EdgeInsets.all(tokens.contentSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppReportToolbar<T>(
                  style: style,
                  events: AppReportEvents<T>(
                    onSearchChanged: (term) {
                      widget.events.onSearchChanged?.call(term);
                      _emitQueryChanged(searchTerm: term);
                    },
                    onDensityChanged: _onDensityChanged,
                    onColumnVisibilityChanged: _onColumnVisibilityChanged,
                    onExportRequested: widget.events.onExportRequested,
                    onPrintRequested: widget.events.onPrintRequested,
                    onRefresh: widget.events.onRefresh,
                  ),
                  columns: widget.columns,
                  visibleColumnKeys: _visibleColumnKeys,
                  currentDensity: _density,
                  isLoading: widget.isLoading,
                ),
                AppReportGrid<T>(
                  columns: _visibleColumns,
                  rows: widget.rows,
                  style: style.copyWith(density: _density),
                  events: AppReportEvents<T>(
                    onSortChanged: _onSortChanged,
                    onRowTap: _onRowTap,
                    onRowDoubleTap: widget.events.onRowDoubleTap,
                    onRowLongPress: widget.events.onRowLongPress,
                    onRowSelection: widget.events.onRowSelection,
                  ),
                  currentSorts: _sorts,
                  emptyMessage: widget.emptyMessage,
                ),
              ],
            ),
          ),
        ),
        if (showPagination) ...<Widget>[
          SizedBox(height: tokens.sectionSpacing),
          AppSkeleton(
            enabled: widget.isLoading,
            loadingSemanticsLabel: 'Carregando paginação...',
            child: AppSectionCard(
              child: AppReportPaginationBar(
                pageInfo: widget.pageInfo!,
                onPageChanged: (page) {
                  widget.events.onPageChanged?.call(page);
                  _emitQueryChanged(page: page);
                },
                onPageSizeChanged: (size) {
                  widget.events.onPageSizeChanged?.call(size);
                  _emitQueryChanged(page: 1);
                },
                availablePageSizes: style.resolvedPageSizes,
                isLoading: widget.isLoading,
              ),
            ),
          ),
        ],
      ],
    );

    if (style.enablePullToRefresh && widget.events.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: () => widget.events.onRefresh!(),
        child: body,
      );
    }

    return body;
  }
}
