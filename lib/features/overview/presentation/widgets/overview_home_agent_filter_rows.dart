part of 'overview_home_agent_filter_control.dart';

/// Row shown when no explicit selection is active: "All N branches".
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

/// Condensed row shown when the selection has more agents than the inline
/// chip row can render comfortably ([_kMaxInlineChips]).
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

/// Inline chip row shown when the selection size fits within
/// [_kMaxInlineChips]. Each chip is dismissible (when more than one is
/// selected) and renders connection / token-missing state via colors.
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

  final List<DashboardAgentOption> availableAgents;
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
    final byId = <String, DashboardAgentOption>{
      for (final a in availableAgents) a.agentId: a,
    };
    final ordered =
        selectedIds
            .map((id) => byId[id])
            .whereType<DashboardAgentOption>()
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
