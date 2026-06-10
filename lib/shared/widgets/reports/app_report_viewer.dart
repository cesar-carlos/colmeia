import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_load_error_surface.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
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
///   loadFailure: controller.loadFailure,
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
    this.loadFailure,
    this.errorMessage,
    this.onRetry,
    this.retryCountdownLabel,
    this.supportContext,
    this.emptyMessage,
    this.searchHintText,
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
  final AppFailure? loadFailure;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String? retryCountdownLabel;
  final AgentQueryFailureSupportContext? supportContext;
  final String? emptyMessage;

  /// Optional override for the toolbar search field hint. When null a generic
  /// localized hint is used.
  final String? searchHintText;

  @override
  State<AppReportViewer<T>> createState() => _AppReportViewerState<T>();
}

class _AppReportViewerState<T> extends State<AppReportViewer<T>> {
  late Set<String> _visibleColumnKeys;
  late AppReportDensity _density;
  late List<AppReportSortDescriptor> _sorts;
  late List<AppReportGroupDescriptor> _groups;
  late final AppReportGroupController _groupController;

  bool get _hasLoadError => AgentQueryLoadErrorSurface.hasErrorFor(
    loadFailure: widget.loadFailure,
    errorMessage: widget.errorMessage,
  );

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
    final values =
        widget.filterValues ??
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
          title:
              widget.title ??
              AppLocalizations.of(context).reportRowDetailDefaultTitle,
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

  /// Builds a "Limpar filtros" CTA shown inside the empty-state placeholder
  /// when the user has active filters but the resulting page has no rows.
  /// Returns null when there are no active filters (i.e. the empty state is
  /// genuine, not filter-driven).
  Widget? _buildEmptyClearFiltersAction() {
    if (widget.isLoading || _activeFilterCount == 0) {
      return null;
    }
    final hasFiltersUi =
        widget.style.showFiltersPanel && (widget.filters?.isNotEmpty ?? false);
    if (!hasFiltersUi) {
      return null;
    }
    return _ReportEmptyClearFiltersAction(
      onPressed: () {
        widget.events.onFilterCleared?.call();
        _emitQueryChanged(
          filters: const <String, Object?>{},
          page: 1,
        );
      },
    );
  }

  Future<void> _showAdvancedFiltersSheet() async {
    final filters = widget.filters;
    if (filters == null || filters.isEmpty || !mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
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
    final l10n = AppLocalizations.of(context);
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
        (widget.filters?.any((f) => !f.type.supportsInlineLayout) ?? false);
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
        if (_hasLoadError) ...<Widget>[
          AgentQueryLoadErrorSurface(
            loadFailure: widget.loadFailure,
            errorMessage: widget.errorMessage,
            onRetry: widget.onRetry,
            retryCountdownLabel: widget.retryCountdownLabel,
            supportContext: widget.supportContext,
            legacyTitle: l10n.reportLoadErrorTitle,
          ),
          SizedBox(height: tokens.sectionSpacing),
        ],
        if (showPanelFilters) ...<Widget>[
          AppSkeleton(
            enabled: widget.isLoading,
            loadingSemanticsLabel: l10n.reportLoadingFiltersSemantics,
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
            loadingSemanticsLabel: l10n.reportLoadingSummarySemantics,
            child: AppReportSummaryBar(items: widget.summaryItems!),
          ),
          SizedBox(height: tokens.sectionSpacing),
        ],
        AppSkeleton(
          enabled: widget.isLoading,
          loadingSemanticsLabel: l10n.reportLoadingTableSemantics,
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
                  searchHintText: widget.searchHintText,
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
                  emptyAction: _buildEmptyClearFiltersAction(),
                ),
              ],
            ),
          ),
        ),
        if (showPagination) ...<Widget>[
          SizedBox(height: tokens.sectionSpacing),
          _ReportViewerPaginationSection(
            pageInfo: widget.pageInfo!,
            style: style,
            isLoading: widget.isLoading,
            cardColor: reportCardColor,
            cardBorder: reportCardBorder,
            horizontalPadding: isMinimal ? tokens.gapMd : tokens.contentSpacing,
            onPageChanged: (page) {
              widget.events.onPageChanged?.call(page);
              _emitQueryChanged(page: page);
            },
            onPageSizeChanged: (size) {
              widget.events.onPageSizeChanged?.call(size);
              _emitQueryChanged(page: 1, pageSize: size);
            },
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

/// "Limpar filtros" CTA shown inside the grid empty state when the current
/// filters produced no rows.
class _ReportEmptyClearFiltersAction extends StatelessWidget {
  const _ReportEmptyClearFiltersAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
      label: Text(AppLocalizations.of(context).reportEmptyClearFiltersAction),
      onPressed: onPressed,
    );
  }
}

/// Pagination footer section: skeleton + card chrome around
/// [AppReportPaginationBar].
class _ReportViewerPaginationSection extends StatelessWidget {
  const _ReportViewerPaginationSection({
    required this.pageInfo,
    required this.style,
    required this.isLoading,
    required this.cardColor,
    required this.cardBorder,
    required this.horizontalPadding,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final AppReportPageInfo pageInfo;
  final AppReportViewerStyle style;
  final bool isLoading;
  final Color cardColor;
  final BorderSide cardBorder;
  final double horizontalPadding;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      enabled: isLoading,
      loadingSemanticsLabel: AppLocalizations.of(
        context,
      ).reportLoadingPaginationSemantics,
      child: AppSectionCard(
        color: cardColor,
        borderSide: cardBorder,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: AppReportPaginationBar(
          pageInfo: pageInfo,
          onPageChanged: onPageChanged,
          onPageSizeChanged: onPageSizeChanged,
          availablePageSizes: style.resolvedPageSizes,
          isLoading: isLoading,
          entityLabel: style.entityLabel,
          itemsPerPageLabel: style.itemsPerPageLabel,
          showingLabelPrefix: style.showingLabelPrefix,
          showingLabelMiddle: style.showingLabelMiddle,
        ),
      ),
    );
  }
}
