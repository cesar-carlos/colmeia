part of 'overview_home_agent_filter_control.dart';

/// Bulk-selection modal sheet opened from
/// [OverviewHomeAgentFilterControl]. Renders the searchable agent list,
/// bulk select/deselect actions, and the apply/cancel CTAs.
class _OverviewAgentSelectionSheet extends StatefulWidget {
  const _OverviewAgentSelectionSheet({
    required this.l10n,
    required this.availableAgents,
    required this.initialSelected,
  });

  final AppLocalizations l10n;
  final List<DashboardAgentOption> availableAgents;
  final Set<String> initialSelected;

  @override
  State<_OverviewAgentSelectionSheet> createState() =>
      _OverviewAgentSelectionSheetState();
}

class _OverviewAgentSelectionSheetState
    extends State<_OverviewAgentSelectionSheet> {
  late Set<String> _selected;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelected);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim().toLowerCase();

  List<DashboardAgentOption> get _filtered {
    final q = _query;
    if (q.isEmpty) {
      return widget.availableAgents;
    }
    return widget.availableAgents
        .where((a) => a.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  void _toggle(String agentId, bool? checked) {
    if (checked ?? false) {
      setState(() => _selected.add(agentId));
    } else {
      setState(() => _selected.remove(agentId));
    }
  }

  void _selectAllAgents() {
    final allIds = widget.availableAgents.map((a) => a.agentId).toSet();
    setState(() => _selected = allIds);
  }

  void _deselectAllAgents() {
    setState(_selected.clear);
  }

  void _selectAllMatching() {
    final next = Set<String>.from(_selected);
    for (final a in _filtered) {
      next.add(a.agentId);
    }
    setState(() => _selected = next);
  }

  void _deselectAllMatching() {
    final visible = _filtered;
    setState(() {
      for (final a in visible) {
        _selected.remove(a.agentId);
      }
    });
  }

  void _popWithAllBranches() {
    final allIds = widget.availableAgents.map((e) => e.agentId).toSet();
    Navigator.of(context).pop(allIds);
  }

  void _apply() {
    Navigator.of(context).pop(Set<String>.from(_selected));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.extension<AppThemeTokens>()!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final filtered = _filtered;
    final showFilteredBulk = _query.isNotEmpty && filtered.isNotEmpty;
    final allFilteredSelected =
        filtered.isNotEmpty &&
        filtered.every((a) => _selected.contains(a.agentId));
    final anyFilteredSelected = filtered.any(
      (a) => _selected.contains(a.agentId),
    );
    final byIdForBanner = <String, DashboardAgentOption>{
      for (final a in widget.availableAgents) a.agentId: a,
    };
    final showMissingTokenBanner = _selected.any(
      (id) => byIdForBanner[id]?.missingLocalClientToken ?? false,
    );
    final showCounter = widget.availableAgents.isNotEmpty;
    final bulkActionStyle = TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.gapMd,
        vertical: tokens.gapSm,
      ),
    );

    final minChromePx =
        236.0 +
        44.0 +
        (showCounter ? 28.0 : 0.0) +
        (widget.availableAgents.isNotEmpty ? 44.0 : 0.0) +
        (showFilteredBulk ? 88.0 : 0.0) +
        (showMissingTokenBanner ? 88.0 : 0.0) +
        (_selected.isEmpty ? 44.0 : 0.0);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: draggableSheetMinChildFractionForChrome(
          viewportHeight: viewportHeight,
          minChromePixels: minChromePx,
        ),
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(560, MediaQuery.sizeOf(context).width),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const BottomSheetCompactDragHandle(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.contentSpacing,
                      0,
                      tokens.contentSpacing,
                      tokens.gapSm,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            widget.l10n.overviewHomeBranchFilterSheetTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  if (widget.availableAgents.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        tokens.contentSpacing,
                        tokens.gapXs,
                        tokens.contentSpacing,
                        0,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          style: bulkActionStyle,
                          onPressed: _popWithAllBranches,
                          child: Text(
                            widget
                                .l10n
                                .overviewHomeBranchFilterSheetUseAllBranches,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.contentSpacing,
                      vertical: tokens.gapSm,
                    ),
                    child: AppTextField(
                      controller: _searchController,
                      autofocus: true,
                      hintText:
                          widget.l10n.overviewHomeBranchFilterSheetSearchHint,
                      prefixIcon: Icons.search_rounded,
                      density: AppTextFieldDensity.compact,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (showCounter)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        tokens.contentSpacing,
                        0,
                        tokens.contentSpacing,
                        tokens.gapXs,
                      ),
                      child: Text(
                        widget.l10n.overviewHomeBranchFilterSelectionCount(
                          _selected.length,
                          widget.availableAgents.length,
                        ),
                        style: theme.appTypography.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.contentSpacing,
                      showCounter ? tokens.gapXs : 0,
                      tokens.contentSpacing,
                      tokens.gapSm,
                    ),
                    child: Wrap(
                      spacing: tokens.gapSm,
                      runSpacing: tokens.gapXs,
                      children: <Widget>[
                        TextButton(
                          style: bulkActionStyle,
                          onPressed: widget.availableAgents.isEmpty
                              ? null
                              : _selectAllAgents,
                          child: Text(
                            _query.isNotEmpty
                                ? widget
                                      .l10n
                                      .overviewHomeBranchFilterSelectAllFullRoster
                                : widget.l10n.overviewHomeBranchFilterSelectAll,
                          ),
                        ),
                        TextButton(
                          style: bulkActionStyle,
                          onPressed: _selected.isEmpty
                              ? null
                              : _deselectAllAgents,
                          child: Text(
                            widget.l10n.overviewHomeBranchFilterDeselectAll,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showFilteredBulk)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        tokens.contentSpacing,
                        0,
                        tokens.contentSpacing,
                        tokens.gapSm,
                      ),
                      child: Wrap(
                        spacing: tokens.gapSm,
                        runSpacing: tokens.gapXs,
                        children: <Widget>[
                          TextButton(
                            style: bulkActionStyle,
                            onPressed: allFilteredSelected
                                ? null
                                : _selectAllMatching,
                            child: Text(
                              widget
                                  .l10n
                                  .overviewHomeBranchFilterSelectMatching,
                            ),
                          ),
                          TextButton(
                            style: bulkActionStyle,
                            onPressed: anyFilteredSelected
                                ? null
                                : _deselectAllMatching,
                            child: Text(
                              widget
                                  .l10n
                                  .overviewHomeBranchFilterDeselectMatching,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (showMissingTokenBanner)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        tokens.contentSpacing,
                        0,
                        tokens.contentSpacing,
                        tokens.gapSm,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            tokens.formFieldRadius,
                          ),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(tokens.gapSm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: scheme.primary,
                              ),
                              SizedBox(width: tokens.gapSm),
                              Expanded(
                                child: Text(
                                  widget
                                      .l10n
                                      .overviewHomeBranchFilterMissingClientTokenBanner,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(tokens.contentSpacing),
                              child: Text(
                                widget
                                    .l10n
                                    .overviewHomeBranchFilterNoSearchResults,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: EdgeInsets.symmetric(
                              horizontal: tokens.contentSpacing,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final agent = filtered[index];
                              final nameColor = _overviewAgentNameColor(
                                agent.connectionStatus,
                                scheme,
                              );
                              final isOffline =
                                  agent.connectionStatus ==
                                  AgentConnectionStatus.offline;
                              final title = Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  if (isOffline) ...<Widget>[
                                    Icon(
                                      Icons.cloud_off_outlined,
                                      size: 18,
                                      color: scheme.error,
                                    ),
                                    SizedBox(width: tokens.gapXs),
                                  ],
                                  if (agent
                                      .missingLocalClientToken) ...<Widget>[
                                    Icon(
                                      Icons.vpn_key_off_outlined,
                                      size: 18,
                                      color: scheme.tertiary,
                                    ),
                                    SizedBox(width: tokens.gapXs),
                                  ],
                                  Expanded(
                                    child: Text(
                                      agent.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: nameColor),
                                    ),
                                  ),
                                ],
                              );
                              final tooltipLines = <String>[
                                if (isOffline)
                                  widget.l10n.agentConnectionOffline,
                                if (agent.missingLocalClientToken)
                                  widget
                                      .l10n
                                      .overviewHomeBranchFilterMissingClientTokenRowSubtitle,
                              ];
                              final titleWidget = tooltipLines.isEmpty
                                  ? title
                                  : Tooltip(
                                      message: tooltipLines.join('\n'),
                                      child: title,
                                    );
                              return CheckboxListTile(
                                title: titleWidget,
                                subtitle: agent.missingLocalClientToken
                                    ? Text(
                                        widget
                                            .l10n
                                            .overviewHomeBranchFilterMissingClientTokenRowSubtitle,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      )
                                    : null,
                                dense: true,
                                value: _selected.contains(agent.agentId),
                                onChanged: (v) => _toggle(agent.agentId, v),
                              );
                            },
                          ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        tokens.contentSpacing,
                        tokens.gapMd,
                        tokens.contentSpacing,
                        tokens.contentSpacing,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (_selected.isEmpty)
                            Padding(
                              padding: EdgeInsets.only(bottom: tokens.gapSm),
                              child: Text(
                                widget
                                    .l10n
                                    .overviewHomeBranchFilterApplyRequiresSelectionHint,
                                style: theme.appTypography.caption.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    widget.l10n.overviewHomeBranchFilterCancel,
                                  ),
                                ),
                              ),
                              SizedBox(width: tokens.gapMd),
                              Expanded(
                                child: Semantics(
                                  button: true,
                                  enabled: _selected.isNotEmpty,
                                  label: _selected.isEmpty
                                      ? widget
                                            .l10n
                                            .overviewHomeBranchFilterApplyDisabledSemantics
                                      : widget
                                            .l10n
                                            .overviewHomeBranchFilterApply,
                                  child: _selected.isEmpty
                                      ? Tooltip(
                                          message: widget
                                              .l10n
                                              .overviewHomeBranchFilterApplyRequiresSelectionHint,
                                          child: FilledButton(
                                            onPressed: null,
                                            child: Text(
                                              widget
                                                  .l10n
                                                  .overviewHomeBranchFilterApply,
                                            ),
                                          ),
                                        )
                                      : FilledButton(
                                          onPressed: _apply,
                                          child: Text(
                                            widget
                                                .l10n
                                                .overviewHomeBranchFilterApply,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
