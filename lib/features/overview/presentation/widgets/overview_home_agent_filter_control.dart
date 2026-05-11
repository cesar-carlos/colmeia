import 'dart:math' as math;

import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/bottom_sheet_compact_drag_handle.dart';
import 'package:flutter/material.dart';

const int _kMaxInlineChips = 3;

/// Home overview agent filter: compact summary, sheet for bulk selection.
class OverviewHomeAgentFilterControl extends StatelessWidget {
  const OverviewHomeAgentFilterControl({
    required this.l10n,
    required this.availableAgents,
    required this.selectedAgentIds,
    required this.onSelectionChanged,
    super.key,
    this.enabled = true,
  });

  final AppLocalizations l10n;
  final List<OverviewAgentOption> availableAgents;

  /// Domain: `null` means all approved agents.
  final Set<String>? selectedAgentIds;

  /// Emits domain-level selection: `null` when equivalent to “all agents”.
  final ValueChanged<Set<String>?> onSelectionChanged;
  final bool enabled;

  Set<String> get _allIds => availableAgents.map((e) => e.agentId).toSet();

  void _emitNormalized(Set<String> explicit) {
    final all = _allIds;
    if (explicit.length == all.length && explicit.containsAll(all)) {
      onSelectionChanged(null);
      return;
    }
    onSelectionChanged(explicit);
  }

  Future<void> _openSheet(BuildContext context) async {
    if (!enabled || availableAgents.isEmpty) {
      return;
    }
    final initial = selectedAgentIds == null
        ? Set<String>.from(_allIds)
        : Set<String>.from(selectedAgentIds!);

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (ctx) => _OverviewAgentSelectionSheet(
        l10n: l10n,
        availableAgents: availableAgents,
        initialSelected: initial,
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }
    _emitNormalized(result);
  }

  void _removeOne(BuildContext context, String agentId) {
    final explicit = Set<String>.from(selectedAgentIds ?? _allIds)
      ..remove(agentId);
    if (explicit.isEmpty) {
      return;
    }
    _emitNormalized(explicit);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final colors = theme.appColors;
    final scheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(tokens.formFieldRadius + 2);
    final labelToFieldGap = tokens.gapXs;

    if (availableAgents.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.dashboardHomeFiltersBranchesLabel,
            style: typography.utilityOverline.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: labelToFieldGap),
          Text(
            l10n.dashboardHomeFiltersBranchesEmptyHint,
            style: typography.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final explicitIds = selectedAgentIds == null ? _allIds : selectedAgentIds!;
    final count = explicitIds.length;
    final allCount = availableAgents.length;
    final isImplicitAll = selectedAgentIds == null;
    final showManySummary = !isImplicitAll && count > _kMaxInlineChips;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.dashboardHomeFiltersBranchesLabel,
          style: typography.utilityOverline.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: labelToFieldGap),
        Semantics(
          container: true,
          label: isImplicitAll
              ? l10n.overviewHomeBranchFilterAllBranchesSummary(allCount)
              : l10n.overviewHomeBranchFilterSelectedCount(count),
          child: Material(
            color: scheme.surfaceContainerLowest,
            borderRadius: borderRadius,
            child: InkWell(
              onTap: enabled ? () => _openSheet(context) : null,
              borderRadius: borderRadius,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.54),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.formFieldPaddingHorizontal,
                  vertical: tokens.gapSm,
                ),
                child: isImplicitAll
                    ? _AllAgentsSummaryRow(
                        l10n: l10n,
                        totalCount: allCount,
                        refineLabel: l10n.overviewHomeBranchFilterRefineAction,
                        enabled: enabled,
                        onRefine: () => _openSheet(context),
                      )
                    : showManySummary
                    ? _ManySelectedSummaryRow(
                        l10n: l10n,
                        count: count,
                        editLabel: l10n.overviewHomeBranchFilterEditAction,
                        enabled: enabled,
                        onEdit: () => _openSheet(context),
                      )
                    : _InlineChipsRow(
                        availableAgents: availableAgents,
                        selectedIds: explicitIds,
                        enabled: enabled,
                        onRemove: (id) => _removeOne(context, id),
                        onAddOrEdit: () => _openSheet(context),
                        editLabel: l10n.overviewHomeBranchFilterEditAction,
                        scheme: scheme,
                        tokens: tokens,
                        typography: typography,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AllAgentsSummaryRow extends StatelessWidget {
  const _AllAgentsSummaryRow({
    required this.l10n,
    required this.totalCount,
    required this.refineLabel,
    required this.enabled,
    required this.onRefine,
  });

  final AppLocalizations l10n;
  final int totalCount;
  final String refineLabel;
  final bool enabled;
  final VoidCallback onRefine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Icon(
          Icons.groups_2_outlined,
          size: 22,
          color: scheme.onSurfaceVariant,
        ),
        SizedBox(width: theme.extension<AppThemeTokens>()!.gapSm),
        Expanded(
          child: Text(
            l10n.overviewHomeBranchFilterAllBranchesSummary(totalCount),
            style: theme.appTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ),
        TextButton(
          onPressed: enabled ? onRefine : null,
          child: Text(refineLabel),
        ),
      ],
    );
  }
}

class _ManySelectedSummaryRow extends StatelessWidget {
  const _ManySelectedSummaryRow({
    required this.l10n,
    required this.count,
    required this.editLabel,
    required this.enabled,
    required this.onEdit,
  });

  final AppLocalizations l10n;
  final int count;
  final String editLabel;
  final bool enabled;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Icon(
          Icons.filter_alt_outlined,
          size: 22,
          color: scheme.onSurfaceVariant,
        ),
        SizedBox(width: theme.extension<AppThemeTokens>()!.gapSm),
        Expanded(
          child: Text(
            l10n.overviewHomeBranchFilterSelectedCount(count),
            style: theme.appTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ),
        TextButton(
          onPressed: enabled ? onEdit : null,
          child: Text(editLabel),
        ),
      ],
    );
  }
}

