part of 'app_brazil_store_sales_map_chart.dart';

class _DesktopBranchSidebarOverlay extends StatelessWidget {
  const _DesktopBranchSidebarOverlay({
    required this.width,
    required this.maxHeight,
    required this.topInset,
    required this.horizontalInset,
    required this.entries,
    required this.allowCollapse,
    required this.onToggleCollapsed,
    required this.onSelectBranch,
    required this.onPreviewBranchStart,
    required this.onPreviewBranchEnd,
    this.selectedStoreId,
  });

  final double width;
  final double maxHeight;
  final double topInset;
  final double horizontalInset;
  final List<AppBrazilStoreSalesVisibleBranchListItem> entries;
  final bool allowCollapse;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<AppBrazilStoreSalesPoint> onSelectBranch;
  final ValueChanged<AppBrazilStoreSalesPoint> onPreviewBranchStart;
  final VoidCallback onPreviewBranchEnd;
  final String? selectedStoreId;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topInset,
      left: horizontalInset,
      child: KeyedSubtree(
        key: const ValueKey<String>('brazil-store-sales-map-sidebar-floating'),
        child: _DesktopBranchSidebar(
          width: width,
          maxHeight: maxHeight,
          entries: entries,
          selectedStoreId: selectedStoreId,
          allowCollapse: allowCollapse,
          onToggleCollapsed: onToggleCollapsed,
          onSelectBranch: onSelectBranch,
          onPreviewBranchStart: onPreviewBranchStart,
          onPreviewBranchEnd: onPreviewBranchEnd,
        ),
      ),
    );
  }
}

class _DesktopBranchSidebarCollapsedOverlay extends StatelessWidget {
  const _DesktopBranchSidebarCollapsedOverlay({
    required this.topInset,
    required this.horizontalInset,
    required this.onExpand,
  });

  final double topInset;
  final double horizontalInset;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colorScheme = theme.colorScheme;
    final appColors = context.appColors;
    final l10n = AppLocalizations.of(context);

