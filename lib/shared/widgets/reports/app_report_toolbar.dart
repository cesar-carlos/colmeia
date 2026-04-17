import 'dart:async';

import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
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
    this.onOpenFiltersSheet,
    this.activeFilterCount = 0,
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
  final VoidCallback? onOpenFiltersSheet;
  final int activeFilterCount;

  @override
  State<AppReportToolbar<T>> createState() => _AppReportToolbarState<T>();
}

class _AppReportToolbarState<T> extends State<AppReportToolbar<T>> {
  late final TextEditingController _searchController;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.searchTerm ?? '',
    );
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
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _emitSearchChanged(String term) {
    final debounce = widget.style.searchDebounce;
    if (debounce == Duration.zero) {
      widget.events.onSearchChanged?.call(term);
      return;
    }

    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(
      debounce,
      () => widget.events.onSearchChanged?.call(term),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final style = widget.style;
    if (style.toolbarMode == AppReportToolbarMode.hidden) {
      return const SizedBox.shrink();
    }
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
    final canOpenFiltersSheet =
        style.showFiltersPanel &&
        style.filterLayout == AppReportFilterLayout.sheet &&
        widget.onOpenFiltersSheet != null;
    final showSelectionStatus = widget.selectedRowCount > 0;

    final hasAnyAction =
        canOpenFiltersSheet ||
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

    final compactToolbar = style.toolbarMode == AppReportToolbarMode.compact;

    Widget buildContent(BoxConstraints constraints) {
      final isCompact = constraints.maxWidth < AppBreakpoints.mobile;
      final searchWidth = compactToolbar
          ? (isCompact ? constraints.maxWidth : 220.0)
          : (isCompact ? constraints.maxWidth : 260.0);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!compactToolbar &&
              (style.showSearchBar || hasAnyAction) &&
              style.showToolbarLabel)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.gapSm),
              child: Text(
                'Ferramentas da tabela',
                style: typography.utilityOverline.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          Wrap(
            spacing: compactToolbar ? tokens.gapXs : tokens.gapSm,
            runSpacing: compactToolbar ? tokens.gapXs : tokens.gapSm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (style.showSearchBar)
                SizedBox(
                  width: searchWidth,
                  child: AppTextField(
                    controller: _searchController,
                    enabled: !widget.isLoading,
                    hintText: 'Buscar vendedor, loja ou produto',
                    prefixIcon: Icons.search_rounded,
                    density: AppTextFieldDensity.compact,
                    // Avoid rebuilding the whole AppTextField every keystroke:
                    // a tiny ValueListenableBuilder watches just the text value
                    // and toggles the suffix clear icon in isolation.
                    suffix: _SearchClearButton(
                      controller: _searchController,
                      isLoading: widget.isLoading,
                      onCleared: () {
                        _searchDebounceTimer?.cancel();
                        widget.events.onSearchChanged?.call('');
                      },
                    ),
                    onChanged: _emitSearchChanged,
                  ),
                ),
              if (showSelectionStatus)
                _ToolbarPill(
                  icon: Icons.checklist_rounded,
                  label: widget.selectedRowCount == 1
                      ? '1 selecionado'
                      : '${widget.selectedRowCount} selecionados',
                  tooltip: 'Linhas selecionadas na grade',
                  onRemove: widget.isLoading ? null : widget.onClearSelection,
                ),
              ...activeGroups.map((group) {
                final label = groupLabels[group.columnKey] ?? group.columnKey;
                return _ToolbarPill(
                  icon: Icons.layers_outlined,
                  label: 'Agrupado: $label',
                  tooltip: 'Agrupado por $label',
                  onRemove: widget.isLoading
                      ? null
                      : () {
                          final updatedGroups = activeGroups
                              .where((entry) => entry != group)
                              .toList(growable: false);
                          widget.events.onGroupChanged?.call(updatedGroups);
                        },
                );
              }),
              if (canOpenFiltersSheet)
                _FilterSheetButton(
                  onPressed: widget.isLoading
                      ? null
                      : widget.onOpenFiltersSheet,
                  activeCount: widget.activeFilterCount,
                  compact: compactToolbar,
                ),
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
                  compact: compactToolbar,
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
                                .map((group) => group.copyWith(expanded: true))
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
                                .map((group) => group.copyWith(expanded: false))
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
                  child: compactToolbar
                      ? AppFlatButton(
                          onPressed: canChooseColumns
                              ? () async {
                                  final result =
                                      await showAppReportColumnChooser<T>(
                                        context: context,
                                        columns: widget.columns,
                                        currentlyVisible:
                                            widget.visibleColumnKeys,
                                      );
                                  if (result != null) {
                                    widget.events.onColumnVisibilityChanged
                                        ?.call(result);
                                  }
                                }
                              : null,
                          fillWidth: false,
                          child: const Icon(
                            Icons.view_column_outlined,
                            size: 18,
                          ),
                        )
                      : AppSecondaryButton(
                          onPressed: canChooseColumns
                              ? () async {
                                  final result =
                                      await showAppReportColumnChooser<T>(
                                        context: context,
                                        columns: widget.columns,
                                        currentlyVisible:
                                            widget.visibleColumnKeys,
                                      );
                                  if (result != null) {
                                    widget.events.onColumnVisibilityChanged
                                        ?.call(result);
                                  }
                                }
                              : null,
                          label: 'Colunas',
                          icon: const Icon(
                            Icons.view_column_outlined,
                            size: 18,
                          ),
                        ),
                ),
              if (style.showExportActions)
                _ExportButton(
                  enabled: canExport,
                  selectedRowCount: widget.selectedRowCount,
                  onExportRequested: (request) =>
                      widget.events.onExportRequested?.call(request),
                  compact: compactToolbar,
                ),
              if (style.showPrintAction)
                Tooltip(
                  message: 'Imprimir',
                  child: compactToolbar
                      ? AppFlatButton(
                          onPressed: canPrint
                              ? widget.events.onPrintRequested
                              : null,
                          fillWidth: false,
                          child: const Icon(Icons.print_outlined, size: 18),
                        )
                      : AppSecondaryButton(
                          onPressed: canPrint
                              ? widget.events.onPrintRequested
                              : null,
                          label: 'Imprimir',
                          icon: const Icon(Icons.print_outlined, size: 18),
                        ),
                ),
              if (style.showRefreshAction)
                Tooltip(
                  message: 'Atualizar',
                  child: AppFlatButton(
                    onPressed: canRefresh
                        ? () => widget.events.onRefresh?.call()
                        : null,
                    fillWidth: false,
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 20),
                  ),
                ),
            ],
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.gapSm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = buildContent(constraints);
          if (compactToolbar) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.gapXs),
              child: content,
            );
          }

          return DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(tokens.gapSm),
              child: content,
            ),
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
      child: AppFlatButton(
        onPressed: onPressed,
        fillWidth: false,
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _ToolbarPill extends StatelessWidget {
  const _ToolbarPill({
    required this.icon,
    required this.label,
    required this.tooltip,
    this.onRemove,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(tokens.formFieldRadius + 10),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: tokens.gapSm,
            right: onRemove == null ? tokens.gapSm : tokens.gapXs,
            top: tokens.gapXs,
            bottom: tokens.gapXs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppTagChip(
                label: label,
                icon: icon,
                backgroundColor: Colors.transparent,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
              if (onRemove != null) ...<Widget>[
                SizedBox(width: tokens.gapXs),
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheetButton extends StatelessWidget {
  const _FilterSheetButton({
    required this.activeCount,
    this.onPressed,
    this.compact = false,
  });

  final VoidCallback? onPressed;
  final int activeCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasActiveFilters = activeCount > 0;
    final icon = Badge.count(
      isLabelVisible: hasActiveFilters,
      count: activeCount,
      child: Icon(
        Icons.filter_list_rounded,
        size: 18,
        color: hasActiveFilters ? theme.colorScheme.primary : null,
      ),
    );

    if (compact) {
      return Tooltip(
        message: hasActiveFilters
            ? l10n.reportFiltersButtonActive(activeCount)
            : l10n.reportFiltersButton,
        child: AppFlatButton(
          onPressed: onPressed,
          fillWidth: false,
          child: icon,
        ),
      );
    }

    return AppSecondaryButton(
      onPressed: onPressed,
      label: l10n.reportFiltersButton,
      icon: icon,
    );
  }
}

MenuStyle _buildReportMenuStyle(BuildContext context) {
  final theme = Theme.of(context);
  final tokens = theme.extension<AppThemeTokens>()!;

  return MenuStyle(
    backgroundColor: WidgetStatePropertyAll(
      theme.colorScheme.surfaceContainerLow,
    ),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    shadowColor: WidgetStatePropertyAll(
      theme.colorScheme.shadow.withValues(alpha: 0.12),
    ),
    side: WidgetStatePropertyAll(
      BorderSide(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
      ),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
      ),
    ),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(vertical: tokens.gapXs),
    ),
  );
}

ButtonStyle _buildReportMenuItemStyle(BuildContext context) {
  final theme = Theme.of(context);
  final tokens = theme.extension<AppThemeTokens>()!;
  final typography = theme.appTypography;

  return ButtonStyle(
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(
        horizontal: tokens.gapMd,
        vertical: tokens.gapSm,
      ),
    ),
    textStyle: WidgetStatePropertyAll(
      typography.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    ),
    foregroundColor: WidgetStatePropertyAll(theme.colorScheme.onSurface),
    iconColor: WidgetStatePropertyAll(theme.colorScheme.onSurfaceVariant),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return theme.colorScheme.primary.withValues(alpha: 0.08);
      }
      if (states.contains(WidgetState.hovered)) {
        return theme.colorScheme.primary.withValues(alpha: 0.04);
      }
      return null;
    }),
  );
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
      style: _buildReportMenuStyle(context),
      builder: (context, menuController, child) {
        return Tooltip(
          message: 'Controlar níveis de agrupamento',
          child: AppFlatButton(
            onPressed: enabled
                ? () {
                    if (menuController.isOpen) {
                      menuController.close();
                    } else {
                      menuController.open();
                    }
                  }
                : null,
            fillWidth: false,
            child: const Icon(Icons.account_tree_outlined, size: 18),
          ),
        );
      },
      menuChildren: <Widget>[
        for (var level = 1; level <= levelCount; level++) ...<Widget>[
          MenuItemButton(
            style: _buildReportMenuItemStyle(context),
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
            style: _buildReportMenuItemStyle(context),
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
    this.compact = false,
    this.onChanged,
  });

  final bool enabled;
  final List<AppReportGroupDescriptor> currentGroups;
  final List<AppReportColumn<T>> groupableColumns;
  final bool compact;
  final ValueChanged<List<AppReportGroupDescriptor>>? onChanged;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: _buildReportMenuStyle(context),
      builder: (context, controller, child) {
        final onPressed = enabled
            ? () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              }
            : null;
        if (compact) {
          return Tooltip(
            message: 'Agrupar',
            child: AppFlatButton(
              onPressed: onPressed,
              fillWidth: false,
              child: const Icon(Icons.layers_outlined, size: 18),
            ),
          );
        }

        return AppSecondaryButton(
          onPressed: onPressed,
          label: 'Agrupar',
          icon: const Icon(Icons.layers_outlined, size: 18),
        );
      },
      menuChildren: <Widget>[
        MenuItemButton(
          style: _buildReportMenuItemStyle(context),
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
            style: _buildReportMenuItemStyle(context),
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
    return AppSegmentedControl<AppReportDensity>(
      options: const <AppSegmentedControlOption<AppReportDensity>>[
        AppSegmentedControlOption(
          value: AppReportDensity.compact,
          label: 'Compacto',
          tooltip: 'Linhas mais densas',
        ),
        AppSegmentedControlOption(
          value: AppReportDensity.comfortable,
          label: 'Conforto',
          tooltip: 'Equilibrio entre leitura e densidade',
        ),
        AppSegmentedControlOption(
          value: AppReportDensity.expanded,
          label: 'Expandido',
          tooltip: 'Mais respiro vertical',
        ),
      ],
      value: current,
      onChanged: onChanged ?? (_) {},
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
    this.compact = false,
  });

  final bool enabled;
  final ValueChanged<AppReportExportRequest> onExportRequested;
  final int selectedRowCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: _buildReportMenuStyle(context),
      builder: (ctx, controller, child) {
        final onPressed = enabled
            ? () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              }
            : null;
        if (compact) {
          return Tooltip(
            message: 'Exportar',
            child: AppFlatButton(
              onPressed: onPressed,
              fillWidth: false,
              child: const Icon(Icons.download_outlined, size: 18),
            ),
          );
        }

        return AppSecondaryButton(
          onPressed: onPressed,
          label: 'Exportar',
          icon: const Icon(Icons.download_outlined, size: 18),
        );
      },
      menuChildren: <Widget>[
        for (final format in AppReportExportFormat.values)
          SubmenuButton(
            menuStyle: _buildReportMenuStyle(context),
            style: _buildReportMenuItemStyle(context),
            leadingIcon: Icon(format.icon),
            menuChildren: _buildFormatMenuChildren(context, format),
            child: Text(format.label),
          ),
      ],
    );
  }

  List<Widget> _buildFormatMenuChildren(
    BuildContext context,
    AppReportExportFormat format,
  ) {
    final scopeLabel = format.label;

    final items = <Widget>[
      _buildExportMenuItem(
        context: context,
        format: format,
        scope: AppReportExportScope.currentPage,
        label: '$scopeLabel da página atual',
      ),
      _buildExportMenuItem(
        context: context,
        format: format,
        scope: AppReportExportScope.allPages,
        label: '$scopeLabel de todas as páginas',
      ),
      if (selectedRowCount > 0)
        _buildExportMenuItem(
          context: context,
          format: format,
          scope: AppReportExportScope.selection,
          label: '$scopeLabel da seleção ($selectedRowCount)',
        ),
    ];

    if (format.supportsMetadataSections) {
      items
        ..add(const Divider(height: 1))
        ..add(
          _buildExportMenuItem(
            context: context,
            format: format,
            scope: AppReportExportScope.currentPage,
            includeFilters: true,
            label: '$scopeLabel da página atual + filtros',
          ),
        )
        ..add(
          _buildExportMenuItem(
            context: context,
            format: format,
            scope: AppReportExportScope.allPages,
            includeFilters: true,
            label: '$scopeLabel de todas as páginas + filtros',
          ),
        );
      if (selectedRowCount > 0) {
        items.add(
          _buildExportMenuItem(
            context: context,
            format: format,
            scope: AppReportExportScope.selection,
            includeFilters: true,
            label: '$scopeLabel da seleção + filtros',
          ),
        );
      }
    }

    return items;
  }

  Widget _buildExportMenuItem({
    required BuildContext context,
    required AppReportExportFormat format,
    required AppReportExportScope scope,
    required String label,
    bool includeFilters = false,
  }) {
    return MenuItemButton(
      style: _buildReportMenuItemStyle(context),
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

// ---------------------------------------------------------------------------
// Search clear button
// ---------------------------------------------------------------------------

/// Minimal listener that rebuilds only when the search text is empty/non-empty
/// changes. Keeps the parent [AppTextField] off the rebuild path that would
/// otherwise fire on every keystroke.
class _SearchClearButton extends StatelessWidget {
  const _SearchClearButton({
    required this.controller,
    required this.isLoading,
    required this.onCleared,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.text.isEmpty) {
          return const SizedBox.shrink();
        }
        return IconButton(
          icon: const Icon(Icons.close_rounded, size: 18),
          tooltip: 'Limpar busca',
          onPressed: isLoading
              ? null
              : () {
                  controller.clear();
                  onCleared();
                },
        );
      },
    );
  }
}
