import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column_chooser.dart';
import 'package:colmeia/shared/widgets/reports/app_report_events.dart';
import 'package:colmeia/shared/widgets/reports/app_report_grid.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_style.dart';
import 'package:flutter/material.dart';

/// Action bar rendered above the grid.
///
/// Features are gated by booleans in [AppReportViewerStyle]:
/// - search bar
/// - density toggle
/// - column chooser
/// - export (PDF/Excel) dropdown
/// - print
/// - refresh
class AppReportToolbar<T> extends StatefulWidget {
  const AppReportToolbar({
    required this.style,
    required this.columns,
    required this.groupableColumns,
    required this.visibleColumnKeys,
    required this.currentDensity,
    super.key,
    this.events = const AppReportEvents(),
    this.searchTerm,
    this.currentGroups = const <AppReportGroupDescriptor>[],
    this.selectedRowCount = 0,
    this.isLoading = false,
    this.groupController,
    this.onClearSelection,
  });

  final AppReportViewerStyle style;
  final AppReportEvents<T> events;
  final List<AppReportColumn<T>> columns;
  final List<AppReportColumn<T>> groupableColumns;
  final Set<String> visibleColumnKeys;
  final AppReportDensity currentDensity;
  final String? searchTerm;
  final List<AppReportGroupDescriptor> currentGroups;
  final int selectedRowCount;
  final bool isLoading;
  final AppReportGroupController? groupController;
  final VoidCallback? onClearSelection;

  @override
  State<AppReportToolbar<T>> createState() => _AppReportToolbarState<T>();
}

class _AppReportToolbarState<T> extends State<AppReportToolbar<T>> {
  late final TextEditingController _searchController;

