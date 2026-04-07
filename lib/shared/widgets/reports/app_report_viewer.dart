import 'dart:async';

import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/l10n/app_localizations.dart';
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
import 'package:colmeia/shared/widgets/reports/app_report_inline_filters_bar.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_pagination_bar.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';
import 'package:colmeia/shared/widgets/reports/app_report_style.dart';
import 'package:colmeia/shared/widgets/reports/app_report_summary_bar.dart';
import 'package:colmeia/shared/widgets/reports/app_report_toolbar.dart';
import 'package:flutter/foundation.dart';
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
    this.headerActions = const <Widget>[],
    this.filters,
    this.filterValues,
    this.selectedRows,
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

  /// Small actions rendered with the title row (e.g. JSON/CSV).
  final List<Widget> headerActions;

  /// Filter descriptors. When null the filters panel is not rendered.
  final List<AppReportFilterDescriptor>? filters;

  /// Current filter values applied by the consumer.
  final Map<String, Object?>? filterValues;

  /// Currently selected rows, used by toolbar actions such as export selection.
  final List<T>? selectedRows;

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
  late List<AppReportGroupDescriptor> _groups;
  late final AppReportGroupController _groupController;

  @override
  void initState() {
    super.initState();
    _groupController = AppReportGroupController();
    _initFromQuery();
  }

  @override
  void didUpdateWidget(covariant AppReportViewer<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query && widget.query != null) {
      _applyExternalQuery(widget.query!);
    }
    if (oldWidget.columns != widget.columns) {
      _syncVisibleColumnKeysWithColumns();
    }
  }

  void _initFromQuery() {
    final query = widget.query;
    _density = query?.density ?? widget.style.density;
    _sorts = query?.sorts ?? <AppReportSortDescriptor>[];
    _groups = query?.groups ?? <AppReportGroupDescriptor>[];
    _visibleColumnKeys = query?.visibleColumnKeys ?? _defaultVisibleKeys();
  }

  void _applyExternalQuery(AppReportQuery query) {
    setState(() {
      _density = query.density;
      _sorts = query.sorts;
      _groups = query.groups;
      if (query.visibleColumnKeys != null) {
        _visibleColumnKeys = Set<String>.from(query.visibleColumnKeys!);
      }
    });
  }

  void _syncVisibleColumnKeysWithColumns() {
    setState(() {
      final validKeys = widget.columns.map((column) => column.key).toSet();
      final syncedKeys = _visibleColumnKeys.intersection(validKeys);
      _groups = _groups
          .where((group) => validKeys.contains(group.columnKey))
          .toList(growable: false);
      _visibleColumnKeys = syncedKeys.isNotEmpty
          ? syncedKeys
          : _defaultVisibleKeys();
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

  int get _activeFilterCount {
    final values = widget.filterValues ??
        widget.query?.filters ??
        const <String, Object?>{};
    return widget.filters
            ?.where((filter) => filter.hasActiveValue(values))
            .length ??
        0;
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
    final visibleGroups = _groups
        .where((group) => keys.contains(group.columnKey))
        .toList(growable: false);
    final groupsChanged = !listEquals(visibleGroups, _groups);
    setState(() {
      _visibleColumnKeys = keys;
      _groups = visibleGroups;
    });
    widget.events.onColumnVisibilityChanged?.call(keys);
    if (groupsChanged) {
      widget.events.onGroupChanged?.call(visibleGroups);
    }
    _emitQueryChanged(
      visibleColumnKeys: keys,
      groups: visibleGroups,
      page: groupsChanged ? 1 : null,
    );
  }

  void _onGroupChanged(List<AppReportGroupDescriptor> groups) {
    setState(() => _groups = groups);
    widget.events.onGroupChanged?.call(groups);
    _emitQueryChanged(groups: groups, page: 1);
  }

  void _onGroupStateChanged(List<AppReportGroupDescriptor> groups) {
    setState(() => _groups = groups);
    widget.events.onGroupStateChanged?.call(groups);
  }

  void _onGroupToggle(AppReportGroupToggleEvent event) {
    if (event.groupLevel < 0 || event.groupLevel >= _groups.length) {
      return;
    }

    final updatedGroups = List<AppReportGroupDescriptor>.from(_groups);
    updatedGroups[event.groupLevel] = updatedGroups[event.groupLevel].copyWith(
      expanded: event.isExpanded,
    );
    _onGroupStateChanged(updatedGroups);
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
    List<AppReportGroupDescriptor>? groups,
    AppReportDensity? density,
    Set<String>? visibleColumnKeys,
    Map<String, Object?>? filters,
    int? page,
    int? pageSize,
    String? searchTerm,
  }) {
    final current = widget.query ?? const AppReportQuery();
    final normalizedSearchTerm = searchTerm?.trim();
    final updated = current.copyWith(
      sorts: sorts ?? _sorts,
      groups: groups ?? _groups,
      density: density ?? _density,
      visibleColumnKeys: visibleColumnKeys ?? _visibleColumnKeys,
      filters: filters ?? current.filters,
      page: page ?? current.page,
      pageSize: pageSize ?? current.pageSize,
      searchTerm: normalizedSearchTerm,
      clearSearchTerm:
          normalizedSearchTerm != null && normalizedSearchTerm.isEmpty,
    );
    widget.events.onQueryChanged?.call(updated);
  }

  bool _supportsInlineFilter(AppReportFilterType type) => switch (type) {
    AppReportFilterType.text => true,
    AppReportFilterType.search => true,
    AppReportFilterType.singleSelect => true,
    AppReportFilterType.date => true,
    AppReportFilterType.dateRange => true,
    _ => false,
  };

  Future<void> _showAdvancedFiltersSheet() async {
    final filters = widget.filters;
    if (filters == null || filters.isEmpty || !mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final tokens = Theme.of(context).extension<AppThemeTokens>()!;
        final l10n = AppLocalizations.of(context);
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.contentSpacing,
            tokens.gapMd,
            tokens.contentSpacing,
            tokens.contentSpacing + bottomInset,
          ),
          child: SingleChildScrollView(
            child: AppReportFiltersPanel(
              title: widget.title != null
                  ? l10n.reportFiltersTitleWithContext(widget.title!)
                  : l10n.reportFiltersTitle,
              filters: filters,
              initialValues:
                  widget.filterValues ??
                  widget.query?.filters ??
                  <String, Object?>{},
              onApply: (values) {
                widget.events.onFiltersApplied?.call(values);
                Navigator.of(context).pop();
                _emitQueryChanged(filters: values, page: 1);
              },
              onClear: () {
                widget.events.onFilterCleared?.call();
                Navigator.of(context).pop();
                _emitQueryChanged(
                  filters: const <String, Object?>{},
                  page: 1,
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final style = widget.style;
    final groupableColumns = widget.columns
        .where(
          (column) =>
              column.groupable && _visibleColumnKeys.contains(column.key),
        )
        .toList(growable: false);

    final showHeader =
        widget.title != null ||
        widget.subtitle != null ||
        widget.headerTrailing != null ||
        (widget.contextChips?.isNotEmpty ?? false);
    final showFilters =
        style.showFiltersPanel && (widget.filters?.isNotEmpty ?? false);
    final showInlineFilters =
        showFilters && style.filterLayout == AppReportFilterLayout.inline;
    final showPanelFilters =
        showFilters && style.filterLayout == AppReportFilterLayout.panel;
    final showSummary =
        style.showSummaryBar && (widget.summaryItems?.isNotEmpty ?? false);
    final showPagination = style.showPagination && widget.pageInfo != null;
    final showAdvancedInlineFilters =
        showInlineFilters &&
        (widget.filters?.any((f) => !_supportsInlineFilter(f.type)) ?? false);
    final isMinimal = style.variant == AppReportViewerVariant.minimal;
    final reportCardColor = isMinimal
        ? theme.colorScheme.surface
        : theme.colorScheme.surfaceContainerLow;
    final reportCardBorder = BorderSide(
      color: theme.colorScheme.outlineVariant.withValues(
        alpha: isMinimal ? 0.28 : 0.4,
      ),
    );
    final reportCardPadding = EdgeInsets.all(
      isMinimal ? tokens.gapMd : tokens.contentSpacing,
    );

    final body = ListView(
      padding: context.pageScrollPadding(tokens),
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
            actions: widget.headerActions,
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
        if (showPanelFilters) ...<Widget>[
          AppSkeleton(
            enabled: widget.isLoading,
            loadingSemanticsLabel: 'Carregando filtros...',
            child: AppReportFiltersPanel(
              filters: widget.filters!,
              initialValues:
                  widget.filterValues ??
                  widget.query?.filters ??
                  <String, Object?>{},
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
            color: reportCardColor,
            borderSide: reportCardBorder,
            padding: reportCardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (showInlineFilters) ...<Widget>[
                  AppReportInlineFiltersBar(
                    filters: widget.filters!,
                    initialValues:
                        widget.filterValues ??
                        widget.query?.filters ??
                        <String, Object?>{},
                    isLoading: widget.isLoading,
                    debounceDuration: style.searchDebounce,
                    showAdvancedFiltersButton: showAdvancedInlineFilters,
                    onOpenAdvancedFilters: _showAdvancedFiltersSheet,
                    onFiltersChanged: (values) {
                      widget.events.onFiltersApplied?.call(values);
                      _emitQueryChanged(filters: values, page: 1);
                    },
                  ),
                  SizedBox(height: tokens.gapMd),
                ],
                AppReportToolbar<T>(
                  style: style,
                  events: AppReportEvents<T>(
                    onSearchChanged: (term) {
                      widget.events.onSearchChanged?.call(term);
                      _emitQueryChanged(searchTerm: term, page: 1);
                    },
                    onDensityChanged: _onDensityChanged,
                    onGroupChanged: _onGroupChanged,
                    onGroupStateChanged: _onGroupStateChanged,
                    onColumnVisibilityChanged: _onColumnVisibilityChanged,
                    onExportRequested: widget.events.onExportRequested,
                    onPrintRequested: widget.events.onPrintRequested,
                    onRefresh: widget.events.onRefresh,
                  ),
                  columns: widget.columns,
                  groupableColumns: groupableColumns,
                  visibleColumnKeys: _visibleColumnKeys,
                  currentDensity: _density,
                  currentGroups: _groups,
                  isLoading: widget.isLoading,
                  groupController: _groupController,
                  searchTerm: widget.query?.searchTerm,
                  selectedRowCount: widget.selectedRows?.length ?? 0,
                  onOpenFiltersSheet:
                      style.filterLayout == AppReportFilterLayout.sheet &&
                          showFilters
                      ? _showAdvancedFiltersSheet
                      : null,
                  activeFilterCount: _activeFilterCount,
                  onClearSelection: widget.events.onRowSelection != null
                      ? () =>
                            widget.events.onRowSelection?.call(List<T>.empty())
                      : null,
                ),
                AppReportGrid<T>(
                  columns: _visibleColumns,
                  rows: widget.rows,
                  currentGroups: _groups,
                  selectedRows: widget.selectedRows ?? List<T>.empty(),
                  groupController: _groupController,
                  style: style.copyWith(density: _density),
                  isLoading: widget.isLoading,
                  events: AppReportEvents<T>(
                    onSortChanged: _onSortChanged,
                    onRowTap: _onRowTap,
                    onRowDoubleTap: widget.events.onRowDoubleTap,
                    onRowLongPress: widget.events.onRowLongPress,
                    onRowSelection: widget.events.onRowSelection,
                    onGroupExpanded: (event) {
                      _onGroupToggle(event);
                      widget.events.onGroupExpanded?.call(event);
                    },
                    onGroupCollapsed: (event) {
                      _onGroupToggle(event);
                      widget.events.onGroupCollapsed?.call(event);
                    },
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
              color: reportCardColor,
              borderSide: reportCardBorder,
              child: AppReportPaginationBar(
                pageInfo: widget.pageInfo!,
                onPageChanged: (page) {
                  widget.events.onPageChanged?.call(page);
                  _emitQueryChanged(page: page);
                },
                onPageSizeChanged: (size) {
                  widget.events.onPageSizeChanged?.call(size);
                  _emitQueryChanged(page: 1, pageSize: size);
                },
                availablePageSizes: style.resolvedPageSizes,
                isLoading: widget.isLoading,
                entityLabel: style.entityLabel,
                itemsPerPageLabel: style.itemsPerPageLabel,
                showingLabelPrefix: style.showingLabelPrefix,
                showingLabelMiddle: style.showingLabelMiddle,
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