    return Positioned(
      top: topInset,
      left: horizontalInset,
      child: KeyedSubtree(
        key: const ValueKey<String>(
          'brazil-store-sales-map-sidebar-collapsed',
        ),
        child: AppSectionCard(
          color: colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(_floatingMapOverlaySurfaceRadius),
          borderSide: BorderSide(
            color: appColors.secondary.withValues(alpha: 0.12),
          ),
          padding: EdgeInsets.zero,
          child: Tooltip(
            message: l10n.brazilStoreSalesMapSidebarExpandTooltip,
            child: InkWell(
              borderRadius: BorderRadius.circular(
                _floatingMapOverlaySurfaceRadius,
              ),
              onTap: onExpand,
              child: Padding(
                padding: EdgeInsets.all(tokens.gapSm),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: appColors.secondary,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopBranchSidebar extends StatefulWidget {
  const _DesktopBranchSidebar({
    required this.width,
    required this.maxHeight,
    required this.entries,
    required this.allowCollapse,
    required this.onToggleCollapsed,
    required this.onSelectBranch,
    required this.onPreviewBranchStart,
    required this.onPreviewBranchEnd,
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
  State<_DesktopBranchSidebar> createState() => _DesktopBranchSidebarState();
}

class _DesktopBranchSidebarState extends State<_DesktopBranchSidebar> {
  static const double _scrollbarContentGutter = 14;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<FocusNode> _focusNodes = const <FocusNode>[];
  int _focusedIndex = 0;
  _DesktopBranchSidebarFilterResult? _filterResultCache;
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
  void didUpdateWidget(covariant _DesktopBranchSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries ||
        oldWidget.selectedStoreId != widget.selectedStoreId) {
      _invalidateFilterResultCache();
      _syncFocusNodes();
      _queueFocusRequest();
    }
  }

  @override
  void dispose() {
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

  _DesktopBranchSidebarFilterResult get _filterResult {
    final searchQuery = _searchQuery;
    final entries = widget.entries;
    final cachedResult = _filterResultCache;
    if (cachedResult != null &&
        identical(_filterResultEntriesCache, entries) &&
        _filterResultQueryCache == searchQuery) {
      return cachedResult;
    }

    final normalizedQuery = _normalizedSearchToken(searchQuery);
    final filteredEntries = normalizedQuery == null
        ? entries
        : entries
              .where((entry) => entry.searchIndexText.contains(normalizedQuery))
              .toList(growable: false);
    final totalVisibleRevenue = filteredEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.salesAmount,
    );
    final result = _DesktopBranchSidebarFilterResult(
      entries: filteredEntries,
      totalVisibleRevenue: totalVisibleRevenue,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

    return SizedBox(
      width: widget.width,
      height: widget.maxHeight,
      child: AppSectionCard(
        color: colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(_floatingMapOverlaySurfaceRadius),
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
                      Tooltip(
                        message: l10n.brazilStoreSalesMapSidebarCollapseTooltip,
                        child: InkWell(
                          key: const ValueKey<String>(
                          'brazil-store-sales-map-sidebar-collapse',
                        ),
                          borderRadius: BorderRadius.circular(12),
                          onTap: widget.onToggleCollapsed,
                          child: Padding(
                            padding: EdgeInsets.all(tokens.gapXs * 0.6),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
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
                      ? _DesktopBranchSidebarEmptyState(
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
                                  return _DesktopBranchSidebarItem(
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
    );
  }
}

String? _normalizedSearchToken(String? value) {
  final normalized = AppLocationLookupNormalizer.normalizeAddressLine(value);
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

class _DesktopBranchSidebarFilterResult {
  const _DesktopBranchSidebarFilterResult({
    required this.entries,
    required this.totalVisibleRevenue,
  });

  final List<AppBrazilStoreSalesVisibleBranchListItem> entries;
  final double totalVisibleRevenue;
}

class _DesktopBranchSidebarEmptyState extends StatelessWidget {
  const _DesktopBranchSidebarEmptyState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colorScheme = theme.colorScheme;

    return Center(
      child: KeyedSubtree(
        key: const ValueKey<String>('brazil-store-sales-map-sidebar-empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.storefront_outlined,
              size: 28,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: tokens.gapSm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: tokens.gapXs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopBranchSidebarItem extends StatelessWidget {
  const _DesktopBranchSidebarItem({
    required this.rank,
    required this.entry,
    required this.focusNode,
    required this.isFocused,
    required this.isSelected,
    required this.onFocus,
    required this.onTap,
    required this.onPreviewStart,
    required this.onPreviewEnd,
  });

  final int rank;
  final AppBrazilStoreSalesVisibleBranchListItem entry;
  final FocusNode focusNode;
  final bool isFocused;
  final bool isSelected;
  final VoidCallback onFocus;
  final VoidCallback onTap;
  final VoidCallback onPreviewStart;
  final VoidCallback onPreviewEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colorScheme = theme.colorScheme;
    final highlight = context.appColors.secondary;
    final amountLabel = AppBrFormatters.currency(entry.salesAmount);
    final statusLabel = _statusLabel(context);
    final rankLabel = '#$rank';

    return Semantics(
      button: true,
      selected: isSelected,
      label: [
        rankLabel,
        entry.displayName,
        if (entry.secondaryDisplayName != null) entry.secondaryDisplayName!,
        entry.cityUfLabel,
        if (statusLabel != null) statusLabel else amountLabel,
      ].join(', '),
      child: MouseRegion(
        onEnter: (_) => onPreviewStart(),
        onExit: (_) => onPreviewEnd(),
        child: InkWell(
          key: ValueKey<String>(
            'brazil-store-sales-map-sidebar-item-${entry.id}',
          ),
          focusNode: focusNode,
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              onFocus();
            }
          },
          borderRadius: BorderRadius.circular(tokens.formFieldRadius),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected
                  ? highlight.withValues(alpha: 0.12)
                  : isFocused
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(tokens.formFieldRadius),
              border: Border.all(
                color: isSelected
                    ? highlight
                    : isFocused
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: isSelected
                    ? 1.8
                    : isFocused
                    ? 1.4
                    : 1,
              ),
              boxShadow: isSelected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: highlight.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.gapSm,
                vertical: tokens.gapXs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.gapXs,
                          vertical: tokens.gapXs * 0.6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? highlight.withValues(alpha: 0.18)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            tokens.formFieldRadius,
                          ),
                        ),
                        child: Text(
                          rankLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? highlight
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(width: tokens.gapXs),
                      Expanded(
                        child: Text(
                          entry.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.gapXs * 0.5),
                  if (entry.secondaryDisplayName != null) ...[
                    Text(
                      entry.secondaryDisplayName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: tokens.gapXs * 0.5),
                  ],
                  Text(
                    entry.cityUfLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: tokens.gapXs),
                  if (entry.state ==
                      AppBrazilStoreSalesVisibleBranchListItemState.loading)
                    _DesktopBranchSidebarStatusRow(
                      icon: Icons.sync_rounded,
                      label: _statusLabel(context)!,
                      color: highlight,
                    )
                  else ...[
                    Text(
                      amountLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isSelected ? highlight : colorScheme.onSurface,
                      ),
                    ),
                    if (statusLabel != null) ...[
                      SizedBox(height: tokens.gapXs),
                      _DesktopBranchSidebarStatusRow(
                        icon: _statusIcon,
                        label: statusLabel,
                        color: _statusColor(
                          colorScheme: colorScheme,
                          highlight: highlight,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData get _statusIcon => switch (entry.state) {
    AppBrazilStoreSalesVisibleBranchListItemState.loading => Icons.sync_rounded,
    AppBrazilStoreSalesVisibleBranchListItemState.unavailable =>
      Icons.sync_problem_outlined,
    AppBrazilStoreSalesVisibleBranchListItemState.zeroSales =>
      Icons.remove_shopping_cart_outlined,
    AppBrazilStoreSalesVisibleBranchListItemState.regular => Icons.attach_money,
  };

  String? _statusLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (entry.state) {
      AppBrazilStoreSalesVisibleBranchListItemState.loading =>
        l10n.brazilStoreSalesMapSalesLoadingLabel,
      AppBrazilStoreSalesVisibleBranchListItemState.unavailable =>
        entry.point.salesDataStatusLabel ??
            l10n.brazilStoreSalesMapSalesUnavailableFallback,
      AppBrazilStoreSalesVisibleBranchListItemState.zeroSales =>
        l10n.brazilStoreSalesMapSidebarZeroSalesLabel,
      AppBrazilStoreSalesVisibleBranchListItemState.regular => null,
    };
  }

  Color _statusColor({
    required ColorScheme colorScheme,
    required Color highlight,
  }) {
    return switch (entry.state) {
      AppBrazilStoreSalesVisibleBranchListItemState.loading => highlight,
      AppBrazilStoreSalesVisibleBranchListItemState.unavailable =>
        colorScheme.error,
      AppBrazilStoreSalesVisibleBranchListItemState.zeroSales =>
        colorScheme.onSurfaceVariant,
      AppBrazilStoreSalesVisibleBranchListItemState.regular =>
        colorScheme.onSurface,
    };
  }
}

class _DesktopBranchSidebarStatusRow extends StatelessWidget {
  const _DesktopBranchSidebarStatusRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Row(
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        SizedBox(width: tokens.gapXs),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
