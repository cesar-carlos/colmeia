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
    this.searchHintText,
  });

  /// Optional override for the search field hint. When null a generic localized
  /// hint is used (shared widget must not assume domain-specific copy).
  final String? searchHintText;

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
  late final FocusNode _searchFocusNode;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.searchTerm ?? '',
    );
    _searchFocusNode = FocusNode(debugLabel: 'AppReportToolbar.search');
  }

  @override
  void didUpdateWidget(covariant AppReportToolbar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hadFocus = _searchFocusNode.hasFocus;
    if (!hadFocus &&
        oldWidget.searchTerm != widget.searchTerm &&
        widget.searchTerm != _searchController.text) {
      final next = widget.searchTerm ?? '';
      _searchController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
    if (hadFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _searchFocusNode.hasFocus) {
          return;
        }
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchFocusNode.dispose();
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
    final l10n = AppLocalizations.of(context);
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
      final actionSpacing = compactToolbar ? tokens.gapXs : tokens.gapSm;
      final searchField = AppTextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        hintText: widget.searchHintText ?? l10n.reportSearchHint,
        prefixIcon: Icons.search_rounded,
        density: AppTextFieldDensity.compact,
        textInputAction: TextInputAction.search,
        onFieldSubmitted: (term) {
          _searchDebounceTimer?.cancel();
          widget.events.onSearchChanged?.call(term);
        },
        // Avoid rebuilding the whole AppTextField every keystroke:
        // a tiny ValueListenableBuilder watches just the text value
        // and toggles the suffix clear icon in isolation.
        suffix: _SearchClearButton(
          controller: _searchController,
          onCleared: () {
            _searchDebounceTimer?.cancel();
            widget.events.onSearchChanged?.call('');
          },
        ),
        onChanged: _emitSearchChanged,
      );
      final actionChildren = <Widget>[
        if (showSelectionStatus)
          _ToolbarPill(
            icon: Icons.checklist_rounded,
            label: l10n.reportSelectionPill(widget.selectedRowCount),
            tooltip: l10n.reportSelectionPillTooltip,
            onRemove: widget.isLoading ? null : widget.onClearSelection,
          ),
        ...activeGroups.map((group) {
          final label = groupLabels[group.columnKey] ?? group.columnKey;
          return _ToolbarPill(
            icon: Icons.layers_outlined,
            label: l10n.reportGroupedPill(label),
            tooltip: l10n.reportGroupedPillTooltip(label),
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
            onPressed: widget.isLoading ? null : widget.onOpenFiltersSheet,
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
            tooltip: l10n.reportExpandGroupsTooltip,
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
            tooltip: l10n.reportCollapseGroupsTooltip,
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
          _ColumnChooserButton<T>(
            enabled: canChooseColumns,
            columns: widget.columns,
            visibleColumnKeys: widget.visibleColumnKeys,
            compact: compactToolbar,
            onVisibilityChanged: widget.events.onColumnVisibilityChanged,
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
            message: l10n.reportPrintLabel,
            child: compactToolbar
                ? AppFlatButton(
                    onPressed: canPrint ? widget.events.onPrintRequested : null,
                    fillWidth: false,
                    child: const Icon(Icons.print_outlined, size: 18),
                  )
                : AppSecondaryButton(
                    onPressed: canPrint ? widget.events.onPrintRequested : null,
                    label: l10n.reportPrintLabel,
                    icon: const Icon(Icons.print_outlined, size: 18),
                  ),
          ),
        if (style.showRefreshAction)
          Tooltip(
            message: l10n.reportRefreshTooltip,
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
      ];
      final actionWrap = Wrap(
        spacing: actionSpacing,
        runSpacing: actionSpacing,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: actionChildren,
      );
      final Widget toolbarControls;
      if (!style.showSearchBar) {
        toolbarControls = actionWrap;
      } else if (isCompact) {
        toolbarControls = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            searchField,
            if (actionChildren.isNotEmpty) ...<Widget>[
              SizedBox(height: actionSpacing),
              actionWrap,
            ],
          ],
        );
      } else {
        toolbarControls = Row(
          children: <Widget>[
            Expanded(child: searchField),
            if (actionChildren.isNotEmpty) ...<Widget>[
              SizedBox(width: actionSpacing),
              actionWrap,
            ],
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!compactToolbar &&
              (style.showSearchBar || hasAnyAction) &&
              style.showToolbarLabel)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.gapSm),
              child: Text(
                l10n.reportToolbarLabel,
                style: typography.utilityOverline.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          toolbarControls,
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
          borderRadius: BorderRadius.circular(tokens.chipRadius),
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
                IconButton(
                  onPressed: onRemove,
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).deleteButtonTooltip,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  iconSize: 16,
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
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
    final l10n = AppLocalizations.of(context);
    return MenuAnchor(
      style: _buildReportMenuStyle(context),
      builder: (context, menuController, child) {
        return Tooltip(
          message: l10n.reportGroupLevelsTooltip,
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
            child: Text(l10n.reportExpandToLevel(level)),
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
            child: Text(l10n.reportCollapseToLevel(level)),
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
    final l10n = AppLocalizations.of(context);
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
            message: l10n.reportGroupLabel,
            child: AppFlatButton(
              onPressed: onPressed,
              fillWidth: false,
              child: const Icon(Icons.layers_outlined, size: 18),
            ),
          );
        }

        return AppSecondaryButton(
          onPressed: onPressed,
          label: l10n.reportGroupLabel,
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
          child: Text(l10n.reportClearGroupingAction),
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
    final l10n = AppLocalizations.of(context);
    return AppSegmentedControl<AppReportDensity>(
      options: <AppSegmentedControlOption<AppReportDensity>>[
        AppSegmentedControlOption(
          value: AppReportDensity.compact,
          label: l10n.reportDensityCompact,
          tooltip: l10n.reportDensityCompactTooltip,
        ),
        AppSegmentedControlOption(
          value: AppReportDensity.comfortable,
          label: l10n.reportDensityComfortable,
          tooltip: l10n.reportDensityComfortableTooltip,
        ),
        AppSegmentedControlOption(
          value: AppReportDensity.expanded,
          label: l10n.reportDensityExpanded,
          tooltip: l10n.reportDensityExpandedTooltip,
        ),
      ],
      value: current,
      onChanged: onChanged ?? (_) {},
    );
  }
}

// ---------------------------------------------------------------------------
// Column chooser button
// ---------------------------------------------------------------------------

class _ColumnChooserButton<T> extends StatelessWidget {
  const _ColumnChooserButton({
    required this.enabled,
    required this.columns,
    required this.visibleColumnKeys,
    required this.compact,
    this.onVisibilityChanged,
  });

  final bool enabled;
  final List<AppReportColumn<T>> columns;
  final Set<String> visibleColumnKeys;
  final bool compact;
  final ValueChanged<Set<String>>? onVisibilityChanged;

  Future<void> _openChooser(BuildContext context) async {
    final result = await showAppReportColumnChooser<T>(
      context: context,
      columns: columns,
      currentlyVisible: visibleColumnKeys,
    );
    if (result != null) {
      onVisibilityChanged?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onPressed = enabled ? () => _openChooser(context) : null;
    const icon = Icon(Icons.view_column_outlined, size: 18);
    return Tooltip(
      message: l10n.reportColumnsTooltip,
      child: compact
          ? AppFlatButton(
              onPressed: onPressed,
              fillWidth: false,
              child: icon,
            )
          : AppSecondaryButton(
              onPressed: onPressed,
              label: l10n.reportColumnsLabel,
              icon: icon,
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
    this.compact = false,
  });

  final bool enabled;
  final ValueChanged<AppReportExportRequest> onExportRequested;
  final int selectedRowCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            message: l10n.reportExportLabel,
            child: AppFlatButton(
              onPressed: onPressed,
              fillWidth: false,
              child: const Icon(Icons.download_outlined, size: 18),
            ),
          );
        }

        return AppSecondaryButton(
          onPressed: onPressed,
          label: l10n.reportExportLabel,
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
    final l10n = AppLocalizations.of(context);
    final scopeLabel = format.label;

    _ExportMenuItem item({
      required AppReportExportScope scope,
      required String label,
      bool includeFilters = false,
    }) {
      return _ExportMenuItem(
        format: format,
        scope: scope,
        label: label,
        includeFilters: includeFilters,
        onExportRequested: onExportRequested,
      );
    }

    final items = <Widget>[
      item(
        scope: AppReportExportScope.currentPage,
        label: l10n.reportExportScopeCurrentPage(scopeLabel),
      ),
      item(
        scope: AppReportExportScope.allPages,
        label: l10n.reportExportScopeAllPages(scopeLabel),
      ),
      if (selectedRowCount > 0)
        item(
          scope: AppReportExportScope.selection,
          label: l10n.reportExportScopeSelection(scopeLabel, selectedRowCount),
        ),
    ];

    if (format.supportsMetadataSections) {
      items
        ..add(const Divider(height: 1))
        ..add(
          item(
            scope: AppReportExportScope.currentPage,
            includeFilters: true,
            label: l10n.reportExportScopeCurrentPageWithFilters(scopeLabel),
          ),
        )
        ..add(
          item(
            scope: AppReportExportScope.allPages,
            includeFilters: true,
            label: l10n.reportExportScopeAllPagesWithFilters(scopeLabel),
          ),
        );
      if (selectedRowCount > 0) {
        items.add(
          item(
            scope: AppReportExportScope.selection,
            includeFilters: true,
            label: l10n.reportExportScopeSelectionWithFilters(scopeLabel),
          ),
        );
      }
    }

    return items;
  }
}

class _ExportMenuItem extends StatelessWidget {
  const _ExportMenuItem({
    required this.format,
    required this.scope,
    required this.label,
    required this.onExportRequested,
    this.includeFilters = false,
  });

  final AppReportExportFormat format;
  final AppReportExportScope scope;
  final String label;
  final ValueChanged<AppReportExportRequest> onExportRequested;
  final bool includeFilters;

  @override
  Widget build(BuildContext context) {
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
    required this.onCleared,
  });

  final TextEditingController controller;
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
          tooltip: AppLocalizations.of(context).reportClearSearchTooltip,
          onPressed: () {
            controller.clear();
            onCleared();
          },
        );
      },
    );
  }
}
