import 'dart:async';

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_sidebar_filter.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_sidebar_list_widgets.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_overlay_chrome.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_layout_constants.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BrazilMapChartDesktopBranchSidebar extends StatefulWidget {
  const BrazilMapChartDesktopBranchSidebar({
    required this.width,
    required this.maxHeight,
    required this.entries,
    required this.allowCollapse,
    required this.onToggleCollapsed,
    required this.onSelectBranch,
    required this.onPreviewBranchStart,
    required this.onPreviewBranchEnd,
    super.key,
    this.selectedStoreId,
  });

  final double width;
  final double maxHeight;
  final List<AppBrazilStoreSalesVisibleBranchListItem> entries;
  final bool allowCollapse;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<AppBrazilStoreSalesPoint> onSelectBranch;
  final ValueChanged<AppBrazilStoreSalesPoint> onPreviewBranchStart;
  final VoidCallback onPreviewBranchEnd;
  final String? selectedStoreId;

  @override
  State<BrazilMapChartDesktopBranchSidebar> createState() =>
      BrazilMapChartDesktopBranchSidebarState();
}

class BrazilMapChartDesktopBranchSidebarState
    extends State<BrazilMapChartDesktopBranchSidebar> {
  static const double _scrollbarContentGutter = 14;
  static const Duration _focusRequestDebounce = Duration(milliseconds: 48);

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<FocusNode> _focusNodes = const <FocusNode>[];
  int _focusedIndex = 0;
  Timer? _focusRequestDebounceTimer;
  String? _lastQueuedFocusStoreId;
  BrazilMapChartDesktopBranchSidebarFilterResult? _filterResultCache;
  String? _filterResultQueryCache;
  List<AppBrazilStoreSalesVisibleBranchListItem>? _filterResultEntriesCache;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _syncFocusNodes();
    _queueFocusRequest();
  }

  @override
  void didUpdateWidget(covariant BrazilMapChartDesktopBranchSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectionChanged =
        oldWidget.selectedStoreId != widget.selectedStoreId;
    final entriesChanged = !brazilMapChartSidebarEntriesEquivalent(
      oldWidget.entries,
      widget.entries,
    );
    if (!entriesChanged && !selectionChanged) {
      return;
    }

    if (entriesChanged) {
      _invalidateFilterResultCache();
      _syncFocusNodes();
    } else {
      _invalidateFilterResultCache();
      final selectedIndex = _selectedIndex;
      if (selectedIndex >= 0) {
        _focusedIndex = selectedIndex;
      }
    }

    if (selectionChanged) {
      _queueFocusRequest();
    }
  }

  @override
  void dispose() {
    _focusRequestDebounceTimer?.cancel();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _scrollController.dispose();
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _searchQuery => _searchController.text.trim();

  void _invalidateFilterResultCache() {
    _filterResultCache = null;
    _filterResultQueryCache = null;
    _filterResultEntriesCache = null;
  }

  BrazilMapChartDesktopBranchSidebarFilterResult get _filterResult {
    final searchQuery = _searchQuery;
    final entries = widget.entries;
    final cachedResult = _filterResultCache;
    if (cachedResult != null &&
        identical(_filterResultEntriesCache, entries) &&
        _filterResultQueryCache == searchQuery) {
      return cachedResult;
    }

    final result = filterBrazilMapChartSidebarEntries(
      entries: entries,
      searchQuery: searchQuery,
    );
    _filterResultCache = result;
    _filterResultQueryCache = searchQuery;
    _filterResultEntriesCache = entries;
    return result;
  }

  List<AppBrazilStoreSalesVisibleBranchListItem> get _filteredEntries {
    return _filterResult.entries;
  }

  void _handleSearchChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _invalidateFilterResultCache();
      _syncFocusNodes();
    });
  }

  void _syncFocusNodes() {
    final entries = _filteredEntries;
    final nextLength = entries.length;
    if (_focusNodes.length == nextLength) {
      final selectedIndex = _selectedIndex;
      if (selectedIndex >= 0) {
        _focusedIndex = selectedIndex;
      } else if (_focusedIndex >= nextLength) {
        _focusedIndex = nextLength == 0 ? 0 : nextLength - 1;
      }
      return;
    }

    final nextNodes = List<FocusNode>.generate(
      nextLength,
      (index) => FocusNode(
        debugLabel: 'brazil-store-sales-map-sidebar-item-${entries[index].id}',
      ),
      growable: false,
    );
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _focusNodes = nextNodes;

    final selectedIndex = _selectedIndex;
    if (selectedIndex >= 0) {
      _focusedIndex = selectedIndex;
    } else if (_focusedIndex >= nextLength) {
      _focusedIndex = nextLength == 0 ? 0 : nextLength - 1;
    }
  }

  int get _selectedIndex {
    final selectedStoreId = widget.selectedStoreId;
    if (selectedStoreId == null) {
      return -1;
    }
    return _filteredEntries.indexWhere((entry) => entry.id == selectedStoreId);
  }

  void _queueFocusRequest() {
    final selectedStoreId = widget.selectedStoreId;
    if (selectedStoreId == _lastQueuedFocusStoreId) {
      return;
    }
    _lastQueuedFocusStoreId = selectedStoreId;
    _focusRequestDebounceTimer?.cancel();
    _focusRequestDebounceTimer = Timer(_focusRequestDebounce, () {
      if (!mounted || _focusNodes.isEmpty) {
        return;
      }
      if (_focusNodes.any((focusNode) => focusNode.hasFocus)) {
        return;
      }
      final targetIndex = _focusedIndex.clamp(0, _focusNodes.length - 1);
      _focusNodes[targetIndex].requestFocus();
    });
  }

  void _moveFocus(int delta) {
    if (_focusNodes.isEmpty) {
      return;
    }
    final nextIndex = (_focusedIndex + delta).clamp(0, _focusNodes.length - 1);
    if (nextIndex == _focusedIndex) {
      return;
    }
    setState(() {
      _focusedIndex = nextIndex;
    });
    _focusNodes[nextIndex].requestFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveFocus(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveFocus(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      final entries = _filteredEntries;
      if (entries.isEmpty) {
        return KeyEventResult.ignored;
      }
      widget.onSelectBranch(entries[_focusedIndex].point);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colorScheme = theme.colorScheme;
    final appColors = context.appColors;
    final l10n = AppLocalizations.of(context);
    final filteredEntries = _filteredEntries;
    final totalVisibleRevenue = _filterResult.totalVisibleRevenue;
    final hasActiveSearch = _searchQuery.isNotEmpty;
    final emptyStateTitle = hasActiveSearch
        ? l10n.brazilStoreSalesMapSidebarSearchEmptyStateTitle
        : l10n.brazilStoreSalesMapSidebarEmptyStateTitle;
    final emptyStateMessage = hasActiveSearch
        ? l10n.brazilStoreSalesMapSidebarSearchEmptyStateMessage
        : l10n.brazilStoreSalesMapSidebarEmptyStateMessage;

    return AppBrazilStoreSalesMapOverlayTooltipScope(
      child: SizedBox(
        width: widget.width,
        height: widget.maxHeight,
        child: AppSectionCard(
          color: colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(
            BrazilMapLayoutConstants.floatingMapOverlaySurfaceRadius,
          ),
          borderSide: BorderSide(
            color: appColors.secondary.withValues(alpha: 0.12),
          ),
          padding: EdgeInsets.fromLTRB(
            tokens.gapSm,
            tokens.gapSm,
            tokens.gapSm,
            tokens.gapXs,
          ),
          child: FocusTraversalGroup(
            child: Focus(
              autofocus: filteredEntries.isNotEmpty,
              onKeyEvent: _handleKeyEvent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: KeyedSubtree(
                          key: const ValueKey<String>(
                            'brazil-store-sales-map-sidebar',
                          ),
                          child: Text(
                            l10n.brazilStoreSalesMapSidebarTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      if (widget.allowCollapse)
                        AppBrazilStoreSalesMapWindowsSafeOverlayIconButton(
                          key: const ValueKey<String>(
                            'brazil-store-sales-map-sidebar-collapse',
                          ),
                          icon: Icons.chevron_left_rounded,
                          dimension: 32,
                          iconSize: 18,
                          onPressed: widget.onToggleCollapsed,
                          tooltipMessage:
                              l10n.brazilStoreSalesMapSidebarCollapseTooltip,
                        ),
                    ],
                  ),
                  SizedBox(height: tokens.gapXs * 0.5),
                  Text(
                    l10n.brazilStoreSalesMapSidebarCountSummary(
                      filteredEntries.length,
                    ),
                    key: const ValueKey<String>(
                      'brazil-store-sales-map-sidebar-count-summary',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: tokens.gapXs * 0.5),
                  Text(
                    l10n.brazilStoreSalesMapSidebarRevenueSummary(
                      AppBrFormatters.currency(totalVisibleRevenue),
                    ),
                    key: const ValueKey<String>(
                      'brazil-store-sales-map-sidebar-revenue-summary',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IgnorePointer(
                    child: Opacity(
                      opacity: 0,
                      child: SizedBox(
                        height: 0,
                        child: Text(
                          l10n.brazilStoreSalesMapSidebarSummary(
                            filteredEntries.length,
                            AppBrFormatters.currency(totalVisibleRevenue),
                          ),
                          key: const ValueKey<String>(
                            'brazil-store-sales-map-sidebar-summary',
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.gapXs),
                  AppTextField(
                    key: const ValueKey<String>(
                      'brazil-store-sales-map-sidebar-search',
                    ),
                    controller: _searchController,
                    hintText: l10n.brazilStoreSalesMapSidebarSearchPlaceholder,
                    prefixIcon: Icons.search_rounded,
                    density: AppTextFieldDensity.compact,
                    semanticsLabel:
                        l10n.brazilStoreSalesMapSidebarSearchSemanticsLabel,
                    textInputAction: TextInputAction.search,
                  ),
                  SizedBox(height: tokens.gapXs),
                  Expanded(
                    child: filteredEntries.isEmpty
                        ? BrazilMapChartDesktopBranchSidebarEmptyState(
                            title: emptyStateTitle,
                            message: emptyStateMessage,
                          )
                        : ScrollConfiguration(
                            behavior: ScrollConfiguration.of(
                              context,
                            ).copyWith(scrollbars: false),
                            child: ScrollbarTheme(
                              data: ScrollbarTheme.of(context).copyWith(
                                thumbColor: WidgetStatePropertyAll(
                                  colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.34,
                                  ),
                                ),
                                thickness: const WidgetStatePropertyAll(6),
                                radius: const Radius.circular(999),
                              ),
                              child: Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: false,
                                trackVisibility: false,
                                interactive: true,
                                child: ListView.separated(
                                  key: const ValueKey<String>(
                                    'brazil-store-sales-map-sidebar-list',
                                  ),
                                  controller: _scrollController,
                                  padding: EdgeInsets.only(
                                    right: _scrollbarContentGutter,
                                    bottom: tokens.gapXs,
                                  ),
                                  itemCount: filteredEntries.length,
                                  separatorBuilder: (_, index) =>
                                      SizedBox(height: tokens.gapXs),
                                  itemBuilder: (context, index) {
                                    final entry = filteredEntries[index];
                                    final isSelected =
                                        entry.id == widget.selectedStoreId;
                                    return BrazilMapChartDesktopBranchSidebarItem(
                                      rank: index + 1,
                                      entry: entry,
                                      focusNode: _focusNodes[index],
                                      isFocused: _focusedIndex == index,
                                      isSelected: isSelected,
                                      onFocus: () {
                                        if (_focusedIndex == index) {
                                          return;
                                        }
                                        setState(() {
                                          _focusedIndex = index;
                                        });
                                      },
                                      onTap: () =>
                                          widget.onSelectBranch(entry.point),
                                      onPreviewStart: () => widget
                                          .onPreviewBranchStart(entry.point),
                                      onPreviewEnd: widget.onPreviewBranchEnd,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