  void _onSearchControllerUpdated() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.searchTerm ?? '',
    );
    _searchController.addListener(_onSearchControllerUpdated);
  }

  @override
  void didUpdateWidget(covariant AppReportToolbar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchTerm != widget.searchTerm &&
        widget.searchTerm != _searchController.text) {
      _searchController.text = widget.searchTerm ?? '';
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchControllerUpdated)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final style = widget.style;
    final activeGroups = widget.currentGroups;
    final groupLabels = <String, String>{
      for (final column in widget.groupableColumns) column.key: column.label,
    };
    final canChooseColumns = style.showColumnChooser && !widget.isLoading;
    final canGroup =
        style.showGroupingChooser &&
        widget.groupableColumns.isNotEmpty &&
        !widget.isLoading;
    final canExport =
        style.showExportActions &&
        widget.events.onExportRequested != null &&
        !widget.isLoading;
    final canPrint =
        style.showPrintAction &&
        widget.events.onPrintRequested != null &&
        !widget.isLoading;
    final canRefresh =
        style.showRefreshAction &&
        widget.events.onRefresh != null &&
        !widget.isLoading;
    final showSelectionStatus = widget.selectedRowCount > 0;

    final hasAnyAction =
        style.showRefreshAction ||
        style.showExportActions ||
        style.showPrintAction ||
        style.showDensityToggle ||
        style.showColumnChooser ||
        (style.showGroupingChooser && widget.groupableColumns.isNotEmpty) ||
        activeGroups.isNotEmpty ||
        showSelectionStatus;

    if (!style.showSearchBar && !hasAnyAction) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.gapSm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < AppBreakpoints.mobile;
          final searchWidth = isCompact ? constraints.maxWidth : 220.0;

          return Wrap(
            spacing: tokens.gapSm,
            runSpacing: tokens.gapSm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (style.showSearchBar)
                SizedBox(
                  width: searchWidth,
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    enabled: !widget.isLoading,
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          tokens.formFieldRadius,
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: widget.isLoading
                                  ? null
                                  : () {
                                      _searchController.clear();
                                      widget.events.onSearchChanged?.call('');
                                    },
                            )
                          : null,
                    ),
                    onChanged: widget.events.onSearchChanged,
                  ),
                ),
              if (showSelectionStatus)
                Tooltip(
                  message: 'Linhas selecionadas na grade',
                  child: InputChip(
                    avatar: const Icon(Icons.checklist_rounded, size: 18),
                    label: Text(
                      widget.selectedRowCount == 1
                          ? '1 selecionado'
                          : '${widget.selectedRowCount} selecionados',
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onDeleted: widget.isLoading
                        ? null
                        : widget.onClearSelection,
                    deleteIcon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ...activeGroups.map((group) {
                final label = groupLabels[group.columnKey] ?? group.columnKey;
                return Tooltip(
                  message: 'Agrupado por $label',
                  child: InputChip(
                    avatar: const Icon(Icons.layers_outlined, size: 18),
                    label: Text(label),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onDeleted: widget.isLoading
                        ? null
                        : () {
                            final updatedGroups = activeGroups
                                .where((entry) => entry != group)
                                .toList(growable: false);
                            widget.events.onGroupChanged?.call(updatedGroups);
                          },
                    deleteIcon: const Icon(Icons.close_rounded, size: 18),
                  ),
                );
              }),
              if (style.showDensityToggle)
                _DensityToggle(
                  current: widget.currentDensity,
                  onChanged: widget.events.onDensityChanged,
                ),
              if (style.showGroupingChooser)
                _GroupButton<T>(
                  enabled: canGroup,
                  currentGroups: activeGroups,
                  groupableColumns: widget.groupableColumns,
                  onChanged: widget.events.onGroupChanged,
                ),
              if (activeGroups.isNotEmpty)
                _GroupStateButton(
                  icon: Icons.unfold_more_rounded,
                  tooltip: 'Expandir grupos',
                  onPressed: widget.isLoading
                      ? null
                      : () {
                          widget.events.onGroupStateChanged?.call(
                            activeGroups
                                .map(
                                  (group) => group.copyWith(expanded: true),
                                )
                                .toList(growable: false),
                          );
                          widget.groupController?.expandAll();
                        },
                ),
              if (activeGroups.isNotEmpty)
                _GroupStateButton(
                  icon: Icons.unfold_less_rounded,
                  tooltip: 'Recolher grupos',
                  onPressed: widget.isLoading
                      ? null
                      : () {
                          widget.events.onGroupStateChanged?.call(
                            activeGroups
                                .map(
                                  (group) => group.copyWith(expanded: false),
                                )
                                .toList(growable: false),
                          );
                          widget.groupController?.collapseAll();
                        },
                ),
              if (activeGroups.length > 1)
                _GroupLevelButton(
                  currentGroups: activeGroups,
                  levelCount: activeGroups.length,
                  controller: widget.groupController,
                  enabled: !widget.isLoading,
                  onGroupStateChanged: widget.events.onGroupStateChanged,
                ),
              if (style.showColumnChooser)
                Tooltip(
                  message: 'Colunas visíveis',
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.view_column_outlined, size: 18),
                    label: const Text('Colunas'),
                    onPressed: canChooseColumns
                        ? () async {
                            final result = await showAppReportColumnChooser<T>(
                              context: context,
                              columns: widget.columns,
                              currentlyVisible: widget.visibleColumnKeys,
                            );
                            if (result != null) {
                              widget.events.onColumnVisibilityChanged?.call(
                                result,
                              );
                            }
                          }
                        : null,
                  ),
                ),
              if (style.showExportActions)
                _ExportButton(
                  enabled: canExport,
                  selectedRowCount: widget.selectedRowCount,
                  onExportRequested: (request) =>
                      widget.events.onExportRequested?.call(request),
                ),
              if (style.showPrintAction)
                Tooltip(
                  message: 'Imprimir',
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Imprimir'),
                    onPressed: canPrint ? widget.events.onPrintRequested : null,
                  ),
                ),
              if (style.showRefreshAction)
                Tooltip(
                  message: 'Atualizar',
                  child: IconButton.outlined(
                    icon: widget.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: canRefresh
                        ? () => widget.events.onRefresh?.call()
                        : null,
                    tooltip: 'Atualizar dados',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Group state buttons
// ---------------------------------------------------------------------------

class _GroupStateButton extends StatelessWidget {
  const _GroupStateButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.outlined(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Group level button
// ---------------------------------------------------------------------------

class _GroupLevelButton extends StatelessWidget {
  const _GroupLevelButton({
    required this.currentGroups,
    required this.levelCount,
    required this.enabled,
    this.controller,
    this.onGroupStateChanged,
  });

  final List<AppReportGroupDescriptor> currentGroups;
  final int levelCount;
  final bool enabled;
  final AppReportGroupController? controller;
  final ValueChanged<List<AppReportGroupDescriptor>>? onGroupStateChanged;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, menuController, child) {
        return Tooltip(
          message: 'Controlar níveis de agrupamento',
          child: IconButton.outlined(
            onPressed: enabled
                ? () {
                    if (menuController.isOpen) {
                      menuController.close();
                    } else {
                      menuController.open();
                    }
                  }
                : null,
            icon: const Icon(Icons.account_tree_outlined, size: 18),
          ),
        );
      },
      menuChildren: <Widget>[
        for (var level = 1; level <= levelCount; level++) ...<Widget>[
          MenuItemButton(
            onPressed: enabled
                ? () {
                    onGroupStateChanged?.call(
                      currentGroups.indexed
                          .map((entry) {
                            final index = entry.$1;
                            final group = entry.$2;
                            return group.copyWith(expanded: index < level);
                          })
                          .toList(growable: false),
                    );
                    controller?.expandToLevel(level);
                  }
                : null,
            child: Text('Expandir até nível $level'),
          ),
          MenuItemButton(
            onPressed: enabled
                ? () {
                    onGroupStateChanged?.call(
                      currentGroups.indexed
                          .map((entry) {
                            final index = entry.$1;
                            final group = entry.$2;
                            return group.copyWith(expanded: index + 1 < level);
                          })
                          .toList(growable: false),
                    );
                    controller?.collapseToLevel(level);
                  }
                : null,
            child: Text('Recolher até nível $level'),
          ),
          if (level < levelCount) const Divider(height: 1),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Group button
// ---------------------------------------------------------------------------

class _GroupButton<T> extends StatelessWidget {
  const _GroupButton({
    required this.enabled,
    required this.currentGroups,
    required this.groupableColumns,
    this.onChanged,
  });

  final bool enabled;
  final List<AppReportGroupDescriptor> currentGroups;
  final List<AppReportColumn<T>> groupableColumns;
  final ValueChanged<List<AppReportGroupDescriptor>>? onChanged;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return OutlinedButton.icon(
          icon: const Icon(Icons.layers_outlined, size: 18),
          label: const Text('Agrupar'),
          onPressed: enabled
              ? () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                }
              : null,
        );
      },
      menuChildren: <Widget>[
        MenuItemButton(
          leadingIcon: const Icon(Icons.clear_all_rounded),
          onPressed: currentGroups.isEmpty
              ? null
              : () => onChanged?.call(const <AppReportGroupDescriptor>[]),
          child: const Text('Limpar agrupamento'),
        ),
        if (groupableColumns.isNotEmpty) const Divider(height: 1),
        ...groupableColumns.map((column) {
          final isActive = currentGroups.any(
            (group) => group.columnKey == column.key,
          );
          return MenuItemButton(
            leadingIcon: Icon(
              isActive ? Icons.check_rounded : Icons.add_rounded,
              size: 18,
            ),
            onPressed: () {
              final updatedGroups = isActive
                  ? currentGroups
                        .where((group) => group.columnKey != column.key)
                        .toList(growable: false)
                  : <AppReportGroupDescriptor>[
                      ...currentGroups,
                      AppReportGroupDescriptor(columnKey: column.key),
                    ];
              onChanged?.call(updatedGroups);
            },
            child: Text(column.label),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Density toggle
// ---------------------------------------------------------------------------

class _DensityToggle extends StatelessWidget {
  const _DensityToggle({
    required this.current,
    this.onChanged,
  });

  final AppReportDensity current;
  final ValueChanged<AppReportDensity>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AppReportDensity>(
      segments: const <ButtonSegment<AppReportDensity>>[
        ButtonSegment(
          value: AppReportDensity.compact,
          icon: Tooltip(
            message: 'Compacto',
            child: Icon(Icons.density_small_rounded, size: 18),
          ),
        ),
        ButtonSegment(
          value: AppReportDensity.comfortable,
          icon: Tooltip(
            message: 'Confortável',
            child: Icon(Icons.density_medium_rounded, size: 18),
          ),
        ),
        ButtonSegment(
          value: AppReportDensity.expanded,
          icon: Tooltip(
            message: 'Expandido',
            child: Icon(Icons.density_large_rounded, size: 18),
          ),
        ),
      ],
      selected: <AppReportDensity>{current},
      onSelectionChanged: (sel) => onChanged?.call(sel.first),
      showSelectedIcon: false,
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: WidgetStateProperty.all(const Size(36, 36)),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Export button
// ---------------------------------------------------------------------------

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.enabled,
    required this.onExportRequested,
    required this.selectedRowCount,
  });

  final bool enabled;
  final ValueChanged<AppReportExportRequest> onExportRequested;
  final int selectedRowCount;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (ctx, controller, child) {
        return OutlinedButton.icon(
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('Exportar'),
          onPressed: enabled
              ? () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                }
              : null,
        );
      },
      menuChildren: <Widget>[
        SubmenuButton(
          leadingIcon: const Icon(Icons.picture_as_pdf_outlined),
          menuChildren: _buildFormatMenuChildren(AppReportExportFormat.pdf),
          child: const Text('PDF'),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.table_chart_outlined),
          menuChildren: _buildFormatMenuChildren(AppReportExportFormat.excel),
          child: const Text('Excel'),
        ),
      ],
    );
  }

  List<Widget> _buildFormatMenuChildren(AppReportExportFormat format) {
    final scopeLabel = switch (format) {
      AppReportExportFormat.pdf => 'PDF',
      AppReportExportFormat.excel => 'Excel',
    };

    return <Widget>[
      _buildExportMenuItem(
        format: format,
        scope: AppReportExportScope.currentPage,
        label: '$scopeLabel da página atual',
      ),
      _buildExportMenuItem(
        format: format,
        scope: AppReportExportScope.allPages,
        label: '$scopeLabel de todas as páginas',
      ),
      if (selectedRowCount > 0)
        _buildExportMenuItem(
          format: format,
          scope: AppReportExportScope.selection,
          label: '$scopeLabel da seleção ($selectedRowCount)',
        ),
      const Divider(height: 1),
      _buildExportMenuItem(
        format: format,
        scope: AppReportExportScope.currentPage,
        includeFilters: true,
        label: '$scopeLabel da página atual + filtros',
      ),
      _buildExportMenuItem(
        format: format,
        scope: AppReportExportScope.allPages,
        includeFilters: true,
        label: '$scopeLabel de todas as páginas + filtros',
      ),
      if (selectedRowCount > 0)
        _buildExportMenuItem(
          format: format,
          scope: AppReportExportScope.selection,
          includeFilters: true,
          label: '$scopeLabel da seleção + filtros',
        ),
    ];
  }

  Widget _buildExportMenuItem({
    required AppReportExportFormat format,
    required AppReportExportScope scope,
    required String label,
    bool includeFilters = false,
  }) {
    return MenuItemButton(
      onPressed: () {
        onExportRequested(
          AppReportExportRequest(
            format: format,
            scope: scope,
            includeFilters: includeFilters,
          ),
        );
      },
      child: Text(label),
    );
  }
}
