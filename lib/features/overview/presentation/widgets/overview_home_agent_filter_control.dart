import 'dart:math' as math;

import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
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

  Set<String> get _allIds =>
      availableAgents.map((e) => e.agentId).toSet();

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
      showDragHandle: true,
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
    final labelToFieldGap =
        tokens.gapXs;

    if (availableAgents.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.dashboardHomeFiltersAgentsLabel.toUpperCase(),
            style: typography.utilityOverline.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: labelToFieldGap),
          Text(
            l10n.dashboardHomeFiltersAgentsEmptyHint,
            style: typography.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final explicitIds = selectedAgentIds == null
        ? _allIds
        : selectedAgentIds!;
    final count = explicitIds.length;
    final allCount = availableAgents.length;
    final isImplicitAll = selectedAgentIds == null;
    final showManySummary = !isImplicitAll && count > _kMaxInlineChips;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.dashboardHomeFiltersAgentsLabel.toUpperCase(),
          style: typography.utilityOverline.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: labelToFieldGap),
        Semantics(
          container: true,
          label: isImplicitAll
              ? l10n.overviewAgentFilterAllAgentsSummary(allCount)
              : l10n.overviewAgentFilterSelectedCount(count),
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
                        refineLabel: l10n.overviewAgentFilterRefineAction,
                        enabled: enabled,
                        onRefine: () => _openSheet(context),
                      )
                    : showManySummary
                    ? _ManySelectedSummaryRow(
                        l10n: l10n,
                        count: count,
                        editLabel: l10n.overviewAgentFilterEditAction,
                        enabled: enabled,
                        onEdit: () => _openSheet(context),
                      )
                    : _InlineChipsRow(
                        availableAgents: availableAgents,
                        selectedIds: explicitIds,
                        enabled: enabled,
                        onRemove: (id) => _removeOne(context, id),
                        onAddOrEdit: () => _openSheet(context),
                        editLabel: l10n.overviewAgentFilterEditAction,
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
            l10n.overviewAgentFilterAllAgentsSummary(totalCount),
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
            l10n.overviewAgentFilterSelectedCount(count),
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
    final ordered = selectedIds
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
                avatar: agent.connectionStatus == AgentConnectionStatus.offline
                    ? Icon(
                        Icons.cloud_off_outlined,
                        size: 16,
                        color: scheme.error,
                      )
                    : null,
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
                    : scheme.surfaceContainerHigh,
                side: BorderSide(
                  color: agent.connectionStatus == AgentConnectionStatus.offline
                      ? scheme.error.withValues(alpha: 0.35)
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
      if (_selected.length <= 1) {
        return;
      }
      setState(() => _selected.remove(agentId));
    }
  }

  void _selectAllMatching() {
    final next = Set<String>.from(_selected);
    for (final a in _filtered) {
      next.add(a.agentId);
    }
    setState(() => _selected = next);
  }

  void _apply() {
    Navigator.of(context).pop(Set<String>.from(_selected));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final filtered = _filtered;
    final matchingNotAllSelected = _query.isNotEmpty &&
        filtered.isNotEmpty &&
        filtered.any((a) => !_selected.contains(a.agentId));

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(560, MediaQuery.sizeOf(context).width),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.contentSpacing,
                      tokens.gapSm,
                      tokens.contentSpacing,
                      tokens.gapSm,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            widget.l10n.overviewAgentFilterSheetTitle,
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
                            widget.l10n.overviewAgentFilterSheetSearchHint,
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
                  if (matchingNotAllSelected)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.contentSpacing,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _selectAllMatching,
                          child: Text(
                            widget.l10n.overviewAgentFilterSelectMatching,
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
                                widget.l10n.overviewAgentFilterNoSearchResults,
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
                              final scheme = theme.colorScheme;
                              final nameColor = _overviewAgentNameColor(
                                agent.connectionStatus,
                                scheme,
                              );
                              final isOffline = agent.connectionStatus ==
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
                              return CheckboxListTile(
                                title: isOffline
                                    ? Tooltip(
                                        message: widget
                                            .l10n.agentConnectionOffline,
                                        child: title,
                                      )
                                    : title,
                                dense: true,
                                value: _selected.contains(agent.agentId),
                                onChanged: (v) => _toggle(agent.agentId, v),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(tokens.contentSpacing),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(widget.l10n.overviewAgentFilterCancel),
                          ),
                        ),
                        SizedBox(width: tokens.gapMd),
                        Expanded(
                          child: FilledButton(
                            onPressed: _apply,
                            child: Text(widget.l10n.overviewAgentFilterApply),
                          ),
                        ),
                      ],
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
    AgentConnectionStatus.unknown => scheme.onSurfaceVariant,
    AgentConnectionStatus.online => scheme.onSurface,
  };
}