class _InlineChipsRow extends StatelessWidget {
  const _InlineChipsRow({
    required this.availableAgents,
    required this.selectedIds,
    required this.enabled,
    required this.onRemove,
    required this.onAddOrEdit,
    required this.editLabel,
    required this.scheme,
    required this.tokens,
    required this.typography,
  });

  final List<OverviewAgentOption> availableAgents;
  final Set<String> selectedIds;
  final bool enabled;
  final ValueChanged<String> onRemove;
  final VoidCallback onAddOrEdit;
  final String editLabel;
  final ColorScheme scheme;
  final AppThemeTokens tokens;
  final AppTypographyTokens typography;

  @override
  Widget build(BuildContext context) {
    final byId = <String, OverviewAgentOption>{
      for (final a in availableAgents) a.agentId: a,
    };
    final ordered =
        selectedIds
            .map((id) => byId[id])
            .whereType<OverviewAgentOption>()
            .toList(growable: false)
          ..sort((a, b) => a.name.compareTo(b.name));
    final canRemove = selectedIds.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: tokens.gapXs,
          runSpacing: tokens.gapXs,
          children: <Widget>[
            for (final agent in ordered)
              InputChip(
                avatar: _agentFilterChipAvatar(agent, scheme),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    agent.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.caption.copyWith(
                      color: _overviewAgentNameColor(
                        agent.connectionStatus,
                        scheme,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor:
                    agent.connectionStatus == AgentConnectionStatus.offline
                    ? scheme.errorContainer.withValues(alpha: 0.42)
                    : agent.missingLocalClientToken
                    ? scheme.tertiaryContainer.withValues(alpha: 0.55)
                    : scheme.surfaceContainerHigh,
                side: BorderSide(
                  color: agent.connectionStatus == AgentConnectionStatus.offline
                      ? scheme.error.withValues(alpha: 0.35)
                      : agent.missingLocalClientToken
                      ? scheme.tertiary.withValues(alpha: 0.35)
                      : scheme.outlineVariant.withValues(alpha: 0.4),
                ),
                deleteIcon: canRemove
                    ? Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      )
                    : null,
                onDeleted: canRemove && enabled
                    ? () => onRemove(agent.agentId)
                    : null,
              ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: enabled ? onAddOrEdit : null,
            child: Text(editLabel),
          ),
        ),
      ],
    );
  }
}

class _OverviewAgentSelectionSheet extends StatefulWidget {
  const _OverviewAgentSelectionSheet({
    required this.l10n,
    required this.availableAgents,
    required this.initialSelected,
  });

  final AppLocalizations l10n;
  final List<OverviewAgentOption> availableAgents;
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

  List<OverviewAgentOption> get _filtered {
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
    final allIds =
        widget.availableAgents.map((e) => e.agentId).toSet();
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
    final anyFilteredSelected =
        filtered.any((a) => _selected.contains(a.agentId));
    final byIdForBanner = <String, OverviewAgentOption>{
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

    final minChromePx = 236.0 +
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
                            widget.l10n.overviewHomeBranchFilterSheetUseAllBranches,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.contentSpacing,
                      vertical: tokens.gapSm,
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText:
                            widget.l10n.overviewHomeBranchFilterSheetSearchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            tokens.formFieldRadius,
                          ),
                        ),
                      ),
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
                          onPressed:
                              _selected.isEmpty ? null : _deselectAllAgents,
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
                              widget.l10n.overviewHomeBranchFilterSelectMatching,
                            ),
                          ),
                          TextButton(
                            style: bulkActionStyle,
                            onPressed: anyFilteredSelected
                                ? null
                                : _deselectAllMatching,
                            child: Text(
                              widget.l10n.overviewHomeBranchFilterDeselectMatching,
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
                                widget.l10n
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
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
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
                                      ? widget.l10n
                                          .overviewHomeBranchFilterApplyDisabledSemantics
                                      : widget.l10n.overviewHomeBranchFilterApply,
                                  child: _selected.isEmpty
                                      ? Tooltip(
                                          message: widget.l10n
                                              .overviewHomeBranchFilterApplyRequiresSelectionHint,
                                          child: FilledButton(
                                            onPressed: null,
                                            child: Text(
                                              widget.l10n
                                                  .overviewHomeBranchFilterApply,
                                            ),
                                          ),
                                        )
                                      : FilledButton(
                                          onPressed: _apply,
                                          child: Text(
                                            widget.l10n.overviewHomeBranchFilterApply,
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

Color _overviewAgentNameColor(
  AgentConnectionStatus status,
  ColorScheme scheme,
) {
  return switch (status) {
    AgentConnectionStatus.offline => scheme.error,
    AgentConnectionStatus.online ||
    AgentConnectionStatus.unknown => scheme.onSurface,
  };
}

Widget? _agentFilterChipAvatar(OverviewAgentOption agent, ColorScheme scheme) {
  final offline = agent.connectionStatus == AgentConnectionStatus.offline;
  final noToken = agent.missingLocalClientToken;
  if (offline && noToken) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.cloud_off_outlined, size: 14, color: scheme.error),
        const SizedBox(width: 3),
        Icon(Icons.vpn_key_off_outlined, size: 14, color: scheme.tertiary),
      ],
    );
  }
  if (offline) {
    return Icon(
      Icons.cloud_off_outlined,
      size: 16,
      color: scheme.error,
    );
  }
  if (noToken) {
    return Icon(
      Icons.vpn_key_off_outlined,
      size: 16,
      color: scheme.tertiary,
    );
  }
  return null;
}
